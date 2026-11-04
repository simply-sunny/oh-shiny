# For each Minecraft version the pack is tested on: the newest Iris for it on Modrinth, and the Sodium that Iris
# version asks for (its own pin, or the newest Sodium for that Minecraft version), and Distant Horizons. Prints
# JSON for make_instances.py.
#
#   python3 versions.py > versions.json
import json, sys, urllib.request, urllib.parse

GAMES = ['1.20.1', '1.20.2', '1.20.4', '1.20.6', '1.21.1', '1.21.3', '1.21.4', '1.21.5', '1.21.8', '1.21.10',
         '1.21.11', '26.1.2', '26.2', '26.3']
API = 'https://api.modrinth.com/v2'
UA = {'User-Agent': 'simply-sunny/oh-shiny version-test'}

def get(path, **q):
    url = API + path + ('?' + urllib.parse.urlencode({k: json.dumps(v) for k, v in q.items()}) if q else '')
    return json.load(urllib.request.urlopen(urllib.request.Request(url, headers=UA)))

def newest(project, game):
    vs = get(f'/project/{project}/version', loaders=['fabric'], game_versions=[game])
    vs = [v for v in vs if v['version_type'] == 'release'] or vs
    return max(vs, key=lambda v: v['date_published']) if vs else None

def jar(v):
    f = next((f for f in v['files'] if f['primary']), v['files'][0])
    return {'version': v['version_number'], 'url': f['url'], 'file': f['filename'], 'sha1': f['hashes']['sha1']}

out = {}
for g in GAMES:
    iris = newest('iris', g)
    if not iris:
        print('no Iris for', g, file=sys.stderr); continue
    pin = next((d for d in iris['dependencies'] if d['project_id'] == 'AANobbMI' and d.get('version_id')), None)
    sodium = get(f'/version/{pin["version_id"]}') if pin else newest('sodium', g)
    mods = [jar(iris), jar(sodium)]
    # Anything else either of them requires (Fabric API, for some Sodium versions).
    for v in (iris, sodium):
        for d in v['dependencies']:
            if d['dependency_type'] == 'required' and d['project_id'] not in ('AANobbMI', 'YL57xq9U') and d.get('project_id'):
                dep = get(f'/version/{d["version_id"]}') if d.get('version_id') else newest(d['project_id'], g)
                if dep and jar(dep)['file'] not in [m['file'] for m in mods]:
                    mods.append(jar(dep))
    # Distant Horizons, which Iris draws through the pack's dh_ programs from Iris 1.7 on.
    dh = newest('distanthorizons', g) if not iris['version_number'].startswith('1.6') else None
    if dh:
        mods.append(jar(dh))
        # With Sodium 0.5 (Minecraft 1.20.x), Distant Horizons needs Indium for the Fabric rendering API, and
        # Indium needs Fabric API. Later Sodium has the API itself.
        if '0.5.' in sodium['version_number']:
            for extra in ('indium', 'fabric-api'):
                vs = get(f'/project/{extra}/version', loaders=['fabric'], game_versions=[g])
                # The build made for this version, when there is one: Indium tags later builds with older versions.
                own = [v for v in vs if g in v['version_number']] or vs
                mods.append(jar(max(own, key=lambda v: v['date_published'])))
    out[g] = mods
    print(g, [m['file'] for m in mods], file=sys.stderr)
print(json.dumps(out, indent=1))
