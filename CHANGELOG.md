# Changelog

All notable changes to oh shiny are documented here. This project follows [Semantic Versioning](https://semver.org/).

## [1.5.1] - 2026-10-26

### Added

- **TAA**: temporal anti-aliasing for the smoothest edges, with no shimmer on far-off blocks.
- **FXAA**: smooths every edge in the picture. When it's on, it replaces Smooth Edges.
- **Sharpening** (0–100%): brings back the crispness TAA softens. 30–50% works well with TAA.

All three are under Image in the settings, and all are off by default.

## [1.5.0] - 2026-10-26

### Fixed

- **Redstone ore**: lit redstone ore (when you step on or click it) glows only in its red specks, each fading softly into the stone. Before, the whole block glowed and the stone between the specks turned flat white.

## [1.4.9] - 2026-10-25

### Changed

- **Water**: ripples are cheaper to work out, fully fogged water is skipped, and reflections take fewer, longer steps.
- **Shadows** on terrain are cheaper per pixel.
- **Ambient occlusion** takes fewer samples.
- **Glow** takes two fewer passes.

On Leadlight, fullscreen, about 68 → 74 frames a second in the same view, with no visible difference.

## [1.4.8] - 2026-10-25

1.2.1 to 1.4.7 were test builds and weren't released.

### Added

- **Fog**: Off or 10% to 90%. A haze over that last share of everything drawn, Distant Horizons' and Voxy's far terrain included, thickest in the valleys. (#1)
- **Shadow Blur** softens ordinary shadow edges, and **Soft Pixel Edges** does the same for Pixel Shadows.
- **Sun Ray Strength**: Soft, Strong or Insane. Strong and Insane add shafts pouring across the picture, out past hills, trees and far-off terrain.
- **Hand Light**: a torch or other light held in your hand lights up what's around you, in its own color.
- **Color Grading** screen with exposure, contrast, shadows, highlights, saturation, vibrance, temperature, tint, split toning, fade and vignette.

### Changed

- **Shadows stay put as you move**: the shadow map is centred on a point fixed in the world and moves on in 4-block steps. (#2)
- **Pixel Shadows** go by how much of each pixel is covered, so edges no longer flip as you move.
- **Plants** sway in one piece, 3D plant resource packs like Mikey Jeo's too.
- **Glow berries**: only the berries glow. Sculk gives off teal light to match.

### Fixed

- Glowing eyes (endermen, spiders, Fresh Animations) keep their color instead of turning white.
- Under water: the sky is fogged, the sun bends with the ripples, and lava and deep water lose their dark smudges.
- Distant Horizons with transparency off: no more holes in the sea.

## [1.2.0] - 2026-10-23

### Added

- **Pixel Shadows**: shadows fall in whole texture pixels with blocky edges. Shadow Pixels sets how many fit across a block (16 matches the game's textures).
- **Distant Horizons**: its far-off terrain is lit and fogged like the rest, and clouds no longer draw over far mountains.
- **Voxy** (Iris only), shaded the same way.

### Changed

- Faster: the glow is added in the final pass, far-off shadows are cheaper, water reflections take fewer steps, and the sky isn't drawn twice above the horizon.

### Fixed

- Faint particles, like Particle Rain's mist, fade smoothly instead of flickering on and off.

## [1.1.0] - 2026-10-23

### Added

- **Mob Shadows**: turning it off stops mobs, players and chests casting shadows. It's off on Low.

### Changed

- Turning off Shadows skips most of the shadow pass. With Colored Light also off, it skips all of it.
- Ambient occlusion, sun rays, bloom and water reflections cost nothing when they're off.
- Shadows and ambient occlusion are cheaper when on.

About 25 to 40% faster than 1.0.0 in testing at 1440p on an M1 Pro.

## [1.0.0] - 2026-10-23

Initial release for Minecraft 26.1 to 26.3 with Iris and Sodium.

### Added

- Shadows, colored light, reflective water, a sky with stars and the Milky Way, bloom, sun rays, ambient occlusion, and waving plants and water.
