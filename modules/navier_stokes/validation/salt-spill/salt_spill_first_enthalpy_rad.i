#rho_salt_s=2000.
rho_salt_l=2000.
#cp_salt_s=2090.
cp_salt_l=2090.
#k_salt_s=0.6
k_salt_l=0.6
L = 425000
#alpha_b = 1.2e-4
T_solidus = 730.
T_liquidus = '${fparse T_solidus + 0.1}'

rho_solid=3000
cp_solid=600
k_solid = 1.

T_hot = 770.
T_cold = 301.15
#h_cold_salt = ${fparse cp_salt_l*(T_cold - T_solidus)}
h_hot_salt  = ${fparse L + cp_salt_l*(T_hot - T_liquidus)}
h_s = 0.0

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
  # [patch_bot]
  #   type = PatchSidesetGenerator
  #   boundary = 'air_solid_iface'
  #   n_patches = 6
  #   input = file
  # []
  # [patch_wall]
  #   type = PatchSidesetGenerator
  #   boundary = 'salt_air_iface'
  #   n_patches = 4
  #   input = patch_bot
  #   partitioner = centroid
  #   centroid_partitioner_direction = x
  # []
  # [top_deletion]
  #   type = BoundaryDeletionGenerator
  #   input = patch_wall
  #   boundary_names = 'air_solid_iface salt_air_iface'
  # []
[]

!include patches.i
air_solid_iface = 'air_solid_iface'# air_solid_iface_1 air_solid_iface_2 air_solid_iface_3 air_solid_iface_4 air_solid_iface_5'
#air_solid_iface = 'air_solid_iface_0 air_solid_iface_1 air_solid_iface_2 air_solid_iface_3 air_solid_iface_4 air_solid_iface_5'# air_solid_iface_6
                  # air_solid_iface_7 air_solid_iface_8 air_solid_iface_9'# air_solid_iface_10 air_solid_iface_11 air_solid_iface_12 air_solid_iface_13
                  #  air_solid_iface_14 air_solid_iface_15 air_solid_iface_16 air_solid_iface_17 air_solid_iface_18 air_solid_iface_19 air_solid_iface_20
                  #  air_solid_iface_21 air_solid_iface_22 air_solid_iface_23 air_solid_iface_24 air_solid_iface_25 air_solid_iface_26 air_solid_iface_27
                  #  air_solid_iface_28 air_solid_iface_29'

[Variables]
  [h_salt]
    type = MooseLinearVariableFVReal
    solver_sys = energy_system
    # Reference: h(T_solidus) = 0.0
    block = 'salt'
  []
  [temp_solid]
    type = MooseLinearVariableFVReal
    solver_sys = solid_energy_system
    # Reference: h(T_solidus) = 0.0
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
  # [density]
  #   type = MooseVariableFVReal
  # []
  [k_eff]
    type = MooseVariableFVReal
  []
  # [cp_var]
  #   type = MooseVariableFVReal
  # []
  # [darcy_coef]
  #   type = MooseVariableFVReal
  # []
  # [fch_coef]
  #   type = MooseVariableFVReal
  # []
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
  []
  [copy_T_solid]
    type = ProjectionAux
    v = 'temp_solid'
    variable = radiation_temperature
    block = solid
  []
[]

