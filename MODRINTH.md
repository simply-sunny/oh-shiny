# Modrinth release sheet

This file is the source of truth for the Modrinth project settings, version metadata, and listing body. The listing body starts after the horizontal rule. Not on CurseForge.

## Project settings

| Field | Value |
| --- | --- |
| Title | **oh shiny!** |
| Slug | `oh-shiny-shaders` (`oh-shiny` belongs to another author's mod) |
| Project type | Shader |
| Project ID | `1YIPfAv7` (rejected 2026-10-28: Forks and Reuploads, needs proof of permission or divergence) |
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

## Content Disclosures

- **Source work:** the shaders formerly built into [Metallum Extra](https://github.com/ohjey/metallum-extra) by **[ohjey](https://github.com/ohjey)**, licensed under the MIT License. Credit for that original work belongs to them.
- **This pack:** standalone adaptation and ongoing development by **[simply-sunny](https://github.com/simply-sunny)**.
- **Permission:** ohjey gave explicit permission to distribute oh shiny! on Modrinth and CurseForge. Proof: [Discord screenshot](https://github.com/simply-sunny/oh-shiny/blob/main/docs/permission.png)
- **License:** distributed under the **MIT License**. The original copyright notice, “Copyright (c) 2026 Metallum Extra contributors,” and full license are preserved in the downloadable pack.

### Changes from the original

- Standalone shader pack with its own settings screen and Low, Medium, High and Ultra presets
- TAA, FXAA and sharpening, plus adjustable color grading
- Pixel Shadows, a single shadow blur setting, and shadows that stay put as you move
- Distant Horizons and Voxy support
- Sun ray strength options, height-based fog, and under-water sun bending
- Performance work on water, shadows, ambient occlusion and glow
- Lit redstone ore glow and other lighting changes

Full history: [commits](https://github.com/simply-sunny/oh-shiny/commits/main) and [CHANGELOG](https://github.com/simply-sunny/oh-shiny/blob/main/CHANGELOG.md).

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
