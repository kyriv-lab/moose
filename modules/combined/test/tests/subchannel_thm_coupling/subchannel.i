# Based on M. Fontana, et al. this arbitrary subassembly is used for THM-SC coupling
T_in = 583.0 #K
flow_area = 0.0004980799633447909 #m2
mass_flux_in = '${fparse 1.0/flow_area}'
P_out = 2e5 # Pa
###################################################
# Geometric parameters
###################################################
n_cells = 25
n_rings = 3
fuel_pin_pitch = 7.26e-3
fuel_pin_diameter = 5.84e-3
wire_z_spacing = 0.3048
wire_diameter = 1.42e-3
inner_duct_in = 3.41e-2
heated_length = 1.0
###################################################
[TriSubChannelMesh]
  [subchannel]
    type = SCMTriAssemblyMeshGenerator
    nrings = ${n_rings}
    n_cells = ${n_cells}
    flat_to_flat = ${inner_duct_in}
    heated_length = ${heated_length}
    pin_diameter = ${fuel_pin_diameter}
    pitch = ${fuel_pin_pitch}
    dwire = ${wire_diameter}
    hwire = ${wire_z_spacing}
    spacer_z = '0.0'
    spacer_k = '0.0'
  []
[]

[Functions]
  [axial_heat_rate]
    type = ParsedFunction
    expression = '(pi/2)*sin(pi*z/L)'
    symbol_names = 'L'
    symbol_values = '${heated_length}'
  []
[]

[FluidProperties]
  [Sodium]
    type = SodiumSaturationFluidProperties
  []
[]

[SubChannel]
  type = TriSubChannel1PhaseProblem
  fp = Sodium
  n_blocks = 1
  P_out = report_pressure_outlet
  compute_density = true
  compute_viscosity = true
  compute_power = true
  P_tol = 1.0e-3
  T_tol = 1.0e-3
  implicit = true
  segregated = false
  staggered_pressure = false
  verbose_multiapps = true
  verbose_subchannel = false
  interpolation_scheme = 'upwind'
  pin_HTC_closure = 'gnielinski'
  friction_closure = 'Cheng'
  mixing_closure = 'Cheng_Todreas'
[]

[SCMClosures]
  [Cheng]
    type = SCMFrictionUpdatedChengTodreas
  []
  [gnielinski]
    type = SCMHTCGnielinski
  []
  [Cheng_Todreas]
    type = SCMMixingChengTodreas
    CT = 2.6
  []
[]

[ICs] # Initial conditions
  ## Geometric variables
  ## these variables can be set by default. SCM will use the kernels listed below by default.
  ## But the user can use other custom kernels in the input that will produce non-default values.
  [S_IC]
    type = SCMTriFlowAreaIC
    variable = S
  []

  [w_perim_IC]
    type = SCMTriWettedPerimIC
    variable = w_perim
  []

  [Dpin_ic]
    type = ConstantIC
    variable = Dpin
    value = ${fuel_pin_diameter}
  []

  ## If an auxvariable is not set it will take the default value of 0
  [P_ic]
    type = ConstantIC
    variable = P
    value = 0.0
  []

  [mdot_ic]
    type = ConstantIC
    variable = mdot
    value = 0.0
  []

  ## What needs to be set are the following
  [T_ic]
    type = ConstantIC
    variable = T
    value = ${T_in}
  []

  [Viscosity_ic]
    type = ViscosityIC
    variable = mu
    p = ${P_out}
    T = T
    fp = Sodium
  []

  [rho_ic]
    type = RhoFromPressureTemperatureIC
    variable = rho
    p = ${P_out}
    T = T
    fp = Sodium
  []

  [h_ic]
    type = SpecificEnthalpyFromPressureTemperatureIC
    variable = h
    p = ${P_out}
    T = T
    fp = Sodium
  []

  # IC's are only called once, so if i want to redifine power i need an auxkernel
  [q_prime_IC]
    type = SCMTriPowerIC
    variable = q_prime
    power = 10000 # W
    filename = "pin_power_profile19.txt"
    axial_heat_rate = axial_heat_rate
  []
[]

