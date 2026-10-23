"""Writes the stage files in shaders/: the programs Iris and Leadlight look for by name.

Each stage file only says what it is: the program it includes from shaders/program/, the defines that program
is built with, and which images it draws into. Edit the table below and run this again rather than editing the
stage files by hand.

    python3 tools/stages.py
"""

from pathlib import Path

SHADERS = Path(__file__).resolve().parent.parent / "shaders"

# name: (vertex program, fragment program, defines, images drawn into, extra fragment lines)
STAGES = {
    "shadow": ("shadow.vsh", "shadow.fsh", [], "0", []),

    "prepare": ("fullscreen.vsh", "prepare.fsh", [], "0", []),

    "gbuffers_basic": ("plain.vsh", "plain.fsh", ["MX_GAME_FOG"], "0", []),
    "gbuffers_textured": ("plain.vsh", "plain.fsh", ["MX_TEXTURED", "MX_LIGHTMAP", "MX_GAME_FOG"], "0", []),
    "gbuffers_skybasic": ("plain.vsh", "sky_basic.fsh", [], "0", []),
    "gbuffers_skytextured": ("plain.vsh", "plain.fsh", ["MX_TEXTURED"], "0", []),
    "gbuffers_clouds": ("clouds.vsh", "clouds.fsh", [], "0", []),
    "gbuffers_terrain": ("terrain.vsh", "terrain.fsh", [], "0", []),
    "gbuffers_damagedblock": ("plain.vsh", "plain.fsh", ["MX_TEXTURED"], "0", []),
    "gbuffers_textured_lit": ("model.vsh", "model.fsh", [], "0", []),
    "gbuffers_entities": ("model.vsh", "model.fsh", ["MX_ENTITY"], "0", []),
    "gbuffers_block": ("model.vsh", "model.fsh", [], "0", []),
    "gbuffers_spidereyes": ("model.vsh", "model.fsh", ["MX_EMISSIVE"], "0", []),
    "gbuffers_particles": ("model.vsh", "model.fsh", ["MX_PARTICLE"], "0", []),
    "gbuffers_beaconbeam": ("plain.vsh", "plain.fsh", ["MX_TEXTURED"], "0", []),
    "gbuffers_armor_glint": ("plain.vsh", "plain.fsh", ["MX_TEXTURED"], "0", []),
    "gbuffers_hand": ("model.vsh", "model.fsh", ["MX_HAND"], "0", []),

    # Between solid things and water: a copy of the picture for water to reflect.
    "deferred": ("fullscreen.vsh", "deferred.fsh", [], "5", []),
    "gbuffers_water": ("terrain.vsh", "terrain.fsh", ["MX_TRANSLUCENT"], "0", []),
    "gbuffers_weather": ("plain.vsh", "plain.fsh", ["MX_TEXTURED", "MX_LIGHTMAP"], "0", []),

    # The composite passes are listed in order below (COMPOSITES) and numbered from there.
    "final": ("fullscreen.vsh", "final.fsh", [], None, []),
}


# The passes over the finished picture, in the order they run: (fragment program, images drawn into, extra lines).
COMPOSITES = [
    # Sun rays and ambient occlusion: worked out, blurred, laid over the picture.
    ("effects.fsh", "6,15", []),
    ("effects_blur.fsh", "7", []),
    ("effects_apply.fsh", "0", []),
    # The glow: the picture at half size, four steps down, four steps back up, then a layer over the picture.
    ("bloom_prefilter.fsh", "10", []),
    *[("bloom_downsample.fsh", str(11 + step),
       [f"uniform sampler2D colortex{10 + step};", f"#define MX_BLOOM_IN colortex{10 + step}"]) for step in range(4)],
    *[("bloom_upsample.fsh", str(13 - step),
       [f"uniform sampler2D colortex{14 - step};", f"uniform sampler2D colortex{13 - step};",
        f"#define MX_BLOOM_IN colortex{14 - step}", f"#define MX_BLOOM_OUT colortex{13 - step}"]) for step in range(4)],
    ("bloom_composite.fsh", "0", []),
]
STAGES.update({
    ("composite" if index == 0 else f"composite{index}"): ("fullscreen.vsh", program, [], targets, extra)
    for index, (program, targets, extra) in enumerate(COMPOSITES)
})


def stage_file(program, defines, targets, extra):
    lines = ["#version 330 compatibility", "", '#include "/lib/settings.glsl"']
    lines += [f"#define {define}" for define in defines]
    if targets is not None:
        lines.append(f"/* RENDERTARGETS: {targets} */")
    lines += extra
    lines += [f'#include "/program/{program}"', ""]
    return "\n".join(lines)


def main():
    for old in list(SHADERS.glob("*.vsh")) + list(SHADERS.glob("*.fsh")):
        old.unlink()
    for name, (vertex, fragment, defines, targets, extra) in STAGES.items():
        (SHADERS / f"{name}.vsh").write_text(stage_file(vertex, defines, None, []))
        (SHADERS / f"{name}.fsh").write_text(stage_file(fragment, defines, targets, extra))
    print(f"wrote {len(STAGES)} stages")


if __name__ == "__main__":
    main()
