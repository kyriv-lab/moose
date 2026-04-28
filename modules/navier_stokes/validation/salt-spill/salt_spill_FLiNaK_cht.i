######## FLiNaK material properties #####################
T_initial = 876.15 #Initial temperature~[K]. Target was 923.15K (650 C) but IR camera measures 876.15 (603 C) at initial time, for Test No. 4
# salt mass recovered 59 g.
# 1/4th inch beaker walls.
T_melt = 735.0 #Melting temperature of salt~[K]
rho_salt_l = ${fparse 2600 - 0.62*T_initial} #Liquid salt density~[Kg/m3]
# rho_salt_s = 2199.0 #Kg Solid salt density~[Kg/m3]
molecular_weight = 0.04129 #Kg/mol
# mu_power = ${fparse 0.21 - 1.2e3/T_initial + 1.4e6/(T_initial * T_initial)}
# mu_salt_l = ${fparse 1e-3 * 10^mu_power} #Liquid salt viscosity~[Pa*s]
cp_salt_l_mol = ${fparse 40 + 4.4e-2*T_initial} #Liquid salt heat capacity~[J/(K*mol)]
cp_salt_l = ${fparse cp_salt_l_mol / molecular_weight} #Liquid salt specific heat~[J/(K*Kg)]
k_salt_l = ${fparse -0.35 + 1.3e-3*T_initial} #Liquid salt thermal conductivity~[W/(m*K)]
#alpha_b = 3.4e-4 #Liquid salt volume expansion~[K^-1]
T_solidus = ${T_melt}
T_liquidus = ${fparse T_solidus + 0.1}
L = 431000 # Heat of fusion~[J/kg]
ambient_temperature = 301.15

######## 316 stainless steel properties ########
rho_solid=8000.0 #Density of steel container~[kg/m3]
cp_solid=600.0 #Specific heat capacity~[J/(Kg*K)]
k_solid=16.0 #Thermal conductivity~[W/(m-k)]

####
h_hot_salt  = ${fparse L + cp_salt_l*(T_initial  - T_liquidus)}
h_s = 0.0

ambient_boundary = 'external_wall solid_top'

[Problem]
  kernel_coverage_check = false
  linear_sys_names = 'energy_system solid_energy_system u_system v_system w_system p_system'
  material_coverage_check = false
  previous_nl_solution_required = true
[]

[GlobalParams]
  view_factor_object_name = rt_vf
[]

[Mesh]
 [file]
    type = FileMeshGenerator
    file = mesh_in.e
  []
  [patch_bot]
    type = PatchSidesetGenerator
    boundary = 'air_solid_iface'
    n_patches = 60
    input = file
    partitioner = centroid
    centroid_partitioner_direction = z
  []
  [patch_wall]
    type = PatchSidesetGenerator
    boundary = 'salt_air_iface'
    n_patches = 60
    input = patch_bot
    partitioner = centroid
    centroid_partitioner_direction = z
  []
  [top_deletion]
    type = BoundaryDeletionGenerator
    input = patch_wall
    boundary_names = 'air_solid_iface salt_air_iface'
  []
[]

!include patches_FLiNaK.i

[Variables]
  [h_salt]
    type = MooseLinearVariableFVReal
    solver_sys = energy_system
    block = 'salt'
  []
  [temp_solid]
    type = MooseLinearVariableFVReal
    solver_sys = solid_energy_system
    block = 'solid'
  []
  [vel_x]
    type = MooseLinearVariableFVReal
    solver_sys = 'u_system'
    initial_condition = 0
    block = salt
  []
  [vel_y]
    type = MooseLinearVariableFVReal
    solver_sys = 'v_system'
    initial_condition = 0
    block = salt
  []
  [vel_z]
    type = MooseLinearVariableFVReal
    solver_sys = 'w_system'
    initial_condition = 0
    block = salt
  []
  [pressure]
    type = MooseLinearVariableFVReal
    solver_sys = 'p_system'
    initial_condition = 0
    block = salt
  []
[]

[AuxVariables]
  [radiation_temperature]
    type = MooseVariableFVReal
    block = 'salt solid'
  []
  [fl]
    type = MooseVariableFVReal
    initial_condition = 1.0
    block = salt
  []
  [temp_salt]
    type = MooseLinearVariableFVReal
    block = salt
  []
  [T_interface]
    type = MooseLinearVariableFVReal
  []
  [k_eff]
    type = MooseVariableFVReal
  []
[]

