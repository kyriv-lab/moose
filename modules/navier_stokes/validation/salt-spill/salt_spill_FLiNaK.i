######## FLiNaK material properties #####################
T_initial = 876.15 #Initial temperature~[K]
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

######## 316 stainless steel properties ########
rho_solid=8000.0 #Density of steel container~[kg/m3]
cp_solid=600.0 #Specific heat capacity~[J/(Kg*K)]
k_solid=16.0 #Thermal conductivity~[W/(m-k)]

ambient_boundary = 'external_wall solid_top'

[Problem]
  kernel_coverage_check = false
  linear_sys_names = 'energy_system u_system v_system w_system p_system'
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
    n_patches = 1536
    input = file
  []
  [patch_wall]
    type = PatchSidesetGenerator
    boundary = 'salt_air_iface'
    n_patches = 1024
    input = patch_bot
    partitioner = centroid
    centroid_partitioner_direction = x
  []
  [top_deletion]
    type = BoundaryDeletionGenerator
    input = patch_wall
    boundary_names = 'air_solid_iface salt_air_iface'
  []
[]

!include patches_FLiNaK.i

[Variables]
  [temperature]
    type = MooseLinearVariableFVReal
    solver_sys = 'energy_system'
    block = 'solid salt'
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
  [fl]
    type = MooseVariableFVReal
    initial_condition = 1.0
    block = salt
  []
  # [density]
  #   type = MooseVariableFVReal
  # []
  # [th_cond]
  #   type = MooseVariableFVReal
  # []
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
  [compute_fl]
    type = NSLiquidFractionAux
    variable = fl
    temperature = temperature
    T_liquidus = '${T_liquidus}'
    T_solidus = '${T_solidus}'
    execute_on = 'TIMESTEP_END'
    block = salt
  []
  # [rho_out]
  #   type = FunctorAux
  #   functor = 'rho_mixture'
  #   variable = 'density'
  # []
  # [th_cond_out]
  #   type = FunctorAux
  #   functor = 'k_mixture'
  #   variable = 'th_cond'
  # []
  # [cp_out]
  #   type = FunctorAux
  #   functor = 'cp_mixture'
  #   variable = 'cp_var'
  # []
  # [darcy_out]
  #   type = FunctorAux
  #   functor = 'Darcy_coefficient'
  #   variable = 'darcy_coef'
  # []
  # [fch_out]
  #   type = FunctorAux
  #   functor = 'Forchheimer_coefficient'
  #   variable = 'fch_coef'
  # []
[]

[FVICs]
  [ic_u_1]
    type = FVConstantIC
    variable = temperature
    value = 301.15
    block = 'solid'
  []
  [ic_u_2]
    type = FVConstantIC
    variable = temperature
    value = ${T_initial}
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

  [temp_time_salt]
    type = LinearFVTimeDerivative
    variable = temperature
    factor = ${fparse rho_salt_l*cp_salt_l}
    block = salt
  []
  [temp_conduction_salt]
    type = LinearFVDiffusion
    diffusion_coeff = ${k_salt_l}
    variable = temperature
    block = salt
  []
  [temp_phasechange_source]
    type = LinearFVPhaseChangeSource
    variable = temperature
    L = ${L}
    T_liquidus = ${T_liquidus}
    T_solidus = ${T_solidus}
    rho = ${rho_salt_l}
    block = salt
  []

  [temp_time_solid]
    type = LinearFVTimeDerivative
    variable = temperature
    factor = ${fparse rho_solid*cp_solid}
    block = solid
  []
  [temp_conduction_solid]
    type = LinearFVDiffusion
    diffusion_coeff = ${k_solid}
    variable = temperature
    block = solid
  []
[]

[UserObjects]
  [gray_lambert]
    type = ViewFactorObjectSurfaceRadiation
    boundary = '${air_solid_interface} air_top ${salt_air_interface}'
    fixed_temperature_boundary = 'air_top'
    fixed_boundary_temperatures = '300'
    emissivity = ${emissivities}
    temperature = temperature
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
    variable = temperature
    boundary = '${ambient_boundary}'
    functor = 301.15
  []
  [radiation_solidwalls]
    type = LinearFVGrayLambert
    variable = temperature
    temperature_radiation = temperature
    coeff_diffusion = ${k_solid}
    surface_radiation_object_name = gray_lambert
    boundary = ${air_solid_interface}
  []
  [radiation_salt_air_interface]
    type = LinearFVGrayLambert
    variable = temperature
    temperature_radiation = temperature
    coeff_diffusion = ${k_salt_l}
    surface_radiation_object_name = gray_lambert
    boundary = ${salt_air_interface}
  []
[]

[FunctorMaterials]
  # [ins_fv]
  #   type = INSFVEnthalpyFunctorMaterial
  #   rho = rho_mixture
  #   cp = cp_mixture
  #   temperature = 'T'
  # []
  # [eff_cp]
  #   type = NSFVMixtureFunctorMaterial
  #   phase_2_names = '${cp_salt_s} ${k_salt_s} ${rho_salt_s}'
  #   phase_1_names = '${cp_salt_l} ${k_salt_l} ${rho_salt_l}}'
  #   prop_names = 'cp_mixture k_mixture rho_mixture'
  #   phase_1_fraction = fl
  # []
  # [mushy_zone_resistance]
  #   type = INSFVMushyPorousFrictionFunctorMaterial
  #   liquid_fraction = 'fl'
  #   mu = '${mu}'
  #   rho_l = '${rho_liquid}'
  #   dendrite_spacing_scaling = 1e-1
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

[Executioner]
  type = PIMPLE
  num_iterations = 15
  dt = 0.1
  end_time = 0.1
  should_solve_momentum = false
  should_solve_pressure = false
  energy_system = 'energy_system'
  energy_l_abs_tol = 5e-8
  energy_l_tol = 1e-10
  energy_equation_relaxation = 0.8
  energy_field_relaxation = 0.8
  energy_absolute_tolerance = 5e-8
  energy_petsc_options_iname = '-pc_type -pc_hypre_type'
  energy_petsc_options_value = 'hypre boomeramg'
  print_fields = false
  continue_on_max_its = true

  rhie_chow_user_object = 'rc'
  momentum_systems = 'u_system v_system w_system'
  pressure_system = 'p_system'
[]

[Outputs]
  exodus = true
  csv = true
  [pgraph]
    type = PerfGraphOutput
    execute_on = 'final'  # Default is "final"
    level = 3                     # Default is 1
    heaviest_branch = true        # Default is false
    heaviest_sections = 7         # Default is 0
  []
[]

!include PP_FLiNaK.i