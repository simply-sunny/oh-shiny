# Ground heights for camera spots, from a headless server on a copy of the world: the game itself only
# ever teleports to absolute positions, so it never waits on a chunk that isn't loaded yet.
#   python3 heights.py <server dir> <java> x,z [x,z ...]   prints "x z y" per spot
import subprocess, sys, re
d, java, spots = sys.argv[1], sys.argv[2], [tuple(map(int, s.split(','))) for s in sys.argv[3:]]
script = 'sleep 15\n'
for i, (x, z) in enumerate(spots):
    script += (f'echo "forceload add {x} {z}"; sleep 3\n'
               f"echo 'summon marker {x} 0 {z} {{Tags:[\"h{i}\"]}}'; sleep 0.5\n"
               f"echo 'execute as @e[tag=h{i}] at @s positioned over motion_blocking_no_leaves run tp @s ~ ~ ~'; sleep 0.5\n"
               f"echo 'data get entity @e[tag=h{i},limit=1] Pos[1]'; sleep 0.5\n")
script += 'echo stop\n'
out = subprocess.run(f'{{ {script} }} | "{java}" -Xmx3G -jar server.jar nogui', shell=True, cwd=d, capture_output=True, text=True).stdout
ys = re.findall(r'has the following entity data: ([-\d.]+)', out)
for (x, z), y in zip(spots, ys): print(x, z, int(float(y)))
