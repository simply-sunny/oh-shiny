# Builds the oh-shiny-lab world: a void superflat, spectator, time and weather frozen, with a datapack
# that builds the test scenes once the player is in, and one function per camera shot.
import sys, os, shutil, json
sys.path.insert(0, os.path.dirname(__file__))
import nbt
from nbt import Tag

SAVES = os.path.expanduser('~/Library/Application Support/PrismLauncher/instances/26.3/minecraft/saves')
SRC, DST = os.path.join(SAVES, 'testiong'), os.path.join(SAVES, 'oh-shiny-lab')
assert not os.path.exists(DST) or os.path.exists(os.path.join(DST, '.lab')), 'refusing to overwrite'
shutil.rmtree(DST, ignore_errors=True)
os.makedirs(os.path.join(DST, 'data/minecraft'))
open(os.path.join(DST, '.lab'), 'w').write('made by make_lab.py\n')

lvl = nbt.load(os.path.join(SRC, 'level.dat'))
d = lvl['Data'].v
d['LevelName'] = Tag(8, 'oh shiny! lab')
d['GameType'] = Tag(3, 3)
d['allowCommands'] = Tag(1, 1)
d['Time'] = Tag(4, 6000)
d.pop('singleplayer_uuid', None)
d.pop('Player', None)
d['spawn'].v['pos'] = Tag(11, [0, 70, -20])
d['DataPacks'].v['Enabled'] = Tag(9, (8, [Tag(8, 'vanilla'), Tag(8, 'fabric-convention-tags-v2'), Tag(8, 'file/lab')]))
nbt.save(os.path.join(DST, 'level.dat'), lvl)

wg = nbt.load(os.path.join(SRC, 'data/minecraft/world_gen_settings.dat'))
ow = wg['data'].v['dimensions'].v['minecraft:overworld'].v
ow['generator'] = Tag(10, {
    'type': Tag(8, 'minecraft:flat'),
    'settings': Tag(10, {
        'biome': Tag(8, 'minecraft:plains'),
        'features': Tag(1, 0), 'lakes': Tag(1, 0),
        'layers': Tag(9, (10, [Tag(10, {'block': Tag(8, 'minecraft:air'), 'height': Tag(3, 1)})])),
        'structure_overrides': Tag(9, (8, [])),
    }),
})
wg['data'].v['generate_structures'] = Tag(1, 0)
nbt.save(os.path.join(DST, 'data/minecraft/world_gen_settings.dat'), wg)

gr = nbt.load(os.path.join(SRC, 'data/minecraft/game_rules.dat'))
r = gr['data'].v
for k, v in {'advance_time': 0, 'advance_weather': 0, 'spawn_mobs': 0, 'spawn_monsters': 0, 'spawn_phantoms': 0,
             'spawn_patrols': 0, 'spawn_wandering_traders': 0, 'send_command_feedback': 0, 'command_block_output': 0,
             'log_admin_commands': 0, 'random_tick_speed': 0, 'show_advancement_messages': 0, 'locator_bar': 0}.items():
    r['minecraft:' + k] = Tag(1, v)
nbt.save(os.path.join(DST, 'data/minecraft/game_rules.dat'), gr)

# ---------------------------------------------------------------- datapack
P = os.path.join(DST, 'datapacks/lab')
F = os.path.join(P, 'data/lab/function')
os.makedirs(F)
json.dump({'pack': {'description': 'oh shiny! lab scenes', 'min_format': 121, 'max_format': 121}}, open(os.path.join(P, 'pack.mcmeta'), 'w'))
os.makedirs(os.path.join(P, 'data/minecraft/tags/function'))
json.dump({'values': ['lab:load']}, open(os.path.join(P, 'data/minecraft/tags/function/load.json'), 'w'))
json.dump({'values': ['lab:tick']}, open(os.path.join(P, 'data/minecraft/tags/function/tick.json'), 'w'))

def fn(name, lines):
    path = os.path.join(F, name + '.mcfunction')
    os.makedirs(os.path.dirname(path), exist_ok=True)
    open(path, 'w').write('\n'.join(lines) + '\n')

fn('load', ['scoreboard objectives add lab dummy', 'forceload add -48 -48 240 48'])
# Waits for the chunks, builds once, and keeps the player a spectator at the first shot until then.
fn('tick', [
    'scoreboard players add #t lab 1',
    'execute if score #t lab matches 60 unless score #built lab matches 1 run function lab:build',
    'execute unless score #built lab matches 1 run tp @a 0 70 -20 0 20',
    'gamemode spectator @a[gamemode=!spectator]',
])

S = []  # build commands
def fill(a, b, block, mode=''):
    S.append(f'fill {a[0]} {a[1]} {a[2]} {b[0]} {b[1]} {b[2]} {block} {mode}'.strip())
def setb(p, block):
    S.append(f'setblock {p[0]} {p[1]} {p[2]} {block}')

# A. Colored light: a closed white room, a bay for each kind of light along the back wall, 5 blocks apart so
# no light's color is lost under a stronger neighbour's in the light map.
fill((-24, 63, -12), (24, 73, 12), 'minecraft:white_concrete', 'hollow')
lights = ['minecraft:torch', 'minecraft:soul_torch', 'minecraft:copper_torch', 'minecraft:sea_lantern', 'minecraft:amethyst_cluster',
          'minecraft:end_rod', 'minecraft:redstone_torch', 'minecraft:crying_obsidian', 'minecraft:lava_cauldron']
for i, b in enumerate(lights):
    x = -20 + i * 5
    setb((x, 64, 10), b)
    if i < len(lights) - 1:
        fill((x + 2, 64, 7), (x + 3, 68, 11), 'minecraft:white_concrete')