[AuxKernels]
  [T_from_h]
    type = FunctorAux
    functor = 'T_from_p_h'
    variable = 'temp_salt'
    block = salt
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [fl_from_h]
    type = FunctorAux
    functor = 'liquid_fraction'
    variable = 'fl'
    block = salt
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [k_eff_from_h]
    type = FunctorAux
    functor = 'kappa_h_salt'
    variable = 'k_eff'
    block = salt
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [copy_T_salt]
    type = ProjectionAux
    v = 'temp_salt'
    variable = radiation_temperature
    block = salt
    execute_on = 'INITIAL LINEAR NONLINEAR TIMESTEP_BEGIN TIMESTEP_END'
  []
  [copy_T_solid]
    type = ProjectionAux
    v = 'temp_solid'
    variable = radiation_temperature
    block = solid
    execute_on = 'INITIAL LINEAR NONLINEAR TIMESTEP_BEGIN TIMESTEP_END'
  []
[]

[FVICs]
  [ic_u_1]
    type = FVConstantIC
    variable = temp_solid
    value = ${ambient_temperature}
    block = 'solid'
  []
  [ic_u_2]
    type = FVConstantIC
    variable = temp_salt
    value = ${T_initial}
    block = 'salt'
  []
  [ic_u_3]
    type = FVConstantIC
    variable = h_salt
    value = ${h_hot_salt}
    block = 'salt'
  []
[]

[UserObjects]
  [rc]
    type = RhieChowMassFlux
    u = vel_x
    v = vel_y
    w = vel_z
    pressure = pressure
    rho = 1
    p_diffusion_kernel = p_diffusion
    block = salt
  []
[]

[LinearFVKernels]
  [p_diffusion]
    type = LinearFVAnisotropicDiffusion
    variable = pressure
    diffusion_tensor = Ainv
    block = salt
    use_nonorthogonal_correction = false
  []
  [h_time]
    type = LinearFVTimeDerivative
    variable = h_salt
    factor = ${rho_salt_l}
    block = salt
  []
  [conduction]
    type = LinearFVDiffusion
    variable = h_salt
    diffusion_coeff = 'kappa_h_salt'
    use_nonorthogonal_correction = false
    block = salt
  []
  [temp_time_solid]
    type = LinearFVTimeDerivative
    variable = temp_solid
    factor = ${fparse rho_solid*cp_solid}
    block = solid
  []
  [temp_conduction_solid]
    type = LinearFVDiffusion
    diffusion_coeff = ${k_solid}
    variable = temp_solid
    block = solid
  []
[]

[UserObjects]
  [gray_lambert]
    type = ViewFactorObjectSurfaceRadiation
    boundary = '${air_solid_interface} air_top ${salt_air_interface}'
    fixed_temperature_boundary = 'air_top'
    fixed_boundary_temperatures = '${ambient_temperature}'
    emissivity = ${emissivities}
    temperature = radiation_temperature
    execute_on = 'LINEAR TIMESTEP_BEGIN TIMESTEP_END NONLINEAR'
  []

  [vf_study]
    type = ViewFactorRayStudy
    execute_on = INITIAL
    boundary = '${air_solid_interface} air_top ${salt_air_interface}'
    face_order = CONSTANT
    polar_quad_order = 16
    azimuthal_quad_order = 16
    face_type = GAUSS
    warn_non_planar = false
  []

  [rt_vf]
    type = RayTracingViewFactor
    boundary = '${air_solid_interface} air_top ${salt_air_interface}'
    execute_on = INITIAL
    ray_study_name = vf_study
    normalize_view_factor = true
  []
[]

[RayBCs]
  [vf]
    type = ViewFactorRayBC
    boundary = '${air_solid_interface} air_top ${salt_air_interface}'
  []
[]

[LinearFVBCs]
  # temperature BCs
  [ambient]
    type = LinearFVAdvectionDiffusionFunctorDirichletBC
    variable = temp_solid
    boundary = '${ambient_boundary}'
    functor = ${ambient_temperature}
  []
  [radiation_solidwalls]
    type = LinearFVGrayLambert
    variable = temp_solid
    temperature_radiation = radiation_temperature
    coeff_diffusion = ${k_solid}
    surface_radiation_object_name = gray_lambert
    boundary = ${air_solid_interface}
    reconstruct_emission = false
  []
  [radiation_salt_air_iface]
    type = LinearFVGrayLambertEnthalpyBC
    variable = h_salt
    temperature_radiation = T_from_p_h
    dTdh = dTdh
    coeff_diffusion = 'kappa_h_salt'
    surface_radiation_object_name = gray_lambert
    boundary = ${salt_air_interface}
    reconstruct_emission = true
  []
  # [radiation_salt_air_iface]
  #   type = LinearFVAdvectionDiffusionFunctorNeumannBC
  #   variable = h_salt #radiation_temperature
  #   boundary = ${salt_air_interface}
  #   functor = -18000.0
  # []
  # cht
  [fluid_solid]
    type = LinearFVRobinCHTBC
    variable = h_salt
    boundary = salt_solid_wall
    h = ${h_s}
    thermal_conductivity = ${k_solid}
    incoming_flux = heat_flux_to_fluid_salt_solid_wall
    surface_temperature = interface_temperature_fluid_salt_solid_wall
  []
  [solid_fluid]
    type = LinearFVDirichletCHTBC
    variable = temp_solid
    boundary = salt_solid_wall
    functor = temp_salt
  []
