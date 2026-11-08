# Records the wiki's clips without touching the keyboard: the Modrinth App launches the profile straight into
# the scene world, a datapack moves the camera and sets the time tick by tick, and rec-util's mcrec helper
# records the game window. Each setting the clips compare is a launch of its own, with the pack's settings
# file written before it starts.
#
#   python3 record.py setup iris|leadlight   swap the profile's mods to one loader (undo with restore)
#   python3 record.py restore                put the profile's mods, options and configs back
#   python3 record.py world                  copy the test save to oh-shiny-scene
#   python3 record.py scout                  launch once and log where the biomes and structures are
#   python3 record.py run <plan.py> [names]  record each run in the plan
import json, os, shutil, signal, subprocess, sys, time, urllib.parse

GAME = os.path.expanduser('~/Library/Application Support/ModrinthApp/profiles/26.3 Fabric')
INSTANCE = 'local:04b6bf83-98e9-4042-aa05-4637591fbb05'
WORLD = 'oh-shiny-scene'
PACK = 'oh shiny! 1.5.4.zip'
HERE = os.path.dirname(os.path.abspath(__file__))
WORK = os.environ['LAB_WORK']                 # backups, jars and recordings live here, never in the repo
BACKUP, JARS, OUT = (os.path.join(WORK, d) for d in ('profile-backup', 'jars', 'rec'))
STATE = os.path.join(BACKUP, 'state.json')
KEEP = {'iris': ('fabric-api',), 'leadlight': ('fabric-api', 'metallum')}
ADD = {'iris': ('iris-fabric-1.11.7+mc26.3.jar', 'sodium-fabric-0.9.2+mc26.3.jar'),
       'leadlight': ('leadlight-0.2.0+mc26.3.jar', 'sodium-fabric-0.9.2+mc26.3.jar')}

def state():
    return json.load(open(STATE)) if os.path.exists(STATE) else {'disabled': [], 'added': [], 'files': {}}

def save(s): json.dump(s, open(STATE, 'w'), indent=1)

def keep_file(path):
    """Copies a file once, before the first change, so restore can put it back as it was."""
    s = state()
    if path not in s['files']:
        dst = os.path.join(BACKUP, 'files', str(len(s['files'])))
        os.makedirs(os.path.dirname(dst), exist_ok=True)
        if os.path.exists(path): shutil.copy2(path, dst); s['files'][path] = dst
        else: s['files'][path] = None
        save(s)

def write(path, text):
    keep_file(path); os.makedirs(os.path.dirname(path), exist_ok=True); open(path, 'w').write(text)

def restore():
    s = state(); mods = os.path.join(GAME, 'mods')
    for f in s['added']:
        p = os.path.join(mods, f)
        if os.path.exists(p): os.remove(p)
    for f in s['disabled']:
        if os.path.exists(os.path.join(mods, f + '.disabled')): os.rename(os.path.join(mods, f + '.disabled'), os.path.join(mods, f))
    for path, copy in s['files'].items():
        if copy: shutil.copy2(copy, path)
        elif os.path.isdir(path): shutil.rmtree(path)
        elif os.path.exists(path): os.remove(path)
    save({'disabled': [], 'added': [], 'files': {}}); print('restored')

def setup(loader):
    s = state(); mods = os.path.join(GAME, 'mods')
    for f in s['added']:
        if os.path.exists(os.path.join(mods, f)): os.remove(os.path.join(mods, f))
    s['added'] = []
    for f in sorted(os.listdir(mods)):
        if not f.endswith('.jar'): continue
        if f.startswith(KEEP[loader]):
            continue
        os.rename(os.path.join(mods, f), os.path.join(mods, f + '.disabled'))
        if f not in s['disabled']: s['disabled'].append(f)
    for f in s['disabled']:   # a mod the other loader kept and this one needs
        if f.startswith(KEEP[loader]) and os.path.exists(os.path.join(mods, f + '.disabled')):
            os.rename(os.path.join(mods, f + '.disabled'), os.path.join(mods, f))
    for f in ADD[loader]:
        shutil.copy2(os.path.join(JARS, f), os.path.join(mods, f)); s['added'].append(f)
    save(s)
    shutil.copy2(os.path.join(os.path.dirname(os.path.dirname(HERE)), 'dist', PACK), os.path.join(GAME, 'shaderpacks', PACK))
    if PACK not in state()['added']: s = state(); s['added'].append('../shaderpacks/' + PACK); save(s)
    write(os.path.join(GAME, 'config/iris.properties'), f'enableShaders=true\nshaderPack={PACK}\n')
    write(os.path.join(GAME, 'leadlight/pack.txt'), f'pack={PACK}\nenabled=true\n')
    hud()
    print(loader, sorted(f for f in os.listdir(mods) if f.endswith('.jar')))