[FVICs]
  [ic_u_1]
    type = FVConstantIC
    variable = temp_solid
    value = ${T_cold}
    block = 'solid'
  []
  [ic_u_2]
    type = FVConstantIC
    variable = temp_salt
    value = ${T_hot}
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
  # [h_advection]
  #   type = LinearFVEnergyAdvection
  #   variable = h_salt
  #   advected_interp_method = ${advected_interp_method}
  #   rhie_chow_user_object = 'rc'
  #   block = salt
  # []
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
  [./gray_lambert]
    type = ViewFactorObjectSurfaceRadiation
    boundary = '${air_solid_iface} air_top ${salt_air_iface}'
    fixed_temperature_boundary = 'air_top'
    fixed_boundary_temperatures = '300'
    emissivity = ${emissivities}
    temperature = radiation_temperature
    execute_on = 'LINEAR TIMESTEP_BEGIN TIMESTEP_END NONLINEAR'
  [../]

  [vf_study]
    type = ViewFactorRayStudy
    execute_on = INITIAL
    boundary = '${air_solid_iface} air_top ${salt_air_iface}'
    face_order = CONSTANT
    polar_quad_order = 2 #16
    azimuthal_quad_order = 2 #16
    face_type = GAUSS
    warn_non_planar = false
  []

  [rt_vf]
    type = RayTracingViewFactor
    boundary = '${air_solid_iface} air_top ${salt_air_iface}'
    execute_on = INITIAL
    ray_study_name = vf_study
    normalize_view_factor = true
  []
[]

[RayBCs]
  [vf]
    type = ViewFactorRayBC
    boundary = '${air_solid_iface} air_top ${salt_air_iface}'
  []
[]

[LinearFVBCs]
  # temperature BCs
  [top_solid_temp]
    type = LinearFVAdvectionDiffusionFunctorDirichletBC
    variable = temp_solid
    boundary = 'solid_top'
    functor = 301.15
  []
  [outer_solid_temp]
    type = LinearFVAdvectionDiffusionFunctorDirichletBC
    variable = temp_solid
    boundary = 'external_wall'
    functor = 301.15
  []
  [./radiation_solidwalls]
    type = LinearFVGrayLambert
    variable = temp_solid
    temperature_radiation = radiation_temperature
    coeff_diffusion = ${k_solid}
    surface_radiation_object_name = gray_lambert
    boundary = ${air_solid_iface}
    reconstruct_emission = false
  [../]
  [./radiation_salt_air_iface]
    type = LinearFVGrayLambert
    variable = h_salt
    temperature_radiation = radiation_temperature
    coeff_diffusion = 'kappa_h_salt'
    surface_radiation_object_name = gray_lambert
    boundary = ${salt_air_iface}
    reconstruct_emission = false
  [../]

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
  # [rad_hflux]
  #   type = ParsedFunctorMaterial
  #   property_name = rad_hflux
  #   functor_names = 'temp_salt'
  #   expression = '-5.67e-8*(pow(temp_salt,4)-pow(301.15,4))' #'-5.67e-8*(pow(temp_salt,4)-pow(301.15,4))'
  #   block = salt
  # []
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
  # Mixture properties
  # [eff_props]
  #   # Use the linear-FV mixture functor material (Real-only) to avoid AD dependencies.
  #   type = WCNSLinearFVMixtureFunctorMaterial
  #   phase_2_names = 'cp_s k_s rho_s'
  #   phase_1_names = 'cp_l k_l rho_l'
  #   prop_names = 'cp_mixture k_mixture rho_mixture'
  #   phase_1_fraction = liquid_fraction
  # []
  # [darcy_coeff_friction]
  #   type = ParsedFunctorMaterial
  #   property_name = 'darcy_coef_friction'
  #   functor_names = 'darcy_coef'
  #   functor_symbols = 'darcy_coef'
  #   expression = 'darcy_coef'
  # []
  # [forch_coeff_friction]
  #   type = ParsedFunctorMaterial
  #   property_name = 'forch_coef_friction'
  #   functor_names = 'U fch_coef'
  #   functor_symbols = 'U fch_coef'
  #   expression = 'fch_coef * U'
  # []
[]

# [Debug]
#   show_functors = true
# []

[Executioner]
  type = PIMPLE
  num_iterations = 20
  dt = 0.02
  end_time = 0.4
  should_solve_momentum = false
  should_solve_pressure = false
  energy_system = 'energy_system'
  solid_energy_system = 'solid_energy_system'
  energy_l_abs_tol = 1e-6
  energy_l_tol = 1e-8
  energy_equation_relaxation = 0.5
  energy_field_relaxation = 0.5
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
    sync_times = '0.4 10 90'
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
