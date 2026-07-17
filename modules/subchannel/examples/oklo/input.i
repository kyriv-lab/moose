inlet_temperature = 600
mass_flux = 3000
outlet_pressure = 200000.0
assembly_power = 0.0
pin_pitch = 0.012
wire_diameter = 0.001
pin_diameter = 0.01
wire_pitch = 0.4
inner_f2f = 0.2
n_rings = 9
unheated_length_entry = 0.5
heated_length = 1
unheated_length_exit = 1
cell_count = 60
n_blocks = 1

[TriSubChannelMesh]
  [subchannel]
    type = SCMTriAssemblyMeshGenerator
    nrings = ${n_rings}
    n_cells = ${cell_count}
    flat_to_flat = ${inner_f2f}
    unheated_length_entry = ${unheated_length_entry}
    unheated_length_exit = ${unheated_length_exit}
    heated_length = ${heated_length}
    pin_diameter = ${pin_diameter}
    pitch = ${pin_pitch}
    dwire = ${wire_diameter}
    hwire = ${wire_pitch}
    spacer_z = '0.0'
    spacer_k = '0.0'
  []

  [duct]
    type = SCMTriDuctMeshGenerator
    input = subchannel
    nrings = ${n_rings}
    n_cells = ${cell_count}
    flat_to_flat = ${inner_f2f}
    unheated_length_entry = ${unheated_length_entry}
    unheated_length_exit = ${unheated_length_exit}
    heated_length = ${heated_length}
    pitch = ${pin_pitch}
  []
[]

[FluidProperties]
  [sodium]
    type = PBSodiumFluidProperties
  []
[]

[SubChannel]
  type = TriSubChannel1PhaseProblem
  fp = sodium
  n_blocks = ${n_blocks}
  P_out = ${outlet_pressure}
  compute_density = true
  compute_viscosity = true
  compute_power = false
  full_output = true
  P_tol = 0.0001
  T_tol = 1e-05
  implicit = true
  segregated = false
  interpolation_scheme = 'upwind'
  duct_HTC_closure = 'gnielinski'
  pin_HTC_closure = 'borishanskii'
  friction_closure = 'cheng'
  mixing_closure = 'cheng_todreas'
[]

[SCMClosures]
  [cheng]
    type = SCMFrictionUpdatedChengTodreas
  []
  [gnielinski]
    type = SCMHTCGnielinski
  []
  [borishanskii]
    type = SCMHTCBorishanskii
  []
  [cheng_todreas]
    CT = 1.0
    type = SCMMixingChengTodreas
  []
[]

[ICs]
  [S_IC]
    type = SCMTriFlowAreaIC
    variable = S
  []

  [w_perim_IC]
    type = SCMTriWettedPerimIC
    variable = w_perim
  []

  [q_prime_IC]
    type = SCMTriPowerIC
    variable = q_prime
    power = ${assembly_power}
    filename = "pin_power_profile.txt"
    # axial_heat_rate = axial_heat_rate
  []

  [T_ic]
    type = ConstantIC
    variable = T
    value = ${inlet_temperature}
  []

  [Dpin_ic]
    type = ConstantIC
    variable = Dpin
    value = ${pin_diameter}
  []

  [P_ic]
    type = ConstantIC
    variable = P
    value = 0.0
  []

  [DP_ic]
    type = ConstantIC
    variable = DP
    value = 0.0
  []

  [Viscosity_ic]
    type = ViscosityIC
    variable = mu
    p = ${outlet_pressure}
    T = T
    fp = sodium
  []

  [rho_ic]
    type = RhoFromPressureTemperatureIC
    variable = rho
    p = ${outlet_pressure}
    T = T
    fp = sodium
  []

  [h_ic]
    type = SpecificEnthalpyFromPressureTemperatureIC
    variable = h
    p = ${outlet_pressure}
    T = T
    fp = sodium
  []

  [mdot_ic]
    type = ConstantIC
    variable = mdot
    value = 0.0
  []
[]

[AuxKernels]
  [T_in_bc]
    type = ConstantAux
    variable = T
    boundary = inlet
    value = ${inlet_temperature}
    execute_on = 'timestep_begin'
    block = subchannel
  []
  [mdot_in_bc]
    type = SCMMassFlowRateAux
    variable = mdot
    boundary = inlet
    area = S
    mass_flux = ${mass_flux}
    execute_on = 'timestep_begin'
  []
[]

[Outputs]
  exodus = true
  csv = true
[]

[Postprocessors]
  [md_0]
    type = SubChannelPointValue
    variable = mdot
    index = 0
    execute_on = 'TIMESTEP_END'
    height = 1.0
  []

  [ff_ch0]
    type = SubChannelPointValue
    variable = ff
    index = 0
    execute_on = 'TIMESTEP_END'
    height = 1.0
  []

  [DP_SubchannelDelta]
    type = SubChannelDelta
    variable = P
    execute_on = 'TIMESTEP_END'
  []
[]

[Executioner]
  type = Steady
[]

################################################################################
# A multiapp that projects data to a detailed mesh
################################################################################

[MultiApps]
  [viz]
    type = FullSolveMultiApp
    input_files = "3d.i"
    execute_on = "timestep_end"
  []
[]

[Transfers]
  [subchannel_transfer]
    type = SCMSolutionTransfer
    to_multi_app = viz
    variable = 'mdot SumWij P DP h T rho mu S'
  []
  [pin_transfer]
    type = SCMSolutionTransfer
    transfer_type = pin
    to_multi_app = viz
    variable = 'q_prime Tpin'
  []
[]
