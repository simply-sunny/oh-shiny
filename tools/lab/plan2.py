D = {}
cx, ax = 48, 96
shot('ao', 6000, (ax - 1, 66, -5), (0, 28), {'default': D, 'ao_off': {'AMBIENT_OCCLUSION': 'false'}})
shot('shadows', 2500, (cx + 8, 68, -9), (35, 32), {
    'default': D, 'pixel': {'PIXEL_SHADOWS': 'true'}, 'blur4': {'SHADOW_SOFTNESS': '4'},
    'no_mob_shadows': {'MOB_SHADOWS': 'false'}, 'shadows_off': {'SHADOWS': 'false'}})
shot('shadows_close', 2500, (cx - 4, 66, 4), (0, 85), {
    'default': D, 'pixel': {'PIXEL_SHADOWS': 'true'}, 'pixel_soft': {'PIXEL_SHADOWS': 'true', 'PIXEL_SHADOWS_SOFT': 'true'},
    'blur4': {'SHADOW_SOFTNESS': '4'}})
shot('aa', 6000, (cx + 9, 64.6, -2), (90, -4), {
    'smooth_edges': D, 'none': {'SMOOTH_EDGES': 'false'}, 'fxaa': {'FXAA': 'true'}, 'taa': {'TAA': 'true'}}, settle=4)
