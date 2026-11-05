# Fetches Mojang's Java runtimes for macOS arm64 into Prism's java folder, as Prism lays them out
# (java/<component>/bin/java): gamma is Java 17 (Minecraft 1.20.1-1.20.4), delta Java 21 (1.20.5-1.21.11).
#
#   python3 get_java.py java-runtime-gamma java-runtime-delta
import sys, os, json, urllib.request, hashlib

ROOT = os.path.expanduser('~/Library/Application Support/PrismLauncher/java')
ALL = 'https://piston-meta.mojang.com/v1/products/java-runtime/2ec0cc96c44e5a76b9c8b7c39df7210883d12871/all.json'
get = lambda url: urllib.request.urlopen(url).read()

runtimes = json.loads(get(ALL))['mac-os-arm64']
for name in sys.argv[1:]:
    files = json.loads(get(runtimes[name][0]['manifest']['url']))['files']
    dst = os.path.join(ROOT, name)
    # Mojang's tree is jre.bundle/Contents/Home/...; Prism's runtimes keep only Home.
    prefix = 'jre.bundle/Contents/Home/'
    for path, f in files.items():
        if not path.startswith(prefix):
            continue
        out = os.path.join(dst, path[len(prefix):])
        if f['type'] == 'directory':
            os.makedirs(out, exist_ok=True)
        elif f['type'] == 'file':
            os.makedirs(os.path.dirname(out), exist_ok=True)
            data = get(f['downloads']['raw']['url'])
            assert hashlib.sha1(data).hexdigest() == f['downloads']['raw']['sha1'], path
            open(out, 'wb').write(data)
            if f.get('executable'):
                os.chmod(out, 0o755)
    for path, f in files.items():
        if f['type'] == 'link' and path.startswith(prefix):
            out = os.path.join(dst, path[len(prefix):])
            if not os.path.lexists(out):
                os.symlink(f['target'], out)
    print(name, '->', dst)
