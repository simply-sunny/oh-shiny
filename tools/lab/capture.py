# Runs shots in the oh-shiny lab: for each, sets time and camera, writes the pack settings for each variant,
# reloads the pack (F10) when they change, and captures the screen.
import subprocess, sys, time, os
T = os.path.dirname(os.path.abspath(__file__))
OUT = os.environ.get('LAB_OUT', os.path.join(os.path.dirname(T), 'cap'))
CFG = os.path.expanduser('~/Library/Application Support/PrismLauncher/instances/26.3/minecraft/shaderpacks/oh shiny! 1.5.3.zip.txt')
HEAD = ("# Written by Leadlight's settings screen and by Iris, one NAME=value per line.\n"
        "# Only what differs from the pack's own defaults.\n"
        "# leadlight/options.txt is a different file, it is never written here, and it wins.\n")
mc = lambda *a: subprocess.run([os.path.join(T, 'mc.sh'), *a], check=True, capture_output=True)
current = None

def settings(s):
    global current
    if s == current: return
    open(CFG, 'w').write(HEAD + ''.join(f'{k}={v}\n' for k, v in s.items()))
    mc('key', '109')  # F10: Reload Shaders
    time.sleep(7)
    current = s

def shot(name, t, pos, rot, variants, settle=3):
    mc('cmd', f'time set {t}')
    mc('cmd', f'tp @s {pos[0]} {pos[1]} {pos[2]} {rot[0]} {rot[1]}')
    for vname, s in variants.items():
        settings(s)
        # Again after the reload: the camera can drift while the pack reloads.
        mc('cmd', f'tp @s {pos[0]} {pos[1]} {pos[2]} {rot[0]} {rot[1]}')
        mc('shot', os.path.join(OUT, f'{name}__{vname}.png'), str(settle))
        print(name, vname, flush=True)

if __name__ == '__main__':
    exec(open(sys.argv[1]).read())
