# A look around: each candidate spot for 8 seconds, so the clips' cameras can be picked from real frames.
SPOTS = [  # name, x, z, height above the surface, yaw, pitch, time
    ('village_n', -240, 930, 14, 180, 18, 3000), ('village_e', -270, 896, 14, -90, 18, 3000),
    ('village_w', -210, 896, 14, 90, 18, 3000), ('beach_n', -48, 300, 6, 180, 8, 3000),
    ('beach_s', -48, 245, 6, 0, 8, 3000), ('beach_e', -80, 272, 6, -90, 8, 3000),
    ('beach_w', -16, 272, 6, 90, 8, 3000), ('forest_e', 16, 112, 2, -90, -8, 1200),
    ('dark_e', 48, -16, 2, -90, -8, 1200), ('birch_e', -80, 16, 2, -90, -8, 1200),
    ('hills_n', 48, 170, 30, 180, 12, 3000), ('hills_s', 48, 120, 30, 0, 12, 3000),
    ('ocean_w', 144, -240, 4, 90, 4, 12000), ('beach_sunset', -48, 272, 6, 90, -2, 12000),
]
GROUND = {(-240, 930): 71, (-270, 896): 64, (-210, 896): 68, (-240, 896): 63, (-48, 300): 63, (-48, 245): 67, (-80, 272): 68, (-16, 272): 72, (-48, 272): 65, (16, 112): 68, (48, -16): 63, (-80, 16): 66, (48, 170): 63, (48, 120): 68, (48, 144): 71, (144, -240): 63}  # from heights.py
ev = {}
for i, (n, x, z, h, yaw, pitch, t) in enumerate(SPOTS):
    at = 40 + i * 160
    ev[at] = [f'time set {t}', f'tp @a {x} {GROUND[(x, z)] + h} {z} {yaw} {pitch}']
RUNS = {'look': ({}, ev, 40 + len(SPOTS) * 160 + 20)}
