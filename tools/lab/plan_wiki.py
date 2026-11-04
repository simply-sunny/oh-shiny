# The wiki's How it works shots, in the oh-shiny-scene world (make_scene.py): each variant is one change from the
# pack's defaults (Medium), except the presets. Leadlight must have the pack enabled in leadlight/pack.txt, with no
# shadowdistance line of its own. Run with: LAB_OUT=<dir> python3 capture.py plan_wiki.py, then to_wiki.py <dir>.
D = {}
mc("cmd", "tick freeze")  # clouds and water hold still, so frames differ only by their setting
OFF = 'false'
LOW = {'MOB_SHADOWS': OFF, 'shadowMapResolution': '1024', 'shadowDistance': '64.0', 'WATER_REFLECTIONS': OFF, 'AMBIENT_OCCLUSION': OFF}
HIGH = {'shadowDistance': '128.0', 'SUN_RAYS': 'true'}
ULTRA = {'shadowMapResolution': '4096', 'shadowDistance': '192.0', 'SUN_RAYS': 'true'}
shot('day', 1000, (-40, 68, 104), (-40, 4), {
    'default': D, 'low': LOW, 'high': HIGH, 'ultra': ULTRA,
    'shadows_off': {'SHADOWS': OFF}, 'pixel': {'PIXEL_SHADOWS': 'true'}, 'blur4': {'SHADOW_SOFTNESS': '4'},
    'dist32': {'shadowDistance': '32.0'}, 'dist192': {'shadowDistance': '192.0'},
    'res1024': {'shadowMapResolution': '1024'}, 'res4096': {'shadowMapResolution': '4096'},
    'ao_off': {'AMBIENT_OCCLUSION': OFF}, 'rays1': {'SUN_RAYS': 'true', 'SUN_RAYS_STRENGTH': '1'},
    'rays2': {'SUN_RAYS': 'true'}, 'rays3': {'SUN_RAYS': 'true', 'SUN_RAYS_STRENGTH': '3'},
    'refl_off': {'WATER_REFLECTIONS': OFF}, 'bloom_off': {'BLOOM': OFF}, 'fog50': {'FOG_AMOUNT': '50'},
    'aa_none': {'SMOOTH_EDGES': OFF}, 'fxaa': {'FXAA': 'true'}, 'taa': {'TAA': 'true'}}, settle=4)
shot('sunset', 12600, (-36, 69, 120), (110, 2), {
    'default': D, **{f'color{c}': {'SUNSET_COLOR': str(c)} for c in range(1, 6)},
    'rays2': {'SUN_RAYS': 'true'}, 'refl_off': {'WATER_REFLECTIONS': OFF}, 'bloom_off': {'BLOOM': OFF}})
shot('night', 114000, (-36, 70, 108), (-45, 25), {
    'default': D, 'colored_off': {'COLORED_LIGHT': OFF}, 'bloom_off': {'BLOOM': OFF}, 'ao_off': {'AMBIENT_OCCLUSION': OFF}})
