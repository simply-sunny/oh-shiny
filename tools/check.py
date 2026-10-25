"""Compiles every stage with glslangValidator, the way Iris would see them: with the defaults and every option on and
off, with Distant Horizons running, and Voxy's patch inside a stand-in for Voxy's own shader.

For each variant the settings are changed as the shader pack screen would change them, includes are expanded
from the shaders folder as Iris does, the macros Iris defines are added after #version, and each stage is
compiled. Catches GLSL mistakes without starting the game; it does not check how anything looks.

    python3 tools/check.py            (needs glslangValidator: brew install glslang)
"""

import json
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

PACK = Path(__file__).resolve().parent.parent
PIXEL_SHADOWS = ("//#define PIXEL_SHADOWS", "#define PIXEL_SHADOWS")
# name: settings to change, as (what the line starts with, what it becomes).
VARIANTS = {
    "default": [],
    "pixel shadows": [PIXEL_SHADOWS, ("#define PIXEL_SHADOWS_SIZE 16", "#define PIXEL_SHADOWS_SIZE 8"),
                      ("//#define PIXEL_SHADOWS_SOFT", "#define PIXEL_SHADOWS_SOFT")],
    "soft shadows": [("#define SHADOW_SOFTNESS 1", "#define SHADOW_SOFTNESS 3"), ("//#define SUN_RAYS", "#define SUN_RAYS"),
                     ("#define SUN_RAYS_STRENGTH 3", "#define SUN_RAYS_STRENGTH 1")],
    "everything on": [("//#define SUN_RAYS", "#define SUN_RAYS"), PIXEL_SHADOWS, ("#define FOG_AMOUNT 0", "#define FOG_AMOUNT 50")],
    "everything off": [
        ("#define SHADOWS", "//#define SHADOWS"), ("#define COLORED_LIGHT", "//#define COLORED_LIGHT"),
        ("#define HAND_LIGHT", "//#define HAND_LIGHT"),
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
# What Iris adds with Distant Horizons running: the define everywhere, and in its programs the block kinds and
# the attribute that holds them.
DH_MACROS = "#define DISTANT_HORIZONS\n"
DH_PROGRAM = """#define DH_BLOCK_UNKNOWN 0
#define DH_BLOCK_LEAVES 1
#define DH_BLOCK_STONE 2
#define DH_BLOCK_WOOD 3
#define DH_BLOCK_METAL 4
#define DH_BLOCK_DIRT 5
#define DH_BLOCK_LAVA 6
#define DH_BLOCK_DEEPSLATE 7
#define DH_BLOCK_SNOW 8
#define DH_BLOCK_SAND 9
#define DH_BLOCK_TERRACOTTA 10
#define DH_BLOCK_NETHER_STONE 11
#define DH_BLOCK_WATER 12
#define DH_BLOCK_GRASS 13
#define DH_BLOCK_AIR 14
#define DH_BLOCK_ILLUMINATED 15
"""
# What Voxy wraps its patch in (its lod/gl46/quads.frag): the parameters it hands voxy_emitFragment, and the
# uniforms voxy.json lists, declared by Voxy.
VOXY_HEAD = """#version 460 core
struct VoxyFragmentParameters {
    vec4 sampledColour;
    vec2 tile;
    vec2 uv;
    uint face;
    uint modelId;
    vec2 lightMap;
    vec4 tinting;
    uint customId;
};
void voxy_emitFragment(VoxyFragmentParameters parameters);
"""
VOXY_UNIFORM_TYPES = {"vxProjInv": "mat4", "vxModelViewInv": "mat4", "vxRenderDistance": "int"}


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


def compile_source(source, kind):
    result = subprocess.run(["glslangValidator", "-S", kind, str(source)], capture_output=True, text=True)
    return result.returncode == 0, result.stdout


def copy_with(changes, root, label):
    shutil.copytree(PACK / "shaders", root)
    settings = root / "lib" / "settings.glsl"
    text = settings.read_text()
    for old, new in changes:
        if old not in text:
            sys.exit(f"{label}: settings.glsl has no line starting {old!r}")
        text = text.replace(old, new, 1)
    settings.write_text(text)


def check_variant(name, changes, work, lod):
    root = work / (name.replace(" ", "_").replace(",", "") + "_" + lod)
    copy_with(changes, root, name)
    failures = 0
    stages = sorted(root.glob("*.vsh")) + sorted(root.glob("*.fsh"))
    if lod != "dh":
        stages = [stage for stage in stages if not stage.name.startswith("dh_")]
    for stage in stages:
        version, rest = expand(root, stage).split("\n", 1)
        kind = "vert" if stage.suffix == ".vsh" else "frag"
        macros = MACROS
        if lod == "dh":
            macros += DH_MACROS
            if stage.name.startswith("dh_"):
                macros += DH_PROGRAM + ("in int dhMaterialId;\n" if kind == "vert" else "")
        if lod == "voxy":
            macros += "#define VOXY\n"
        source = root / f"check-{stage.name}.{kind}"
        source.write_text(f"{version}\n{macros}{rest}")
        ok, output = compile_source(source, kind)
        if not ok:
            failures += 1
            print(f"{name} ({lod}): {stage.name} failed\n{output}")
    if lod == "voxy":
        failures += check_voxy(name, root)
    print(f"{name} ({lod}): {len(stages) - failures} of {len(stages)} stages compile")
    return failures


def check_voxy(name, root):
    uniforms = json.loads((root / "voxy.json").read_text())["uniforms"]
    types = {uniform: kind for kind, uniform in re.findall(r"uniform (\w+) (\w+);", (root / "lib" / "uniforms.glsl").read_text())}
    types.update(VOXY_UNIFORM_TYPES)
    missing = [uniform for uniform in types if uniform not in uniforms]
    if missing:
        print(f"{name} (voxy): voxy.json does not list {missing}")
        return 1
    declarations = "".join(f"uniform {types[uniform]} {uniform};\n" for uniform in uniforms)
    failures = 0
    for patch in ["voxy_opaque.glsl", "voxy_translucent.glsl"]:
        source = root / f"check-{patch}.frag"
        source.write_text(VOXY_HEAD + declarations + expand(root, root / patch) + "\nvoid main() {}\n")
        ok, output = compile_source(source, "frag")
        if not ok:
            failures += 1
            print(f"{name} (voxy): {patch} failed\n{output}")
    return failures


def main():
    if shutil.which("glslangValidator") is None:
        sys.exit("glslangValidator not found (brew install glslang, or apt install glslang-tools)")
    with tempfile.TemporaryDirectory() as work:
        work = Path(work)
        failures = 0
        for name, changes in VARIANTS.items():
            for lod in ["none", "dh", "voxy"]:
                failures += check_variant(name, changes, work, lod)
    sys.exit(1 if failures else 0)


if __name__ == "__main__":
    main()
