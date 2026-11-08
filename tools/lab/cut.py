# Cuts the wiki's clips out of record.py's recordings. Each shot is found by its "LAB SHOT <name>" line in
# the run's game log, and a clip that steps through a setting joins the same shot from several runs, in the
# order the wiki's captions name them.
#
#   python3 cut.py <recordings dir> <wiki clips dir>
import datetime, json, os, re, subprocess, sys
from PIL import Image

REC, DST = sys.argv[1], sys.argv[2]
plan = {}; exec(open(os.path.join(os.path.dirname(os.path.abspath(__file__)), 'plans/clips.py')).read(), plan)
SETTLE, SHOTS = plan['SETTLE'], plan['SHOTS']
CLIPS = {  # clip: [(run, shot)], played one after another
    'tour': [('base', 'tour')], 'shadows': [('base', 'shadows')], 'water': [('base', 'water')],
    'sky': [('base', 'sky')], 'waving': [('base', 'waving')],
    'presets': [('low', 'presets'), ('base', 'presets'), ('high', 'presets'), ('ultra', 'presets')],
    'pixel': [('base', 'pixel'), ('pixel1', 'pixel'), ('pixel2', 'pixel')],
    'light': [('base', 'light'), ('light0', 'light')],
    'rays': [('base', 'rays'), ('rays1', 'rays'), ('rays2', 'rays'), ('rays3', 'rays')],
    'fog': [('base', 'fog'), ('fog30', 'fog'), ('fog60', 'fog'), ('fog90', 'fog')],
    'sunset': [('base', 'sunset'), ('pixel1', 'sunset'), ('pixel2', 'sunset'), ('light0', 'sunset'), ('sunset4', 'sunset'), ('sunset5', 'sunset')],
}

def marks(run):
    start = json.load(open(os.path.join(REC, run + '.mp4.json')))['rec_start']
    day = datetime.datetime.fromtimestamp(start).date()
    out = {}
    for line in open(os.path.join(REC, run + '.mp4.game.log'), errors='replace'):
        m = re.match(r'\[(\d\d):(\d\d):(\d\d)\] \[Server thread/INFO\]: .*LAB SHOT (\w+)', line)
        if m:
            t = datetime.datetime.combine(day, datetime.time(*map(int, m.groups()[:3]))).timestamp()
            out[m.group(4)] = t + 0.5 - start   # the log has whole seconds: the shot began within that second
    return out

def cut(run, shot, out):
    at = marks(run)[shot] + SETTLE + 0.3
    secs = SHOTS[shot][2]
    subprocess.run(['ffmpeg', '-loglevel', 'error', '-y', '-ss', f'{at:.2f}', '-t', str(secs), '-i', os.path.join(REC, run + '.mp4'),
                    '-an', '-vf', 'crop=iw:iw*9/16,scale=1280:720:flags=lanczos,fps=30,format=yuv420p',
                    '-c:v', 'libx264', '-preset', 'slow', '-crf', '18', out], check=True)

os.makedirs(DST, exist_ok=True)
tmp = os.path.join(REC, 'parts'); os.makedirs(tmp, exist_ok=True)
for clip, parts in CLIPS.items():
    files = []
    for i, (run, shot) in enumerate(parts):
        if not os.path.exists(os.path.join(REC, run + '.mp4')): print('missing', run); break
        f = os.path.join(tmp, f'{clip}-{i}.mp4'); cut(run, shot, f); files.append(f)
    else:
        lst = os.path.join(tmp, clip + '.txt'); open(lst, 'w').write(''.join(f"file '{f}'\n" for f in files))
        out = os.path.join(DST, clip + '.mp4')
        subprocess.run(['ffmpeg', '-loglevel', 'error', '-y', '-f', 'concat', '-safe', '0', '-i', lst, '-an',
                        '-c:v', 'libx264', '-preset', 'slow', '-crf', '27', '-profile:v', 'high', '-pix_fmt', 'yuv420p',
                        '-movflags', '+faststart', out], check=True)
        png = os.path.join(tmp, clip + '.png')
        subprocess.run(['ffmpeg', '-loglevel', 'error', '-y', '-ss', '0.5', '-i', out, '-frames:v', '1', png], check=True)
        Image.open(png).save(os.path.join(DST, clip + '.webp'), quality=80)
        print(clip, os.path.getsize(out) // 1024, 'KB', flush=True)
