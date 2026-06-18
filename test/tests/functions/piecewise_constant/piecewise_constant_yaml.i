[Mesh]
  type = GeneratedMesh
  dim = 1
[]

[Problem]
  solve = false
[]

[UserObjects]
  [yaml]
    type = YAMLFileReader
    filename = 'function_values.yaml'
  []
[]

[Functions]
  [from_yaml]
    type = PiecewiseConstant
    json_uo = 'yaml'
    x_keys = "the_data some_key some_other_key"
    y_keys = "the_data second_key some_other_key"
  []
[]

[Postprocessors]
  [from_yaml]
    type = FunctionValuePostprocessor
    function = from_yaml
    execute_on = 'TIMESTEP_END INITIAL'
  []
[]

[Executioner]
  type = Transient
  dt = 1
  start_time = 0
  end_time = 10
[]

[Outputs]
  csv = true
[]
