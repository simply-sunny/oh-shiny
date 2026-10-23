# oh shiny!

A shader pack for Minecraft 26.1 to 26.3, made from the shaders that used to be built into
[Metallum Extra](https://github.com/ohjey/metallum-extra). Runs on Iris with Sodium, and on Apple silicon
through Metallum and [Leadlight](https://github.com/ohjey/leadlight).

## Features

- Shadows from the sun and moon
- Colored light: torches orange, soul fire blue, sea lanterns teal, amethyst purple
- Water that reflects the world, with ripples and caustics
- A sky with a sun glow, sunsets, stars and the Milky Way
- Bloom, sun rays and ambient occlusion
- Leaves, plants and water that move in the wind
- Edge smoothing

## Install

1. Download the zip from [Releases](https://github.com/simply-sunny/oh-shiny/releases).
2. Put it in your `shaderpacks` folder. Don't unzip it.
3. Select it in **Options → Video Settings → Shader Packs**.

## Settings

Pick a quality preset: Low, Medium, High or Ultra. Medium is the default.

Shadows cost the most. If the game runs slowly, lower **Shadow Distance**.

## Building

```bash
python3 tools/build.py    # writes the zip to dist/
python3 tools/check.py    # compiles every stage (needs glslang)
```

Stage files come from `tools/stages.py` and `block.properties` from `tools/blocks.py`. Edit those, not the
generated files.

## License

MIT