def hud():
    """A resource pack that blanks the crosshair, so the clips show the world and nothing else."""
    root = os.path.join(GAME, 'resourcepacks/oh-shiny-lab-hud')
    keep_file(root)
    from PIL import Image
    os.makedirs(os.path.join(root, 'assets/minecraft/textures/gui/sprites/hud'), exist_ok=True)
    Image.new('RGBA', (15, 15)).save(os.path.join(root, 'assets/minecraft/textures/gui/sprites/hud/crosshair.png'))
    json.dump({'pack': {'description': 'oh shiny! lab: no crosshair', 'min_format': 1, 'max_format': 999, 'pack_format': 75}},
              open(os.path.join(root, 'pack.mcmeta'), 'w'))

def options(chat):
    lines = open(os.path.join(BACKUP, 'options.txt')).read().splitlines()
    want = {'resourcePacks': '["vanilla","file/oh-shiny-lab-hud"]', 'chatVisibility': '0' if chat else '2',
            'fov': '0.0', 'fullscreen': 'true', 'pauseOnLostFocus': 'false', 'renderDistance': '16', 'hideServerAddress': 'true',
            'onboardAccessibility': 'false', 'showSubtitles': 'false', 'narrator': '0', 'bobView': 'false', 'darkMojangStudiosBackground': 'true'}
    out = [l for l in lines if l.split(':', 1)[0] not in want] + [f'{k}:{v}' for k, v in want.items()]
    write(os.path.join(GAME, 'options.txt'), '\n'.join(out) + '\n')

def world():
    src, dst = os.path.join(GAME, 'saves/test'), os.path.join(GAME, 'saves', WORLD)
    env = dict(os.environ, LAB_SAVES=os.path.join(GAME, 'saves'))
    subprocess.run([sys.executable, os.path.join(HERE, 'make_scene.py'), 'test'], env=env, check=True)

def datapack(events, length):
    """events: {tick: [commands]}. Tick 0 is the first tick a player is in the world."""
    F = os.path.join(GAME, 'saves', WORLD, 'datapacks/scene/data/lab/function')
    shutil.rmtree(os.path.join(F, 'e'), ignore_errors=True); os.makedirs(os.path.join(F, 'e'))
    tick = ['gamemode spectator @a[gamemode=!spectator]', 'scoreboard objectives add lab dummy',
            'execute if entity @a run scoreboard players add #t lab 1']
    events = dict(events); tick += events.pop('tick', [])
    for t in sorted(events):
        open(os.path.join(F, 'e', f'{t}.mcfunction'), 'w').write('\n'.join(events[t]) + '\n')
        tick.append(f'execute if score #t lab matches {t} run function lab:e/{t}')
    tick.append(f'execute if score #t lab matches {length} run say LAB DONE')
    open(os.path.join(F, 'tick.mcfunction'), 'w').write('\n'.join(tick) + '\n')
    # The timer starts again on every launch.
    open(os.path.join(F, 'load.mcfunction'), 'w').write('scoreboard objectives add lab dummy\nscoreboard players set #t lab 0\n')
    tags = os.path.join(GAME, 'saves', WORLD, 'datapacks/scene/data/minecraft/tags/function')
    json.dump({'values': ['lab:load']}, open(os.path.join(tags, 'load.json'), 'w'))

def game_pid():
    r = subprocess.run(['pgrep', '-f', 'ModrinthApp/profiles/26.3 Fabric'], capture_output=True, text=True).stdout.split()
    r = [p for p in r if 'java' in subprocess.run(['ps', '-o', 'comm=', '-p', p], capture_output=True, text=True).stdout]
    return int(r[0]) if r else None

