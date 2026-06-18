# YAMLFileReader

!syntax description /UserObjects/YAMLFileReader

This user object loads a YAML file and makes its content available to other objects. The data can
then be accessed programmatically using the right key (if directly at the root level of the data) or
a group of keys, through the same APIs provided by the [JSONFileReader.md].

!alert note
There is currently no search feature implemented. The exact path through the data tree to the value
of interest must be used.

## How YAML is handled id=how-it-works

MOOSE does not maintain a separate query engine for YAML. Instead, the `YAMLFileReader` and the
[JSONFileReader.md] share a common base class (`JSONFileReaderBase`) that stores the data as a
`nlohmann::json` tree and provides all of the value/vector getters. The only difference between the
two readers is how that tree is populated:

- the `JSONFileReader` parses the file directly as JSON;
- the `YAMLFileReader` parses the file as YAML and converts it to JSON, then loads the result into
  the same tree.

The conversion is done with the [rapidyaml](https://github.com/biojppm/rapidyaml) library, which is
vendored as a single header in `framework/contrib/rapidyaml`. YAML is (very nearly) a superset of
JSON, so the file is parsed into a YAML tree and re-emitted as JSON, which is then handed to
`nlohmann::json`. This keeps a single, well-tested query implementation for both formats and avoids
adding a YAML-specific dependency to the MOOSE build environment.

A practical consequence of the round-trip is that the data, once loaded, is plain JSON: YAML-only
constructs that have no JSON equivalent (for example, non-string mapping keys or anchors that are
not expanded) are normalized to their JSON representation. Malformed YAML, or YAML that cannot be
represented as JSON, produces a MOOSE error identifying the file.

Because both readers share the base type, anywhere a reader is consumed by name (such as the
`json_uo` parameter of the [PiecewiseConstant.md] and [PiecewiseLinear.md] functions) a
`YAMLFileReader` may be used interchangeably with a `JSONFileReader`.

!syntax parameters /UserObjects/YAMLFileReader

!syntax inputs /UserObjects/YAMLFileReader

!syntax children /UserObjects/YAMLFileReader

!bibtex bibliography
