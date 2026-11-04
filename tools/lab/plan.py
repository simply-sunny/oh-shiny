D = {}
cx, ax, wx, rx = 48, 96, 144, 192
shot('lights', 18000, (0, 67, -9), (0, 20), {
    'default': D, 'colored_light_off': {'COLORED_LIGHT': 'false'}, 'bloom_off': {'BLOOM': 'false'}})
shot('lights_close', 18000, (-12.5, 65.2, 3), (0, 18), {'default': D, 'colored_light_off': {'COLORED_LIGHT': 'false'}})
shot('shadows', 2500, (cx + 13, 70, -13), (45, 28), {
    'default': D, 'pixel': {'PIXEL_SHADOWS': 'true'}, 'pixel_soft': {'PIXEL_SHADOWS': 'true', 'PIXEL_SHADOWS_SOFT': 'true'},
    'blur4': {'SHADOW_SOFTNESS': '4'}, 'no_mob_shadows': {'MOB_SHADOWS': 'false'}, 'shadows_off': {'SHADOWS': 'false'}})
shot('shadows_close', 2500, (cx - 4, 66.5, 3), (0, 55), {
    'default': D, 'pixel': {'PIXEL_SHADOWS': 'true'}, 'pixel_soft': {'PIXEL_SHADOWS': 'true', 'PIXEL_SHADOWS_SOFT': 'true'},
    'blur4': {'SHADOW_SOFTNESS': '4'}})
shot('ao', 6000, (ax - 7, 67, -7), (-45, 25), {'default': D, 'ao_off': {'AMBIENT_OCCLUSION': 'false'}})
shot('water', 4000, (wx, 66, -13), (0, 18), {'default': D, 'reflections_off': {'WATER_REFLECTIONS': 'false'}})
shot('water_sunset', 12600, (wx + 11, 65, 0), (90, 8), {'default': D})
shot('water_night', 18000, (wx, 66, -13), (0, 18), {'default': D})
shot('water_down', 6000, (wx - 4, 66, -2), (20, 70), {'default': D})
shot('sunrays', 1000, (rx - 8, 65, 0), (-90, -12), {
    'off': D, 'soft': {'SUN_RAYS': 'true', 'SUN_RAYS_STRENGTH': '1'}, 'strong': {'SUN_RAYS': 'true'},
    'insane': {'SUN_RAYS': 'true', 'SUN_RAYS_STRENGTH': '3'}})
shot('sky_night', 18000, (0, 90, -40), (180, -55), {'default': D})
shot('sky_sunset', 12400, (0, 90, -40), (90, -4), {
    f'color{i}': ({'SUNSET_COLOR': str(i)} if i else D) for i in range(6)})
shot('aa', 6000, (cx + 1, 65.5, -2), (-90, -5), {
    'smooth_edges': D, 'none': {'SMOOTH_EDGES': 'false'}, 'fxaa': {'FXAA': 'true'}, 'taa': {'TAA': 'true'}}, settle=4)
