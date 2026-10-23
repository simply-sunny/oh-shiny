"""Compiles every stage with glslangValidator, the way Iris would see them, with the defaults and with every
option on and off.

For each variant the settings are changed as the shader pack screen would change them, includes are expanded
from the shaders folder as Iris does, the macros Iris defines are added after #version, and each stage is
compiled. Catches GLSL mistakes without starting the game; it does not check how anything looks.

    python3 tools/check.py            (needs glslangValidator: brew install glslang)
"""

import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

PACK = Path(__file__).resolve().parent.parent
# name: settings to change, as (what the line starts with, what it becomes).
VARIANTS = {
    "default": [],
    "everything on": [("//#define SUN_RAYS", "#define SUN_RAYS")],
    "everything off": [
        ("#define SHADOWS", "//#define SHADOWS"), ("#define COLORED_LIGHT", "//#define COLORED_LIGHT"),
        ("#define AMBIENT_OCCLUSION", "//#define AMBIENT_OCCLUSION"), ("#define WATER_REFLECTIONS", "//#define WATER_REFLECTIONS"),
        ("#define WAVING", "//#define WAVING"), ("#define BLOOM", "//#define BLOOM"), ("#define SMOOTH_EDGES", "//#define SMOOTH_EDGES"),
    ],
}

# The macros Iris and Leadlight define that the pack relies on; the values only have to be distinct.
MACROS = """#define IS_IRIS
#define MC_VERSION 260300
#define MC_RENDER_STAGE_SKY 1
#define MC_RENDER_STAGE_SUNSET 2
#define MC_RENDER_STAGE_STARS 6
"""


def expand(root, path):
    lines = []
    for line in path.read_text().split("\n"):
        include = re.match(r'\s*#include\s+"(.+)"', line)
        if include:
            name = include.group(1)
            target = root / name.lstrip("/") if name.startswith("/") else path.parent / name
            lines.append(expand(root, target))
        else:
            lines.append(line)
    return "\n".join(lines)


def check_variant(name, changes, work):
    root = work / name.replace(" ", "_").replace(",", "")
    shutil.copytree(PACK / "shaders", root)
    settings = root / "lib" / "settings.glsl"
    text = settings.read_text()
    for old, new in changes:
        if old not in text:
            sys.exit(f"{name}: settings.glsl has no line starting {old!r}")
        text = text.replace(old, new, 1)
    settings.write_text(text)
    failures = 0
    stages = sorted(root.glob("*.vsh")) + sorted(root.glob("*.fsh"))
    for stage in stages:
        version, rest = expand(root, stage).split("\n", 1)
        kind = "vert" if stage.suffix == ".vsh" else "frag"
        source = root / f"check-{stage.name}.{kind}"
        source.write_text(f"{version}\n{MACROS}{rest}")
        result = subprocess.run(["glslangValidator", "-S", kind, str(source)], capture_output=True, text=True)
        if result.returncode != 0:
            failures += 1
            print(f"{name}: {stage.name} failed\n{result.stdout}")
    print(f"{name}: {len(stages) - failures} of {len(stages)} stages compile")
    return failures


def main():
    if shutil.which("glslangValidator") is None:
        sys.exit("glslangValidator not found (brew install glslang, or apt install glslang-tools)")
    with tempfile.TemporaryDirectory() as work:
        failures = sum(check_variant(name, changes, Path(work)) for name, changes in VARIANTS.items())
    sys.exit(1 if failures else 0)


if __name__ == "__main__":
    main()