## Boundary conditions
[AuxKernels]
  [T_in_bc]
    type = FunctorAux
    functor = report_temperature_inlet #I can read in post-processor values
    variable = T
    boundary = inlet
    execute_on = 'timestep_begin'
    block = subchannel
  []
  [mdot_in_bc]
    type = SCMMassFlowRateAux
    variable = mdot
    boundary = inlet
    area = S
    mass_flux = report_mass_flux_inlet #I can read in post-processor values
    execute_on = 'timestep_begin'
    block = subchannel
  []
  # [q_prime]
  #   type = SCMTriPowerAux
  #   variable = q_prime
  #   power = report_power
  #   filename = "pin_power_profile19.txt"
  #   execute_on = 'initial timestep_begin'
  #   axial_heat_rate = axial_heat_rate
  # []
[]

[Outputs]
  csv = true ## I want to have a .csv file output
  exodus = true
[]

# [Executioner]
#   # type = Transient
#   # dt = 1
#   # end_time = 1 #10 if i want sychronized transient
#   type = Steady
# []

[Executioner] ## This is if i want to define picard iterations
  type = Steady
  petsc_options_iname = '-pc_type -pc_hypre_type'
  petsc_options_value = 'hypre boomeramg'
  fixed_point_max_its = 8
  fixed_point_min_its = 6
  fixed_point_rel_tol = 1e-6
[]

[Postprocessors]
  [total_pressure_drop_SC]
    type = SubChannelDelta
    variable = P
    execute_on = "timestep_end"
  []

  # [total_pressure_drop_SC_limited]
  #   type = ParsedPostprocessor
  #   pp_names = 'total_pressure_drop_SC'
  #   expression = 'min(total_pressure_drop_SC, 1e6)'
  #   execute_on = "timestep_end"
  # []

  [Total_power_qprime]
    type = ElementIntegralVariablePostprocessor
    variable = q_prime
    block = fuel_pins
  []

  [Total_power_TH_balance]
    type = SCMTHPowerPostprocessor
    execute_on = 'timestep_end'
  []

  [report_mass_flux_inlet] # Used because i aim to couple with THM
    type = Receiver
    default = ${mass_flux_in}
  []

  [report_temperature_inlet] # Used because i aim to couple with THM
    type = Receiver
    default = ${T_in}
    force_preaux = true
  []

  [report_pressure_outlet] # Used because i aim to couple with THM
    type = Receiver
    default = ${P_out}
  []

  [report_power] # Used because i aim to couple with THM
    type = Receiver
    default = 10000
  []
[]

###############################################################################
[MultiApps]
  ################################################################################
  # Couple to Thermo-Mechanical Pin model (uses kernels available in MOOSE)
  ################################################################################
  [sub]
    type = FullSolveMultiApp
    input_files = one_pin_problem_sub.i
    execute_on = 'timestep_end'
    positions = '0   0   0 '
    output_in_position = true
    bounding_box_padding = '0 0 0.01'
  []

  ################################################################################
  # A multiapp that projects the solution to a detailed mesh for visualization purposes
  ################################################################################
  [viz]
    type = FullSolveMultiApp
    input_files = '3D.i'
    execute_on = 'FINAL'
  []
[]

[Transfers]
  [Tpin] # send pin surface temperature to pin model,
    type = MultiAppGeneralFieldNearestLocationTransfer
    to_multi_app = sub
    variable = Pin_surface_temperature
    source_variable = Tpin
    execute_on = 'timestep_end'
    greedy_search = true
  []

  # # [diameter] # send diameter information from pin model to subchannel
  # #   type = MultiAppGeneralFieldNearestLocationTransfer
  # #   from_multi_app = sub
  # #   variable = Dpin
  # #   source_variable = pin_diameter_deformed
  # #   from_boundaries = right
  # #   execute_on = 'timestep_end'
  # #   greedy_search = true
  # # []

  [q_prime] # send heat flux from pin model to subchannel
    type = MultiAppGeneralFieldNearestLocationTransfer
    from_multi_app = sub
    variable = q_prime
    source_variable = q_prime
    from_boundaries = right
    execute_on = 'timestep_end'
    greedy_search = true
  []

  [subchannel_transfer]
    type = SCMSolutionTransfer
    transfer_type = subchannel
    to_multi_app = viz
    variable = 'mdot SumWij P h T rho mu S'
  []
  [pin_transfer]
    type = SCMSolutionTransfer
    transfer_type = pin
    to_multi_app = viz
    variable = 'Tpin q_prime Dpin'
  []
[]
