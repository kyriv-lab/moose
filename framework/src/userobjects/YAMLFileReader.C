//* This file is part of the MOOSE framework
//* https://mooseframework.inl.gov
//*
//* All rights reserved, see COPYRIGHT for full restrictions
//* https://github.com/idaholab/moose/blob/master/COPYRIGHT
//*
//* Licensed under LGPL 2.1, please see LICENSE for details
//* https://www.gnu.org/licenses/lgpl-2.1.html

#include "YAMLFileReader.h"

#include "MooseUtils.h"
#include "json.h"

// rapidyaml is vendored as a single header; this is the one translation unit that emits its
// definitions, so RYML_SINGLE_HDR_DEFINE_NOW must be defined before including it.
#define RYML_SINGLE_HDR_DEFINE_NOW
#include "rapidyaml.hpp"

registerMooseObject("MooseApp", YAMLFileReader);

namespace
{
// rapidyaml reports errors (e.g. malformed YAML) through callbacks whose default implementation
// calls abort(). Route them through an exception instead so YAMLFileReader::read can translate them
// into a MOOSE error. One template covers all three error-callback signatures (basic/parse/visit).
template <typename ErrorData>
[[noreturn]] void
rymlThrowOnError(c4::csubstr msg, const ErrorData &, void *)
{
  throw std::runtime_error(std::string(msg.str, msg.len));
}
}

InputParameters
YAMLFileReader::validParams()
{
  InputParameters params = JSONFileReaderBase::validParams();
  params.addClassDescription("Loads a YAML file and makes its content available to consumers");
  return params;
}

YAMLFileReader::YAMLFileReader(const InputParameters & parameters) : JSONFileReaderBase(parameters)
{
  read(_filename);
}

void
YAMLFileReader::read(const FileName & filename)
{
  MooseUtils::checkFileReadable(filename);

  // Slurp the YAML file into a string
  std::ifstream yamldata(filename);
  const std::string yaml_str((std::istreambuf_iterator<char>(yamldata)),
                             std::istreambuf_iterator<char>());

  // Make rapidyaml raise exceptions on error rather than aborting the run
  ryml::Callbacks callbacks;
  callbacks.set_error_basic(&rymlThrowOnError<ryml::ErrorDataBasic>)
      .set_error_parse(&rymlThrowOnError<ryml::ErrorDataParse>)
      .set_error_visit(&rymlThrowOnError<ryml::ErrorDataVisit>);
  ryml::set_callbacks(callbacks);

  // YAML is (nearly) a superset of JSON, so parse the YAML and re-emit it as JSON. Storing the data
  // as a JSON tree lets us reuse all of the JSON query machinery (and the inherited getters).
  std::string json_str;
  try
  {
    const ryml::Tree tree = ryml::parse_in_arena(c4::csubstr(filename.data(), filename.size()),
                                                 c4::csubstr(yaml_str.data(), yaml_str.size()));
    json_str = ryml::emitrs_json<std::string>(tree);
  }
  catch (const std::exception & e)
  {
    ryml::reset_callbacks();
    mooseError("Failed to parse YAML file '", filename, "':\n", e.what());
  }
  ryml::reset_callbacks();

  try
  {
    _root = nlohmann::json::parse(json_str);
  }
  catch (const std::exception & e)
  {
    mooseError("Failed to convert the contents of YAML file '", filename, "' to JSON:\n", e.what());
  }
}
