# oh shiny!

A shader pack for Minecraft 26.1 to 26.3, made from the shaders that used to be built into
[Metallum Extra](https://github.com/ohjey/metallum-extra). Runs on Iris with Sodium, and on Apple silicon
through Metallum and [Leadlight](https://github.com/ohjey/leadlight).

## Features

- Shadows from the sun and moon, soft or in whole pixels
- Colored light: torches orange, soul fire blue, sea lanterns teal, amethyst purple
- Light from a torch or lantern held in your hand
- Water that reflects the world, with ripples and caustics
- A sky with a sun glow, sunsets, stars and the Milky Way
- Bloom, sun rays and ambient occlusion
- Leaves, plants and water that move in the wind
- Edge smoothing
- Color grading
- Far-off terrain from [Distant Horizons](https://modrinth.com/mod/distanthorizons) and, on Iris,
  [Voxy](https://modrinth.com/mod/voxy), lit and fogged like the rest

## Install

1. Download the zip from [Releases](https://github.com/simply-sunny/oh-shiny/releases).
2. Put it in your `shaderpacks` folder. Don't unzip it.
3. Select it in **Options → Video Settings → Shader Packs**.

## Settings

Pick a quality preset (Iris calls it Profile): Low, Medium, High or Ultra. Medium is the default.

**Pixel Shadows** makes shadows fall in whole texture pixels, with blocky edges; **Shadow Pixels** sets how
many fit across a block, and **Soft Pixel Edges** smooths their edges. **Shadow Blur** softens ordinary
shadows, which also hides their shimmer as you move. **Fog** lays a haze over the last part of what you can
see (far terrain from Distant Horizons or Voxy included), thickest far off and in the valleys; Off keeps fog
only at the edge.

**Color Grading** has a screen of its own: exposure, contrast, shadows, highlights, saturation, vibrance,
temperature, tint, shadow and highlight color, fade and vignette. All start at Normal.

Shadows cost the most. If the game runs slowly, turn off **Mob Shadows**, lower **Shadow Distance**, or turn
off **Shadows**.

## Building

```bash
python3 tools/build.py    # writes the zip to dist/
python3 tools/check.py    # compiles every stage (needs glslang)
```

Stage files (Distant Horizons' `dh_*` too) come from `tools/stages.py` and `block.properties` from
`tools/blocks.py`. Edit those, not the generated files.

## License

MIT