# B. Shadows: grass, a tree, a fence, bars, a wall, an armor stand and a sheep, in morning sun.
cx = 48
fill((cx - 16, 63, -16), (cx + 16, 63, 16), 'minecraft:grass_block')
fill((cx - 16, 62, -16), (cx + 16, 60, 16), 'minecraft:dirt')
fill((cx, 64, 0), (cx, 69, 0), 'minecraft:oak_log')
fill((cx - 2, 68, -2), (cx + 2, 69, 2), 'minecraft:oak_leaves[persistent=true]')
fill((cx - 1, 70, -1), (cx + 1, 71, 1), 'minecraft:oak_leaves[persistent=true]')
fill((cx - 8, 64, 6), (cx + 2, 64, 6), 'minecraft:oak_fence')
fill((cx + 5, 64, -6), (cx + 5, 66, 2), 'minecraft:iron_bars')
fill((cx - 9, 64, -8), (cx - 9, 65, -2), 'minecraft:cobblestone_wall')
S.append(f'summon minecraft:armor_stand {cx - 4} 64 -3 {{NoGravity:1b,ShowArms:1b,Rotation:[200f,0f]}}')
S.append(f'summon minecraft:sheep {cx + 2} 64 -10 {{NoAI:1b,Rotation:[30f,0f]}}')
fill((cx - 6, 64, 9), (cx - 4, 64, 13), 'minecraft:short_grass')

# C. Ambient occlusion: white steps into a corner, pillars and a ledge.
ax = 96
fill((ax - 8, 63, -8), (ax + 8, 63, 8), 'minecraft:white_concrete')
fill((ax - 8, 64, 6), (ax + 8, 70, 8), 'minecraft:white_concrete')
fill((ax + 6, 64, -8), (ax + 8, 70, 8), 'minecraft:white_concrete')
for i in range(5):
    fill((ax - 6 + i, 64, 5 - i), (ax + 5, 64 + i, 5 - i), 'minecraft:white_concrete')
fill((ax - 6, 64, -6), (ax - 6, 68, -6), 'minecraft:white_concrete')
fill((ax - 3, 64, -6), (ax - 3, 66, -6), 'minecraft:white_concrete')
fill((ax - 8, 69, 3), (ax + 5, 69, 5), 'minecraft:white_concrete')

# D. Water: a deep pool over sand with a lit pillar, an arch and seagrass, open to the sky.
wx = 144
fill((wx - 14, 63, -14), (wx + 14, 63, 14), 'minecraft:smooth_quartz')
fill((wx - 12, 59, -12), (wx + 12, 63, 12), 'minecraft:sand')
fill((wx - 12, 60, -12), (wx + 12, 63, 12), 'minecraft:water')
fill((wx - 2, 60, 2), (wx - 2, 63, 2), 'minecraft:seagrass')
for p in [(wx - 5, 61, 4), (wx - 4, 61, 5), (wx + 3, 61, -3), (wx + 6, 61, 1), (wx + 7, 61, 2)]:
    setb(p, 'minecraft:seagrass')
fill((wx, 64, 10), (wx, 70, 10), 'minecraft:stone_bricks')
fill((wx + 6, 64, 10), (wx + 6, 70, 10), 'minecraft:stone_bricks')
fill((wx, 71, 10), (wx + 6, 71, 10), 'minecraft:stone_bricks')
setb((wx + 3, 70, 10), 'minecraft:lantern[hanging=true]')
fill((wx - 8, 64, 6), (wx - 8, 68, 6), 'minecraft:quartz_pillar')
setb((wx - 8, 69, 6), 'minecraft:sea_lantern')

# E. Sun rays: a leaf canopy with gaps on log pillars, to look up through toward the sun.
rx = 192
fill((rx - 12, 63, -12), (rx + 12, 63, 12), 'minecraft:grass_block')
for px in (-9, 0, 9):
    for pz in (-9, 0, 9):
        fill((rx + px, 64, pz), (rx + px, 74, pz), 'minecraft:oak_log')
fill((rx - 12, 75, -12), (rx + 12, 76, 12), 'minecraft:oak_leaves[persistent=true]')
import random
rnd = random.Random(7)
for _ in range(26):
    x, z = rnd.randint(-11, 10), rnd.randint(-11, 10)
    fill((rx + x, 75, z), (rx + x + rnd.randint(0, 1), 76, z + rnd.randint(0, 1)), 'minecraft:air')

S.append('scoreboard players set #built lab 1')
S.append('tp @a 0 66 -8 0 5')
fn('build', S)

# Shots: time, then where the camera stands and looks (yaw 0 faces +z, 90 faces -x; pitch down is positive).
SHOTS = {
    'lights': (18000, (0, 66.2, -8), (0, 8)),
    'lights_close': (18000, (-4, 65.5, 3), (0, 12)),
    'shadows': (2000, (cx - 14, 69, -16), (-45, 22)),
    'shadows_close': (2000, (cx - 6, 66, -6), (-20, 40)),
    'ao': (6000, (ax - 7, 68.5, -7), (-35, 25)),
    'water': (4000, (wx - 2, 67, -14), (0, 20)),
    'water_sunset': (12600, (wx, 66, 8), (180, 10)),
    'water_night': (18000, (wx - 2, 67, -14), (0, 20)),
    'sunrays': (1000, (rx - 8, 66, 8), (-125, -35)),
    'sky_night': (18000, (0, 90, -40), (180, -50)),
    'sky_sunset': (12400, (0, 90, -40), (90, -5)),
}
for name, (t, pos, rot) in SHOTS.items():
    fn('shot/' + name, ['weather clear', f'time set {t}', f'tp @a {pos[0]} {pos[1]} {pos[2]} {rot[0]} {rot[1]}'])
print('shots:', ' '.join(SHOTS))
print('build commands:', len(S))
