# Makes one Prism instance per Minecraft version the pack is tested on (oh-shiny-iris-<version>): Fabric, the Iris
# and Sodium versions.py found, the pack from dist/ selected and on, and a copy of the test world. Instances that
# exist are brought up to date (mods, pack), not remade.
#
#   python3 make_instances.py <versions.json> <world folder> [version ...]
import sys, os, json, shutil, glob, urllib.request, hashlib, uuid

PRISM = os.path.expanduser('~/Library/Application Support/PrismLauncher')
PACK = sorted(glob.glob(os.path.join(os.path.dirname(os.path.abspath(__file__)), '../../dist/oh shiny! *.zip')))[-1]
CACHE = os.path.join(PRISM, 'cache', 'oh-shiny-mods')
versions, world = json.load(open(sys.argv[1])), sys.argv[2]
only = sys.argv[3:] or list(versions)

def key(v):
    return [int(x) for x in v.split('.')]

def java(v):
    name = 'java-runtime-gamma' if key(v) <= [1, 20, 4] else 'java-runtime-delta' if key(v) < [26] else 'java-runtime-epsilon'
    return os.path.join(PRISM, 'java', name, 'bin', 'java')

def fetch(m):
    os.makedirs(CACHE, exist_ok=True)
    path = os.path.join(CACHE, m['file'])
    if not os.path.exists(path):
        data = urllib.request.urlopen(urllib.request.Request(m['url'], headers={'User-Agent': 'simply-sunny/oh-shiny'})).read()
        assert hashlib.sha1(data).hexdigest() == m['sha1'], m['file']
        open(path, 'wb').write(data)
    return path

for v in only:
    name = f'oh-shiny-iris-{v}'
    inst = os.path.join(PRISM, 'instances', name)
    mc = os.path.join(inst, 'minecraft')
    os.makedirs(mc, exist_ok=True)
    if not os.path.exists(os.path.join(inst, 'instance.cfg')):
        open(os.path.join(inst, 'instance.cfg'), 'w').write(f'''[General]
ConfigVersion=1.3
InstanceType=OneSix
JavaPath={java(v)}
OverrideJavaLocation=true
MaxMemAlloc=4096
OverrideMemory=true
name={name}
uuid={uuid.uuid4().hex}

[UI]
MinecraftWinHeight=900
MinecraftWinWidth=1600
OverrideWindow=true
''')
        json.dump({'formatVersion': 1, 'components': [
            {'uid': 'net.minecraft', 'version': v, 'important': True},
            {'uid': 'net.fabricmc.intermediary', 'version': v, 'dependencyOnly': True},
            {'uid': 'net.fabricmc.fabric-loader', 'version': '0.20.1'},
        ]}, open(os.path.join(inst, 'mmc-pack.json'), 'w'), indent=4)
        # No onboarding, tutorial or pause when the window loses focus; a modest render distance.
        open(os.path.join(mc, 'options.txt'), 'w').write(
            'onboardAccessibility:false\ntutorialStep:none\npauseOnLostFocus:false\nskipMultiplayerWarning:true\n'
            'renderDistance:12\nsimulationDistance:8\nguiScale:2\njoinedFirstServer:true\nnarrator:0\n')
    mods = os.path.join(mc, 'mods')
    shutil.rmtree(mods, ignore_errors=True)
    os.makedirs(mods)
    for m in versions[v]:
        shutil.copy(fetch(m), mods)
    packs = os.path.join(mc, 'shaderpacks')
    shutil.rmtree(packs, ignore_errors=True)
    os.makedirs(packs)
    shutil.copy(PACK, packs)
    os.makedirs(os.path.join(mc, 'config'), exist_ok=True)
    open(os.path.join(mc, 'config', 'iris.properties'), 'w').write(
        f'enableShaders=true\nshaderPack={os.path.basename(PACK)}\ndisableUpdateMessage=true\n'.replace('!', '\\!'))
    # The world is copied once: the game upgrades it for its own version on first load, and keeps that.
    saves = os.path.join(mc, 'saves', 'oh-shiny-test')
    if not os.path.exists(saves):
        shutil.copytree(world, saves)
    print(name, [m['file'] for m in versions[v]])
