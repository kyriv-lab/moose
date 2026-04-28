//* This file is part of the MOOSE framework
//* https://mooseframework.inl.gov
//*
//* All rights reserved, see COPYRIGHT for full restrictions
//* https://github.com/idaholab/moose/blob/master/COPYRIGHT
//*
//* Licensed under LGPL 2.1, please see LICENSE for details
//* https://www.gnu.org/licenses/lgpl-2.1.html

#include "LinearFVGrayLambertEnthalpyBC.h"
#include "GrayLambertSurfaceRadiationBase.h"
#include "HeatConductionNames.h"

#include <algorithm>
#include <set>

registerMooseObject("HeatTransferApp", LinearFVGrayLambertEnthalpyBC);

InputParameters
LinearFVGrayLambertEnthalpyBC::validParams()
{
  InputParameters params = LinearFVAdvectionDiffusionFunctorRobinBCBase::validParams();
  params.addClassDescription(
      "Gray-Lambert radiation boundary condition for linear FV enthalpy solves. "
      "The emission term is linearized with respect to enthalpy using dTdh.");
  params.addRequiredParam<MooseFunctorName>("temperature_radiation",
                                            "Temperature functor reconstructed from enthalpy.");
  params.addRequiredParam<MooseFunctorName>(
      "dTdh",
      "Derivative of temperature with respect to enthalpy used to linearize the T^4 emission.");
  params.addRequiredParam<MooseFunctorName>(
      "coeff_diffusion",
      "Effective enthalpy diffusion coefficient, typically k * dTdh.");
  params.addRequiredParam<UserObjectName>("surface_radiation_object_name",
                                          "Name of the GrayLambertSurfaceRadiationBase UO");
  params.addParam<bool>(
      "reconstruct_emission",
      true,
      "Flag to apply constant heat flux on sideset or reconstruct emission by T^4 law.");
  return params;
}

LinearFVGrayLambertEnthalpyBC::LinearFVGrayLambertEnthalpyBC(const InputParameters & parameters)
  : LinearFVAdvectionDiffusionFunctorRobinBCBase(parameters),
    _temperature_radiation(getFunctor<Real>("temperature_radiation")),
    _dTdh(getFunctor<Real>("dTdh")),
    _coeff_diffusion(getFunctor<Real>("coeff_diffusion")),
    _glsr_uo(getUserObject<GrayLambertSurfaceRadiationBase>("surface_radiation_object_name")),
    _reconstruct_emission(getParam<bool>("reconstruct_emission"))
{
}

BoundaryID
LinearFVGrayLambertEnthalpyBC::getBoundaryID(const Moose::FaceArg & face) const
{
  const auto & all_face_bids = face.fi->boundaryIDs();
  const auto & all_bc_bids = boundaryIDs();
  std::set<BoundaryID> current_bid;
  set_intersection(all_face_bids.begin(),
                   all_face_bids.end(),
                   all_bc_bids.begin(),
                   all_bc_bids.end(),
                   std::inserter(current_bid, current_bid.begin()));
  if (current_bid.size() != 1)
    paramError("boundary",
               std::to_string(current_bid.size()) +
                   " boundaries overlap. This is not currently supported");

  return *current_bid.begin();
}

Real
LinearFVGrayLambertEnthalpyBC::getAlpha(Moose::FaceArg face, Moose::StateArg state) const
{
  return _coeff_diffusion(functorFaceArg(_coeff_diffusion, face.fi), state);
}

Real
LinearFVGrayLambertEnthalpyBC::getBeta(Moose::FaceArg face, Moose::StateArg state) const
{
  if (!_reconstruct_emission)
    return 0.0;

  const auto bid = getBoundaryID(face);
  const Real eps = _glsr_uo.getSurfaceEmissivity(bid);
  const Real T = _temperature_radiation(face, state);
  const Real dTdh = _dTdh(face, state);

  return 4.0 * eps * HeatConduction::Constants::sigma * Utility::pow<3>(T) * dTdh;
}

Real
LinearFVGrayLambertEnthalpyBC::getGamma(Moose::FaceArg face, Moose::StateArg state) const
{
  const auto bid = getBoundaryID(face);

  if (!_reconstruct_emission)
    return _glsr_uo.getSurfaceHeatFluxDensity(bid);

  const Real eps = _glsr_uo.getSurfaceEmissivity(bid);
  const Real T = _temperature_radiation(face, state);
  const Real irradiation = _glsr_uo.getSurfaceIrradiation(bid);

  return eps * (3.0 * HeatConduction::Constants::sigma * Utility::pow<4>(T) + irradiation);
}
