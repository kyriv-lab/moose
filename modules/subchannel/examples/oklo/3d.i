fuel_pin_pitch = 0.012
fuel_pin_diameter = 0.01
inner_duct_in = 0.2
n_rings = 9
unheated_length_entry = 0.5
heated_length = 1
unheated_length_exit = 1
cell_count = 60

[TriSubChannelMesh]
  [subchannel]
    type = SCMDetailedTriAssemblyMeshGenerator
    nrings = ${n_rings}
    n_cells = ${cell_count}
    flat_to_flat = ${inner_duct_in}
    unheated_length_entry = ${unheated_length_entry}
    unheated_length_exit = ${unheated_length_exit}
    heated_length = ${heated_length}
    pin_diameter = ${fuel_pin_diameter}
    pitch = ${fuel_pin_pitch}
  []
[]

[AuxVariables]
  [mdot]
    block = subchannel
  []
  [SumWij]
    block = subchannel
  []
  [P]
    block = subchannel
  []
  [DP]
    block = subchannel
  []
  [h]
    block = subchannel
  []
  [T]
    block = subchannel
  []
  [rho]
    block = subchannel
  []
  [mu]
    block = subchannel
  []
  [S]
    block = subchannel
  []
  [w_perim]
    block = subchannel
  []
  [q_prime]
    block = fuel_pins
  []
  [Tpin]
    block = fuel_pins
  []
[]

[Problem]
  type = NoSolveProblem
[]

[Outputs]
  exodus = true
[]

[Executioner]
  type = Steady
[]
