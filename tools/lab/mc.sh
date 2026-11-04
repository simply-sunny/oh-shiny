#!/bin/zsh
# Drives the game for captures. mc.sh cmd "<command without slash>" | mc.sh key <keycode> | mc.sh shot <out.png> [settle]
set -e
front() { osascript -e 'tell application "System Events" to tell process "java" to set frontmost to true'; sleep 0.4; }
case $1 in
  cmd)
    front
    sleep 0.6
    osascript -e 'tell application "System Events" to key code 44'; sleep 0.9
    osascript -e "tell application \"System Events\" to keystroke \"$2\""; sleep 0.2
    osascript -e 'tell application "System Events" to key code 36' ;;
  key)
    front; osascript -e "tell application \"System Events\" to key code $2" ;;
  shot)
    front; sleep ${3:-2.5}
    screencapture -x "$2.raw.png"
    # The game below the notch's black band, cropped to 16:10 of the panel.
    python3 -c "
from PIL import Image; import sys
im = Image.open(sys.argv[1]).convert('RGB'); w, h = im.size
top = 0
while top < 200 and max(im.getpixel((x, top))[0] for x in range(0, w, 97)) < 3: top += 1
im.crop((0, top, w, h)).save(sys.argv[2])" "$2.raw.png" "$2"
    rm "$2.raw.png"; echo "$2" ;;
esac
