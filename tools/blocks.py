"""Writes shaders/block.properties: which kind of block each is, as far as the shaders care; and
shaders/item.properties, which gives light-giving items held in the hand the ids of their blocks.

The ids must agree with shaders/lib/block_ids.glsl: blocks 10000 + their kind, blocks that give off light
10100 + the color of their light (the palette in shaders/lib/light_colors.glsl). Edit the lists below and run
this again rather than editing block.properties by hand.

    python3 tools/blocks.py
"""

from pathlib import Path

SHADERS = Path(__file__).resolve().parent.parent / "shaders"

COLORS = "white orange magenta light_blue yellow lime pink gray light_gray cyan purple blue brown green red black".split()
COPPER_AGES = [waxed + age for waxed in ["", "waxed_"] for age in ["", "exposed_", "weathered_", "oxidized_"]]
STONES = ["andesite", "diorite", "granite", "blackstone", "deepslate", "basalt", "tuff"]
TALL_PLANTS = "tall_grass large_fern sunflower lilac rose_bush peony pitcher_plant".split()

LEAVES = ("%leaves vine weeping_vines weeping_vines_plant twisting_vines twisting_vines_plant "
          "cave_vines:berries=false cave_vines_plant:berries=false").split()

PLANTS = ("%small_flowers %saplings %crops short_grass grass fern dead_bush bush firefly_bush short_dry_grass "
          "tall_dry_grass sweet_berry_bush nether_wart brown_mushroom red_mushroom crimson_fungus "
          "warped_fungus crimson_roots warped_roots nether_sprouts hanging_roots seagrass cactus_flower torchflower_crop pitcher_crop melon_stem pumpkin_stem "
          "attached_melon_stem attached_pumpkin_stem wheat carrots potatoes beetroots").split()

# Two-block plants: the lower half sways at its top as far as the upper half does at its bottom, so the two stay
# joined. (Sugar cane and dripleaf stems, stacked from whole blocks, stay still: each block would sway alone.)
PLANTS_LOWER = [f"{plant}:half=lower" for plant in TALL_PLANTS] + ["tall_seagrass:half=lower", "small_dripleaf:half=lower"]

PLANTS_UPPER = [f"{plant}:half=upper" for plant in TALL_PLANTS] + ["tall_seagrass:half=upper", "small_dripleaf:half=upper"]


def shiny():
    blocks = ["ice", "packed_ice", "blue_ice", "frosted_ice", "glass", "glass_pane", "tinted_glass", "obsidian",
              "amethyst_block", "budding_amethyst", "calcite"]
    blocks += [f"{color}_stained_glass" for color in COLORS] + [f"{color}_stained_glass_pane" for color in COLORS]
    blocks += [f"{color}_glazed_terracotta" for color in COLORS]
    for stone in STONES:
        blocks.append(f"polished_{stone}")
        if stone != "basalt":
            blocks += [f"polished_{stone}_slab", f"polished_{stone}_stairs", f"polished_{stone}_wall"]
    blocks += ["polished_blackstone_bricks", "polished_blackstone_brick_slab", "polished_blackstone_brick_stairs",
               "polished_blackstone_brick_wall", "polished_blackstone_pressure_plate", "polished_blackstone_button"]
    blocks += ["smooth_stone", "smooth_stone_slab", "smooth_sandstone", "smooth_sandstone_slab", "smooth_sandstone_stairs",
               "smooth_red_sandstone", "smooth_red_sandstone_slab", "smooth_red_sandstone_stairs", "smooth_quartz",
               "smooth_quartz_slab", "smooth_quartz_stairs", "smooth_basalt"]
    blocks += ["quartz_block", "quartz_bricks", "quartz_pillar", "chiseled_quartz_block", "quartz_slab", "quartz_stairs",
               "prismarine", "prismarine_bricks", "dark_prismarine", "prismarine_slab", "prismarine_stairs",
               "prismarine_wall", "prismarine_brick_slab", "prismarine_brick_stairs", "dark_prismarine_slab",
               "dark_prismarine_stairs", "deepslate_tiles", "deepslate_tile_slab", "deepslate_tile_stairs",
               "deepslate_tile_wall", "cracked_deepslate_tiles"]
    return blocks


def metal():
    blocks = ["iron_block", "gold_block", "netherite_block", "diamond_block", "emerald_block", "lapis_block",
              "raw_iron_block", "raw_gold_block", "raw_copper_block", "anvil", "chipped_anvil", "damaged_anvil",
              "chain", "iron_chain", "iron_bars", "iron_door", "iron_trapdoor", "cauldron", "water_cauldron",
              "powder_snow_cauldron", "rail", "powered_rail", "detector_rail", "activator_rail", "heavy_core",
              "hopper", "lightning_rod"]
    for age in COPPER_AGES:
        plain = f"{age}copper_block" if age in ("", "waxed_") else f"{age}copper"
        blocks += [plain, f"{age}cut_copper", f"{age}cut_copper_slab", f"{age}cut_copper_stairs",
                   f"{age}chiseled_copper", f"{age}copper_grate", f"{age}copper_bars", f"{age}copper_chain",
                   f"{age}copper_door", f"{age}copper_trapdoor"]
    return blocks


