[Postprocessors]
  # Air top (fixed temperature boundary participating in radiation)
  [air_top]
    type = GrayLambertSurfaceRadiationPP
    surface_radiation_object_name = gray_lambert
    return_type = RADIOSITY
    boundary = 'air_top'
  []

  # Air–solid interface patches 
  [air_solid_iface_0]
    type = GrayLambertSurfaceRadiationPP
    surface_radiation_object_name = gray_lambert
    return_type = RADIOSITY
    boundary = 'air_solid_iface_0'
  []
  [air_solid_iface_1]
    type = GrayLambertSurfaceRadiationPP
    surface_radiation_object_name = gray_lambert
    return_type = RADIOSITY
    boundary = 'air_solid_iface_1'
  []
  [air_solid_iface_2]
    type = GrayLambertSurfaceRadiationPP
    surface_radiation_object_name = gray_lambert
    return_type = RADIOSITY
    boundary = 'air_solid_iface_2'
  []
  [air_solid_iface_3]
    type = GrayLambertSurfaceRadiationPP
    surface_radiation_object_name = gray_lambert
    return_type = RADIOSITY
    boundary = 'air_solid_iface_3'
  []
  [air_solid_iface_4]
    type = GrayLambertSurfaceRadiationPP
    surface_radiation_object_name = gray_lambert
    return_type = RADIOSITY
    boundary = 'air_solid_iface_4'
  []

  [T_salt_avg]
    type = ElementAverageValue
    variable = temp_salt
    block = salt
    execute_on = 'INITIAL TIMESTEP_END'
  []

  [T_salt_surface_avg]
    type = SideAverageValue
    variable = temp_salt
    boundary = '${salt_air_interface}'
    execute_on = 'INITIAL TIMESTEP_END'
  []

  [T_salt_surface_avg_10]
    type = SideAverageValue
    variable = temp_salt
    boundary = 'salt_air_iface_10'
    execute_on = 'INITIAL TIMESTEP_END'
  []

  # Debug flux on one representative SALT-side patch
  [q_salt_3]
    type = GrayLambertSurfaceRadiationPP
    surface_radiation_object_name = gray_lambert
    return_type = HEAT_FLUX_DENSITY
    boundary = 'salt_air_iface_3'
  []

  [radiation_air_top_net_flux]
    type = GrayLambertSurfaceRadiationPP
    surface_radiation_object_name = gray_lambert
    return_type = HEAT_FLUX_DENSITY
    boundary = 'air_top'
  []
[]
