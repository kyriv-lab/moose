//* This file is part of the MOOSE framework
//* https://mooseframework.inl.gov
//*
//* All rights reserved, see COPYRIGHT for full restrictions
//* https://github.com/idaholab/moose/blob/master/COPYRIGHT
//*
//* Licensed under LGPL 2.1, please see LICENSE for details
//* https://www.gnu.org/licenses/lgpl-2.1.html

#pragma once

#include "JSONFileReaderBase.h"

/**
 * User object that reads a YAML file and makes its data available to other objects. The YAML is
 * converted to a JSON tree on read, so the inherited getters operate on it exactly as for JSON.
 */
class YAMLFileReader : public JSONFileReaderBase
{
public:
  static InputParameters validParams();

  YAMLFileReader(const InputParameters & parameters);

protected:
  /**
   * Read the YAML file, convert it to JSON and load it into _root
   * @param filename the name of the file
   */
  virtual void read(const FileName & filename) override;
};
