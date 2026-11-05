# CurseForge release sheet

CurseForge projects can't be created through the API, so the project is made by hand at [authors.curseforge.com](https://authors.curseforge.com/). Files are uploaded with `tools/publish.py curseforge`. The description is edited on the site, and the listing body after the horizontal rule is its source.

## Project settings

| Field | Value |
| --- | --- |
| Name | **oh shiny!** |
| Project ID | `1769227` (slug `oh-shiny`) |
| Class | Shaders |
| Summary | A shader pack derived from ohjey’s Metallum Extra shaders, with colored lighting, soft shadows, reflective water, and a cinematic sky. |
| Category | Realistic |
| License | MIT |
| Avatar | `branding/icon.png` |
| Gallery | Sunset, Moon, Night sky, Village at night |
| Source | https://github.com/simply-sunny/oh-shiny |

## Files

One file per release zip, release type `release`, game versions as in `GAME_VERSIONS` in `tools/publish.py`.

| File | CurseForge file ID |
| --- | --- |
| `oh shiny! 1.5.3.zip` | `9423433` |

Earlier file IDs aren't recorded.

---

# oh shiny!

A shader pack for Minecraft 1.20.1–26.3, with colored lighting, soft shadows, reflective water, and a cinematic sky.

## Credits

The original shaders were created by **[ohjey](https://github.com/ohjey)** and the **[Metallum Extra contributors](https://github.com/ohjey/metallum-extra)**. oh shiny! is derived from the shaders formerly built into Metallum Extra. Credit for that original work belongs to them.

Standalone adaptation and ongoing development: **[simply-sunny](https://github.com/simply-sunny)**. Published with the original author’s permission.

Distributed under the **MIT License**. The original copyright notice, “Copyright (c) 2026 Metallum Extra contributors,” and full license are preserved in the downloadable pack.

## Features

- Sun and moon shadows, with soft or pixelated edges
- Colored light from torches, soul fire, sea lanterns, and amethyst
- Light from held torches and lanterns
- Reflective water with ripples and caustics
- Sunsets in gold and coral, or a color you pick, plus stars and the Milky Way
- Bloom, sun rays, ambient occlusion, and moving foliage
- TAA, FXAA, sharpening, and adjustable color grading
- Distant Horizons support, plus Voxy on Iris
- Low, Medium, High, and Ultra quality presets

## Installation

1. Install Iris with Sodium, or use Metallum with [Leadlight](https://github.com/ohjey/leadlight) on Apple silicon.
2. Download the shader pack ZIP and place it in your `shaderpacks` folder without extracting it.
3. Select it under Options → Video Settings → Shader Packs.

Medium is the default preset. Lower shadow distance or disable mob shadows if you need better performance.

[Source code](https://github.com/simply-sunny/oh-shiny) · [Report issues](https://github.com/simply-sunny/oh-shiny/issues)
