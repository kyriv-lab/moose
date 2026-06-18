# JSONFileReader

!syntax description /UserObjects/JSONFileReader

This user object loads JSON file into a `nlohmann::json` object. The data can then be accessed programmatically
using the right key (if directly at the root level of the JSON) or group of keys through the APIs provided by the `JSONFileReader`.

!alert note
There is currently no search feature implemented. The exact path through the JSON tree to the data of interest
must be used.

!alert note
To read the same kind of data from a YAML file, use the [YAMLFileReader.md]. It shares this object's
base class and getter APIs; it simply converts the YAML to JSON on read.

!syntax parameters /UserObjects/JSONFileReader

!syntax inputs /UserObjects/JSONFileReader

!syntax children /UserObjects/JSONFileReader

!bibtex bibliography
