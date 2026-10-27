# Modrinth release sheet

This file is the source of truth for the Modrinth project settings, version metadata, and listing body. The listing body starts after the horizontal rule. Not on CurseForge.

## Project settings

| Field | Value |
| --- | --- |
| Title | **oh shiny!** |
| Slug | `oh-shiny-shaders` (`oh-shiny` belongs to another author's mod) |
| Project type | Shader |
| Project ID | `1YIPfAv7` (in review as of 2026-10-27) |
| Summary | A Minecraft shader pack derived from ohjey’s Metallum Extra shaders, with colored lighting, soft shadows, reflective water, and a cinematic sky. |
| License | MIT |
| Environment | Client-side only |
| Featured categories | `colored-lighting`, `realistic`, `reflections` |
| Additional categories | `atmosphere`, `bloom`, `foliage`, `medium`, `shadows` |
| Source | https://github.com/simply-sunny/oh-shiny |
| Issues | https://github.com/simply-sunny/oh-shiny/issues |
| Wiki / docs | *(none)* |
| Discord | *(none)* |
| Donation links | *(none)* |
| Icon | *(none yet)* |
| Gallery | Sunset (featured), Moon, Night sky |

## Version metadata

Upload one Modrinth version per release zip, version number as in `VERSION`, channel `release`, loader `iris`. The title and version names keep the "!" on Modrinth and CurseForge; the zip (`oh shiny <version>.zip`, from `tools/build.py`) and everything on GitHub drop it. 1.5.1 was uploaded under its old name.

| File | Version ID | Modrinth `game_versions` |
| --- | --- | --- |
| `oh shiny! 1.5.1.zip` | `U2kVimHR` | `26.1`, `26.1.1`, `26.1.2`, `26.2`, `26.3` |

Version name format: `oh shiny! 1.5.1`. Versions before 1.5.1 are on GitHub Releases only.

---

# oh shiny!

A shader pack for Minecraft 26.1–26.3, with colored lighting, soft shadows, reflective water, and a cinematic sky.

## Credits

The original shaders were created by **[ohjey](https://github.com/ohjey)**. oh shiny! is derived from the shaders formerly built into Metallum Extra. Credit for that original work belongs to them.

Standalone adaptation and ongoing development: **[simply-sunny](https://github.com/simply-sunny)**. Published with the original author’s permission.

Distributed under the **MIT License**. The original copyright notice, “Copyright (c) 2026 Metallum Extra contributors,” and full license are preserved in the downloadable pack.

## Features

- Sun and moon shadows, with soft or pixelated edges
- Colored light from torches, soul fire, sea lanterns, and amethyst, etc.
- Light from held torches and lanterns
- Reflective water with ripples and caustics
- Sunsets, stars, and the Milky Way
- Bloom, sun rays, ambient occlusion, and moving foliage
- TAA, FXAA, sharpening, and adjustable color grading
- Distant Horizons and Voxy support
- Low, Medium, High, and Ultra quality presets

## Installation

1. Install Iris with Sodium, or use Metallum with [Leadlight](https://github.com/ohjey/leadlight) on Apple silicon.
2. Download the shader pack ZIP and place it in your `shaderpacks` folder without extracting it.
3. Select it under Options → Video Settings → Shader Packs.

Medium is the default preset. Lower shadow distance or disable mob shadows if you need better performance.

[Source code](https://github.com/simply-sunny/oh-shiny) · [Report issues](https://github.com/simply-sunny/oh-shiny/issues)
