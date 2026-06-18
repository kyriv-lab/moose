//* This file is part of the MOOSE framework
//* https://mooseframework.inl.gov
//*
//* All rights reserved, see COPYRIGHT for full restrictions
//* https://github.com/idaholab/moose/blob/master/COPYRIGHT
//*
//* Licensed under LGPL 2.1, please see LICENSE for details
//* https://www.gnu.org/licenses/lgpl-2.1.html

#include "JSONFileReaderBase.h"

#include "json.h"

InputParameters
JSONFileReaderBase::validParams()
{
  InputParameters params = GeneralUserObject::validParams();
  // Add parameters
  params.addRequiredParam<FileName>("filename", "The path to the file including its name");
  // we run this object once at the initialization by default
  params.set<ExecFlagEnum>("execute_on") = EXEC_INITIAL;
  return params;
}

JSONFileReaderBase::JSONFileReaderBase(const InputParameters & parameters)
  : GeneralUserObject(parameters), _filename(getParam<FileName>("filename"))
{
}