# Light-giving things held in the hand that are not blocks, by the color of their light.
HELD_LIGHTS = {1: ["lava_bucket"]}

# 10100 + the place of their light's color in mx_light_palette (light_colors.glsl).
LIGHTS = {
    0: ("Torches, lanterns, glowstone: warm",
        ["torch", "wall_torch", "lantern", "glowstone", "shroomlight", "jack_o_lantern", "glow_lichen",
         "candle:lit=true", "sea_pickle", "light",
         "brewing_stand", "creaking_heart:creaking_heart_state=awake", "trial_spawner", "vault"]
        + [f"{color}_candle:lit=true" for color in COLORS] + [f"{age}copper_bulb:lit=true" for age in COPPER_AGES]),
    1: ("Fire, furnaces, magma: orange",
        ["fire", "campfire:lit=true", "magma_block", "furnace:lit=true", "blast_furnace:lit=true", "smoker:lit=true",
         "lava_cauldron"]),
    2: ("Soul fire: blue", ["soul_torch", "soul_wall_torch", "soul_lantern", "soul_campfire:lit=true", "soul_fire"]),
    3: ("Sea lanterns, conduits: teal", ["sea_lantern", "conduit"]),
    4: ("Amethyst: purple", ["amethyst_cluster", "large_amethyst_bud", "medium_amethyst_bud"]),
    5: ("End rods, beacons, froglights: white",
        ["end_rod", "beacon", "ochre_froglight", "verdant_froglight", "pearlescent_froglight", "dragon_egg"]),
    6: ("Redstone: red",
        ["redstone_torch:lit=true", "redstone_wall_torch:lit=true", "redstone_lamp:lit=true", "redstone_ore:lit=true",
         "deepslate_redstone_ore:lit=true"]),
    7: ("Portals, crying obsidian, sculk: violet",
        ["nether_portal", "end_portal", "end_gateway", "crying_obsidian", "respawn_anchor", "enchanting_table",
         "sculk_catalyst"]),
    8: ("Copper torches and lanterns: green",
        ["copper_torch", "copper_wall_torch"] + [f"{age}copper_lantern" for age in COPPER_AGES]),
}

# 10120 + the place of their light's color: blocks of which only a part gives off light.
GLOW_BERRIES = {0: ("Glow berries: only the berries glow; the vines sway like leaves",
                    ["cave_vines:berries=true", "cave_vines_plant:berries=true"])}


def wrap(blocks):
    lines, line = [], ""
    for block in blocks:
        if len(line) + len(block) + 1 > 110:
            lines.append(line.rstrip())
            line = ""
        line += block + " "
    lines.append(line.rstrip())
    return " \\\n    ".join(lines)


def main():
    text = f"""# oh shiny! block ids. Written by tools/blocks.py; edit that and run it again. Must agree with lib/block_ids.glsl:
# 10000 + the kind of block, 10100 and up for blocks that give off light, 10120 and up for glow berries. Names
# that a Minecraft version does not have are skipped by Iris.

# Water and lava.
block.10001=water
block.10002=lava

# Leaves and vines: sway a little.
block.10003={wrap(LEAVES)}

# Plants rooted in the ground: their tops sway.
block.10004={wrap(PLANTS)}

# The upper half of two-block plants: all of it sways.
block.10005={wrap(PLANTS_UPPER)}

# The lower half of two-block plants: its top sways, as far as the upper half's bottom.
block.10010={wrap(PLANTS_LOWER)}

# Smooth and polished things: catch the sun.
block.10006={wrap(shiny())}

# Metal: catches the sun in its own color.
block.10007={wrap(metal())}

# Blocks that give off light: they glow, and color the light around them. 10100 + the color of their light
# (lib/light_colors.glsl).
"""
    for index, (comment, blocks) in LIGHTS.items():
        text += f"\n# {comment}\nblock.{10100 + index}={wrap(blocks)}\n"
    for index, (comment, blocks) in GLOW_BERRIES.items():
        text += f"\n# {comment}\nblock.{10120 + index}={wrap(blocks)}\n"
    (SHADERS / "block.properties").write_text(text)

    # Items share their blocks' names, without the block's state; wall torches and the like are no items, and
    # Iris skips names it does not know.
    items = """# oh shiny! item ids. Written by tools/blocks.py; edit that and run it again. A light held in the hand
# (lib/lighting.glsl) has the id of its block in block.properties, 10100 + the color of its light.
"""
    for index, (comment, blocks) in LIGHTS.items():
        names = list(dict.fromkeys(block.split(":")[0] for block in blocks if "wall_" not in block))
        names += HELD_LIGHTS.get(index, [])
        items += f"\n# {comment}\nitem.{10100 + index}={wrap(names)}\n"
    (SHADERS / "item.properties").write_text(items)
    print("wrote block.properties and item.properties")


if __name__ == "__main__":
    main()
