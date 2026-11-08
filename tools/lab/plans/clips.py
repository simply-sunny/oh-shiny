# The wiki's clips. Each run is one launch with its own pack settings; each shot teleports, waits for the
# chunks, then holds or speeds time for its clip. A shot logs "LAB SHOT <name>" so cut.py can find it.
GROUND = {(-240, 930): 71, (-270, 896): 64, (-210, 896): 68, (16, 112): 68, (48, -16): 63, (48, 170): 63,
          (144, -240): 63, (-48, 272): 65}   # from heights.py
CAM = {  # x, z, height, yaw, pitch
    'village_w': (-210, 896, 14, 90, 18), 'village_e': (-270, 896, 14, -90, 18), 'village_close': (-270, 896, 6, -90, 22),
    'lake': (48, -16, 2, -90, -8), 'forest': (16, 112, 2, -90, -8), 'hills': (48, 170, 30, 180, 12),
    'sea_sunset': (144, -240, 4, 90, 4), 'beach_sunset': (-48, 272, 6, 90, -2)}
SETTLE, TAIL = 6, 1
SHOTS = {  # camera, start time, seconds, time added per tick
    'tour': ('village_w', 0, 20, 45), 'presets': ('village_e', 3000, 4, 0), 'shadows': ('village_e', 1000, 12, 40),
    'pixel': ('village_close', 3000, 4, 0), 'light': ('village_w', 18000, 5, 0), 'water': ('lake', 2000, 10, 0),
    'sky': ('sea_sunset', 11000, 18, 15), 'rays': ('forest', 1200, 4, 0), 'waving': ('forest', 1200, 10, 0),
    'fog': ('hills', 3000, 4, 0), 'sunset': ('beach_sunset', 12300, 3, 0), 'seaday': ('sea_sunset', 6000, 5, 0)}
LAPSES = sorted({s[3] for s in SHOTS.values() if s[3]})

def run(shots):
    ev, t = {0: ['gamerule advance_time false']}, 40
    for name in shots:
        cam, start, secs, lapse = SHOTS[name]
        x, z, h, yaw, pitch = CAM[cam]
        y = GROUND[(x, z)] + h
        ev[t] = [f'scoreboard players set #lapse lab 0', f'time set {start}', f'tp @a {x} {y} {z} {yaw} {pitch}', f'say LAB SHOT {name}']
        if lapse: ev[t + SETTLE * 20] = [f'scoreboard players set #lapse lab {lapse}']
        t += (SETTLE + secs + TAIL) * 20
    ev[t] = ['scoreboard players set #lapse lab 0']
    # Time-lapses: the tick function adds #lapse to the time every tick.
    ev['tick'] = [f'execute if score #lapse lab matches {l} run time add {l}' for l in LAPSES]
    return ev, t + 20

PRESET = {
    'low': {'shadowMapResolution': 1024, 'shadowDistance': 64.0, 'MOB_SHADOWS': 'false', 'WATER_REFLECTIONS': 'false', 'AMBIENT_OCCLUSION': 'false'},
    'high': {'shadowDistance': 128.0, 'SUN_RAYS': 'true'},
    'ultra': {'shadowMapResolution': 4096, 'shadowDistance': 192.0, 'SUN_RAYS': 'true'}}
RUNS = {
    'base': ({}, *run(['tour', 'presets', 'shadows', 'pixel', 'light', 'water', 'sky', 'rays', 'waving', 'fog', 'sunset'])),
    'low': (PRESET['low'], *run(['presets'])), 'high': (PRESET['high'], *run(['presets'])), 'ultra': (PRESET['ultra'], *run(['presets'])),
    'pixel1': ({'PIXEL_SHADOWS': 'true', 'SUNSET_COLOR': 1}, *run(['pixel', 'sunset'])),
    'pixel2': ({'PIXEL_SHADOWS': 'true', 'PIXEL_SHADOWS_SOFT': 'true', 'SUNSET_COLOR': 2}, *run(['pixel', 'sunset'])),
    'light0': ({'COLORED_LIGHT': 'false', 'SUNSET_COLOR': 3}, *run(['light', 'sunset'])),
    'rays1': ({'SUN_RAYS': 'true', 'SUN_RAYS_STRENGTH': 1}, *run(['rays'])),
    'rays2': ({'SUN_RAYS': 'true'}, *run(['rays'])),
    'rays3': ({'SUN_RAYS': 'true', 'SUN_RAYS_STRENGTH': 3}, *run(['rays'])),
    'fog30': ({'FOG_AMOUNT': 30}, *run(['fog'])), 'fog60': ({'FOG_AMOUNT': 60}, *run(['fog'])), 'fog90': ({'FOG_AMOUNT': 90}, *run(['fog'])),
    'waterfix': ({}, *run(['water', 'seaday'])),
    'sunset4': ({'SUNSET_COLOR': 4}, *run(['sunset'])), 'sunset5': ({'SUNSET_COLOR': 5}, *run(['sunset'])),
}
