# Turns plan_wiki.py's captures into the wiki's frames: 1600 px wide WebP in wiki/public/assets/osh/frames.
#
#   python3 to_wiki.py <capture dir>
import sys, os, glob
from PIL import Image

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '../../wiki/public/assets/osh/frames')
os.makedirs(OUT, exist_ok=True)
for p in sorted(glob.glob(os.path.join(sys.argv[1], '*__*.png'))):
    im = Image.open(p).convert('RGB')
    im = im.resize((1600, round(im.height * 1600 / im.width)), Image.LANCZOS)
    dst = os.path.join(OUT, os.path.basename(p)[:-4] + '.webp')
    im.save(dst, 'WEBP', quality=80, method=6)
    print(os.path.basename(dst), im.size, os.path.getsize(dst) // 1024, 'KB')