[]

[FunctorMaterials]
  [phase_change_enthalpy]
    type = INSFVPhaseChangeEnthalpyFunctorMaterial
    cp_solid = ${cp_salt_l}
    cp_liquid = ${cp_salt_l}
    L = ${L}
    T_solidus = ${T_solidus}
    T_liquidus = ${T_liquidus}

    # This 'temperature' input is used only for h_from_p_T. We do not use h_from_p_T
    # in this file (wall enthalpies are prescribed directly), so a dummy constant is fine.
    temperature = '${T_solidus}'

    enthalpy = h_salt
    block = salt
  []
  [kappa_h_salt]
    type = ParsedFunctorMaterial
    property_name = 'kappa_h_salt'
    functor_names = 'dTdh'#'k_mixture dTdh'
    functor_symbols = 'dTdh'
    expression = '${k_salt_l}*dTdh'
    block = salt
  []
  [enthalpy_cht_functor]
    type = INSFVPhaseChangeEnthalpyFunctorMaterial
    h_from_p_T_name = 'interface_enthalpy_solid_salt_solid_wall'
    T_from_p_h_name = T_from_p_h_cht
    liquid_fraction_name = liquid_fraction_cht
    dTdh_name = dTdh_cht
    cp_solid = ${cp_salt_l}
    cp_liquid = ${cp_salt_l}
    L = ${L}
    T_solidus = ${T_solidus}
    T_liquidus = ${T_liquidus}

    # This 'temperature' input is used only for h_from_p_T. We do not use h_from_p_T
    # in this file (wall enthalpies are prescribed directly), so a dummy constant is fine.
    temperature = 'interface_temperature_solid_salt_solid_wall'

    enthalpy = ${h_hot_salt} #Dummy value
    # block = solid
  []
[]

[Executioner]
  type = PIMPLE
  num_iterations = 20
  dt = 0.1
  end_time = 90
  should_solve_momentum = false
  should_solve_pressure = false
  energy_system = 'energy_system'
  solid_energy_system = 'solid_energy_system'
  energy_l_abs_tol = 1e-6
  energy_l_tol = 1e-8
  energy_equation_relaxation = 0.2
  energy_field_relaxation = 0.2
  energy_absolute_tolerance = 1e-6
  energy_petsc_options_iname = '-pc_type -pc_hypre_type'
  energy_petsc_options_value = 'hypre boomeramg'
  solid_energy_l_abs_tol = 1e-6
  solid_energy_l_tol = 1e-8
  solid_energy_absolute_tolerance = 1e-6
  solid_energy_petsc_options_iname = '-pc_type -pc_hypre_type'
  solid_energy_petsc_options_value = 'hypre boomeramg'
  print_fields = false
  continue_on_max_its = true

  rhie_chow_user_object = 'rc'
  momentum_systems = 'u_system v_system w_system'
  pressure_system = 'p_system'

  cht_interfaces = 'salt_solid_wall'
  cht_solid_flux_relaxation = 0.5
  cht_fluid_flux_relaxation = 0.5
  cht_solid_temperature_relaxation = 0.3
  cht_fluid_temperature_relaxation = 0.3
  cht_heat_flux_tolerance = 1e-3
  max_cht_fpi = 5
[]

[Outputs]
  exodus = true
  [out]
    type = CSV
    sync_times = '10 90'
    sync_only = true
  []
[]

[VectorPostprocessors]
  [centerline]
    type = LineValueSampler
    start_point = '0 0 0.0188' # height of salt surface 0.01885 m
    end_point = '0.0254 0 0.0188'
    num_points = 100
    variable = 'temp_salt' # mu_eff mu_t pressure TKE TKED vel_x vel_y vel_z yplus'
    sort_by = 'x'
    execute_on = 'TIMESTEP_END FINAL'
  []
[]

!include PP_FLiNaK_cht.i
