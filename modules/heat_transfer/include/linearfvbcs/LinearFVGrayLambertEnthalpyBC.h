//* This file is part of the MOOSE framework
//* https://mooseframework.inl.gov
//*
//* All rights reserved, see COPYRIGHT for full restrictions
//* https://github.com/idaholab/moose/blob/master/COPYRIGHT
//*
//* Licensed under LGPL 2.1, please see LICENSE for details
//* https://www.gnu.org/licenses/lgpl-2.1.html

#pragma once

#include "LinearFVAdvectionDiffusionFunctorRobinBCBase.h"

class GrayLambertSurfaceRadiationBase;

/**
 * Gray-Lambert surface radiation BC for linear FV enthalpy solves.
 *
 * The outgoing radiative flux q = eps * (sigma * T(h)^4 - G) is linearized with
 * respect to enthalpy using the chain rule:
 *   dq/dh = 4 * eps * sigma * T^3 * dTdh
 * so the emission term can be treated implicitly in an enthalpy solve.
 */
class LinearFVGrayLambertEnthalpyBC : public LinearFVAdvectionDiffusionFunctorRobinBCBase
{
public:
  static InputParameters validParams();

  LinearFVGrayLambertEnthalpyBC(const InputParameters & parameters);

protected:
  virtual Real getAlpha(Moose::FaceArg face, Moose::StateArg state) const override;
  virtual Real getBeta(Moose::FaceArg face, Moose::StateArg state) const override;
  virtual Real getGamma(Moose::FaceArg face, Moose::StateArg state) const override;

private:
  BoundaryID getBoundaryID(const Moose::FaceArg & face) const;

  /// Temperature functor reconstructed from enthalpy, e.g. T_from_p_h
  const Moose::Functor<Real> & _temperature_radiation;
  /// Derivative dT/dh used to linearize the T^4 emission term with respect to enthalpy
  const Moose::Functor<Real> & _dTdh;
  /// Effective diffusion coefficient used in the enthalpy diffusion solve, e.g. k * dTdh
  const Moose::Functor<Real> & _coeff_diffusion;
  /// User object providing irradiation/view-factor information
  const GrayLambertSurfaceRadiationBase & _glsr_uo;
  /// Whether to reconstruct the emission term implicitly
  bool _reconstruct_emission;
};