def log_has(text, since):
    p = os.path.join(GAME, 'logs/latest.log')
    return os.path.exists(p) and os.path.getmtime(p) >= since and text in open(p, errors='replace').read()

def launch(settings, events, length, record=None, chat=False, timeout=None):
    timeout = timeout or length / 20 + 150
    assert game_pid() is None, 'the game is already running'
    write(os.path.join(GAME, 'shaderpacks', PACK + '.txt'), ''.join(f'{k}={v}\n' for k, v in settings.items()))
    options(chat); datapack(events, length)
    start = time.time()
    url = f'modrinth://launch/instance/{urllib.parse.quote(INSTANCE, safe="")}?singleplayer_world={urllib.parse.quote(WORLD)}'
    subprocess.run(['open', '-g', url], check=True)
    while not (pid := game_pid()):
        if time.time() - start > 120: raise SystemExit('the game did not start')
        time.sleep(1)
    while not log_has('joined the game', start):
        if time.time() - start > 300 or not game_pid(): raise SystemExit('the world did not load')
        time.sleep(0.5)
    rec = None
    if record:
        os.makedirs(OUT, exist_ok=True)
        rec = subprocess.Popen([os.path.join(GAME, '.rec-util/mcrec'), '--pid', str(pid), '--out', record,
                                '--max-height', '1080', '--fps', '60'], stdin=subprocess.PIPE,
                               stdout=open(record + '.log', 'w'), stderr=subprocess.STDOUT, text=True)
        # mcrec keeps a recording only once it's told a world is open, which rec-util does on world load.
        time.sleep(1); rec.stdin.write('CHAPTER lab\n'); rec.stdin.flush()
        for _ in range(50):
            if 'STARTED' in open(record + '.log').read(): break
            time.sleep(0.1)
        json.dump({'rec_start': time.time() - 1.1}, open(record + '.json', 'w'))
    while not log_has('LAB DONE', start):
        if time.time() - start > timeout or not game_pid(): break
        time.sleep(1)
    if rec:
        rec.send_signal(signal.SIGINT)
        try: rec.wait(30)
        except subprocess.TimeoutExpired: rec.kill()
    os.kill(pid, signal.SIGTERM)
    for _ in range(60):
        if not game_pid(): break
        time.sleep(1)
    if game_pid(): os.kill(pid, signal.SIGKILL)
    if record: shutil.copy2(os.path.join(GAME, 'logs/latest.log'), record + '.game.log')
    time.sleep(2)

def scout():
    q = ['execute as @a at @s run ' + c for c in (
        'locate structure minecraft:village_plains', 'locate biome minecraft:beach', 'locate biome minecraft:ocean',
        'locate biome minecraft:forest', 'locate biome minecraft:birch_forest', 'locate biome minecraft:meadow',
        'locate biome minecraft:windswept_hills', 'locate biome minecraft:cherry_grove', 'locate biome minecraft:river')]
    q.append('execute as @a at @s run tellraw @a ["SPAWN ", {"nbt": "Pos", "entity": "@s"}]')
    launch({}, {40: ['gamerule send_command_feedback true'], 60: q}, 200, chat=True)
    log = open(os.path.join(GAME, 'logs/latest.log'), errors='replace').read().splitlines()
    for l in log:
        if 'nearest' in l or 'SPAWN' in l or 'Could not find' in l: print(l.split('[CHAT]')[-1].strip())

if __name__ == '__main__':
    cmd = sys.argv[1]
    if cmd == 'setup': setup(sys.argv[2])
    elif cmd == 'restore': restore()
    elif cmd == 'world': world()
    elif cmd == 'scout': scout()
    elif cmd == 'run':
        plan = {}; exec(open(sys.argv[2]).read(), plan)
        for name, (settings, events, length) in plan['RUNS'].items():
            if len(sys.argv) > 3 and name not in sys.argv[3:]: continue
            print('run', name, flush=True)
            launch(settings, events, length, record=os.path.join(OUT, name + '.mp4'))
