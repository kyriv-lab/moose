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
emissivity= 0.95
sigma_a = 276 # m^-1
diffusion_coef = ${fparse 1/(3*sigma_a)}

######## 316 stainless steel properties ########
rho_solid=8000.0 #Density of steel container~[kg/m3]
cp_solid=600.0 #Specific heat capacity~[J/(Kg*K)]
k_solid=16.0 #Thermal conductivity~[W/(m-k)]

ambient_boundary = 'external_wall solid_top'

[Problem]
  kernel_coverage_check = false
  linear_sys_names = 'energy_system u_system v_system w_system p_system radiation_system'
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
    n_patches = 96
    input = file
  []
  [patch_wall]
    type = PatchSidesetGenerator
    boundary = 'salt_air_iface'
    n_patches = 64
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
  [G]
    type = MooseLinearVariableFVReal
    solver_sys = 'radiation_system'
    initial_condition = ${fparse 4*sigma_a*pow(T_initial,4)}
    block = 'salt'
  []
[]

[AuxVariables]
  [fl]
    type = MooseVariableFVReal
    initial_condition = 1.0
    block = salt
  []
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
[]

[FVICs]
  [ic_u_1]
    type = FVConstantIC
    variable = temperature
    value = ${ambient_temperature}
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

  ### G conservation equation
  [fluid_radiation]
    type = LinearFVP1TemperatureSourceSink
    variable = temperature
    G = 'G'
    absorption_coeff = ${sigma_a}
    block = salt
  []

  [G_diffusion]
    type = LinearFVDiffusion
    variable = G
    diffusion_coeff = ${diffusion_coef}
    block = salt
  []

  [G_source_and_sink]
    type = LinearFVP1RadiationSourceSink
    variable = G
    temperature_radiation = temperature
    absorption_coeff = ${sigma_a}
    block = salt
  []
[]

[UserObjects]
  [gray_lambert]
    type = ViewFactorObjectSurfaceRadiation
    boundary = '${air_solid_interface} air_top ${salt_air_interface}'
    fixed_temperature_boundary = 'air_top'
    fixed_boundary_temperatures = '${ambient_temperature}'
    emissivity = ${emissivities}
    temperature = temperature
    execute_on = 'LINEAR TIMESTEP_BEGIN TIMESTEP_END NONLINEAR'
  []

  [vf_study]
    type = ViewFactorRayStudy
    execute_on = INITIAL
    boundary = '${air_solid_interface} air_top ${salt_air_interface}'
    face_order = CONSTANT
    polar_quad_order = 8
    azimuthal_quad_order = 8
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
    type = LinearFVFunctorRadiativeBC
    variable = temperature
    boundary = '${ambient_boundary}'
    emissivity = ${emissivity}
    Tinfinity = ${ambient_temperature}
    diffusion_coeff =  ${k_solid}
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
  ### G BCs
  [solid_walls_bc_G]
    type = LinearFVP1RadiationMarshakBC
    boundary = 'salt_solid_wall'
    variable = G
    temperature_radiation = temperature
    coeff_diffusion = ${diffusion_coef}
    boundary_emissivity = ${emissivity}
  []

  [salt_air_IF_bc_G]
    type = LinearFVP1RadiationMarshakBC
    boundary = ${salt_air_interface}
    variable = G
    temperature_radiation = temperature
    coeff_diffusion = ${diffusion_coef}
    boundary_emissivity = ${emissivity}
  []
[]

[VectorPostprocessors]
  [radial]
    type = LineValueSampler
    start_point = '0 0 0.01884' # height of salt surface 0.01885 m
    end_point = '0.0254 0 0.01884'
    num_points = 100
    variable = 'temperature'
    sort_by = 'x'
    execute_on = 'TIMESTEP_END FINAL'
  []
[]

[Executioner]
  type = PIMPLE
  num_iterations = 20
  dt = 0.1
  end_time = 10.0
  should_solve_momentum = false
  should_solve_pressure = false
  pm_radiation_systems = 'radiation_system'
  energy_system = 'energy_system'
  pm_radiation_l_abs_tol = 1e-11
  pm_radiation_l_tol = 0
  energy_l_abs_tol = 5e-8
  energy_l_tol = 1e-10
  pm_radiation_equation_relaxation = 1.0
  energy_equation_relaxation = 0.8
  energy_field_relaxation = 0.8
  energy_absolute_tolerance = 5e-8
  pm_radiation_absolute_tolerance = 1e-10
  energy_petsc_options_iname = '-pc_type -pc_hypre_type'
  energy_petsc_options_value = 'hypre boomeramg'
  pm_radiation_petsc_options_iname = '-pc_type -pc_hypre_type'
  pm_radiation_petsc_options_value = 'hypre boomeramg'
  print_fields = false
  continue_on_max_its = true

  rhie_chow_user_object = 'rc'
  momentum_systems = 'u_system v_system w_system'
  pressure_system = 'p_system'
[]

[Outputs]
  exodus = true
  [out]
    type = CSV
    sync_times = '10 90'
    sync_only = true
  []
[]

!include PP_FLiNaK.i