# %%
# This script plots the validation results based on the moose navier_stokes simulation
# and experimental measurements. User needs to edit appropriately
##### LOAD MODULES ###############
import numpy as np
import matplotlib.pyplot as plt
radial_surface_temp_10s = np.genfromtxt("radial_surface_temp_10s.csv", skip_header=0, delimiter=',')
radial_surface_temp_90s = np.genfromtxt("radial_surface_temp_90s.csv", skip_header=0, delimiter=',')
salt_spill_FLiNaK_out_radial_10s = np.genfromtxt("salt_spill_FLiNaK_out_radial_10s.csv", skip_header=1, delimiter=',')
salt_spill_FLiNaK_out_radial_90s = np.genfromtxt("salt_spill_FLiNaK_out_radial_90s.csv", skip_header=1, delimiter=',')
salt_spill_FLiNaK_cht_out_radial_10s = np.genfromtxt("salt_spill_FLiNaK_cht_out_radial_10s.csv", skip_header=1, delimiter=',')
salt_spill_FLiNaK_cht_out_radial_90s = np.genfromtxt("salt_spill_FLiNaK_cht_out_radial_90s.csv", skip_header=1, delimiter=',')
############### MAKE PRETTY ###################
plt.rcParams["font.family"] = "serif"
plt.rcParams["mathtext.fontset"] = "dejavuserif"
###############################################

plt.figure()

# --- Experimental data: Argonne, MSR Salt Spill Accident Testing Using Eutectic NaCl-UCl_3, Sara Thomas and Josh Jackson. 2022 ---
plt.plot(
    radial_surface_temp_10s[:, 0], radial_surface_temp_10s[:, 1] + 273.15,
    linestyle='-',
    # marker='o',
    # markersize=6,
    # markerfacecolor='none',   # see-through
    # markeredgecolor='k',      # black edge
    # markeredgewidth=1.2,
    color ='red',
    label="experiment at 10 seconds, 1/4inch beaker"
)

# --- Experimental data: Argonne, MSR Salt Spill Accident Testing Using Eutectic NaCl-UCl_3, Sara Thomas and Josh Jackson. 2022 ---
plt.plot(
    radial_surface_temp_90s[:, 0], radial_surface_temp_90s[:, 1] + 273.15,
    linestyle='-',
    # marker='o',
    # markersize=6,
    # markerfacecolor='none',   # see-through
    # markeredgecolor='k',      # black edge
    # markeredgewidth=1.2,
    color ='blue',
    label="experiment at 90 seconds, 1/4inch beaker"
)


# --- Simulation results RTL ---
plt.plot(
    0.0254 - salt_spill_FLiNaK_out_radial_10s[:,2],
    salt_spill_FLiNaK_out_radial_10s[:,1],
    linestyle='-.',
    color='black',
    label="MOOSe N-S at 10 seconds, 1/4inch beaker",
)

# --- Simulation results RTL ---
plt.plot(
    0.0254 - salt_spill_FLiNaK_out_radial_90s[:,2],
    salt_spill_FLiNaK_out_radial_90s[:,1],
    linestyle=':',
    color='black',
    label="MOOSe N-S at 90 seconds, 1/4inch beaker",
)

# --- Simulation results RTL ---
plt.plot(
    0.0254 - salt_spill_FLiNaK_cht_out_radial_10s[:,2],
    salt_spill_FLiNaK_cht_out_radial_10s[:,1],
    linestyle='-.',
    color='green',
    label="MOOSe cht N-S at 10 seconds, 1/4inch beaker",
)

# --- Simulation results RTL ---
plt.plot(
    0.0254 - salt_spill_FLiNaK_cht_out_radial_90s[:,2],
    salt_spill_FLiNaK_cht_out_radial_90s[:,1],
    linestyle=':',
    color='green',
    label="MOOSe cht N-S at 90 seconds, 1/4inch beaker",
)

# --- Titles and labels ---
plt.title(
    r"Radial temperature profile" "\n"
    "On salt surface",
    fontsize=13
)
plt.xlabel(r'$radial~location~[m](distance~from~beaker~wall)$', fontsize=14)
plt.ylabel(r'$Temperature~[K]$', fontsize=14)

# --- Legend and layout ---
plt.legend(fontsize=8, loc='lower left')
plt.xlim(0, 0.0254)
# plt.ylim(670, 840)
plt.xticks(fontsize=14)
plt.yticks(fontsize=14)
plt.grid(True)

# --- Save and show ---
plt.savefig("surface_temp_radial_profile.png", dpi=300, bbox_inches='tight')
plt.show()

# %%
