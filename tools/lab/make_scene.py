# Builds the oh-shiny-scene world: a copy of an ordinary survival world (natural terrain, so the wiki's shots look like
# the game), with the player a spectator, time and weather frozen and mobs kept from spawning, and a datapack whose
# lab:lights function places the lights for the night shots. The source world is only read.
#
#   python3 make_scene.py [source save, default 5]
import sys, os, shutil, json
sys.path.insert(0, os.path.dirname(__file__))
import nbt
from nbt import Tag

SAVES = os.path.expanduser('~/Library/Application Support/PrismLauncher/instances/26.3/minecraft/saves')
SRC, DST = os.path.join(SAVES, sys.argv[1] if len(sys.argv) > 1 else '5'), os.path.join(SAVES, 'oh-shiny-scene')
assert not os.path.exists(DST) or os.path.exists(os.path.join(DST, '.lab')), 'refusing to overwrite'
shutil.rmtree(DST, ignore_errors=True)
shutil.copytree(SRC, DST, ignore=shutil.ignore_patterns('session.lock'))
open(os.path.join(DST, '.lab'), 'w').write(f'copied from {SRC} by make_scene.py\n')

lvl = nbt.load(os.path.join(DST, 'level.dat'))
d = lvl['Data'].v
d['LevelName'] = Tag(8, 'oh shiny! scene')
d['GameType'] = Tag(3, 3)
d['allowCommands'] = Tag(1, 1)
d.pop('Player', None)
d.pop('singleplayer_uuid', None)
enabled = d['DataPacks'].v['Enabled']
names = [t.v for t in enabled.v[1]]
if 'file/scene' not in names:
    enabled.v[1].append(Tag(8, 'file/scene'))
nbt.save(os.path.join(DST, 'level.dat'), lvl)
# The player's own file would put them back where they last stood, in survival.
shutil.rmtree(os.path.join(DST, 'players'), ignore_errors=True)
shutil.rmtree(os.path.join(DST, 'playerdata'), ignore_errors=True)

rules = os.path.join(DST, 'data/minecraft/game_rules.dat')
gr = nbt.load(rules)
r = gr['data'].v
for k in ('advance_time', 'advance_weather', 'spawn_mobs', 'spawn_monsters', 'spawn_phantoms', 'spawn_patrols',
          'spawn_wandering_traders', 'send_command_feedback', 'command_block_output', 'log_admin_commands',
          'random_tick_speed', 'show_advancement_messages', 'locator_bar'):
    r['minecraft:' + k] = Tag(1, 0)
nbt.save(rules, gr)

P = os.path.join(DST, 'datapacks/scene')
F = os.path.join(P, 'data/lab/function')
os.makedirs(F)
json.dump({'pack': {'description': 'oh shiny! scene', 'min_format': 121, 'max_format': 121}}, open(os.path.join(P, 'pack.mcmeta'), 'w'))
os.makedirs(os.path.join(P, 'data/minecraft/tags/function'))
json.dump({'values': ['lab:tick']}, open(os.path.join(P, 'data/minecraft/tags/function/tick.json'), 'w'))
open(os.path.join(F, 'tick.mcfunction'), 'w').write('gamemode spectator @a[gamemode=!spectator]\n')
print('made', DST)
