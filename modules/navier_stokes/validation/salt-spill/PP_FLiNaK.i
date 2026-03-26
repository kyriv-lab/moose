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

  # --- SALT–AIR interface ---
  # Total/group radiosity over the salt-side interface (nonzero check)
  [salt_air_iface_salt_radiosity]
    type = GrayLambertSurfaceRadiationPP
    surface_radiation_object_name = gray_lambert
    return_type = RADIOSITY
    boundary = '${salt_air_interface}'
  []

  # Net heat flux density on the SALT-side interface (this is the one you care about)
  [radiation_salt_air_net_flux]
    type = GrayLambertSurfaceRadiationPP
    surface_radiation_object_name = gray_lambert
    return_type = HEAT_FLUX_DENSITY
    boundary = '${salt_air_interface}'
  []

  [T_salt_avg]
    type = ElementAverageValue
    variable = temperature
    block = salt
    execute_on = 'INITIAL TIMESTEP_END'
  []

  [T_salt_surface_avg]
    type = SideAverageValue
    variable = temperature
    boundary = '${salt_air_interface}'
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
