# generate_patches_file.py

base_patch = 1
salt_air = 64
air_solid = 96

# Generate patch names
salt_air_list = [f"salt_air_iface_{i}" for i in range(salt_air)]
air_solid_list = [f"air_solid_iface_{i}" for i in range(air_solid)]

# Total emissivities
total = base_patch + salt_air + air_solid
emissivities = ["0.95"] * total

# Build file contents
content = f"""
# Auto-generated patch configuration

salt_air_interface = '{" ".join(salt_air_list)}'

air_solid_interface = '{" ".join(air_solid_list)}'

emissivities = '{" ".join(emissivities)}'

# totals
# salt_air patches: {salt_air}
# air_solid patches: {air_solid}
# emissivities: {total}
"""

# Write (overwrite) file
with open("patches_FLiNaK.i", "w") as f:
    f.write(content)

print("File 'patches_FLiNaK.i' written successfully.")
print(f"Total emissivities: {total}")