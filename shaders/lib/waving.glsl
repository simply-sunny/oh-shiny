// Wind and water movement, applied to terrain vertices. The shadow pass applies the same movement, so shadows
// follow what casts them.
#ifndef MX_WAVING
#define MX_WAVING

#include "/lib/frame.glsl"
#include "/lib/block_ids.glsl"

float mx_water_height(vec2 world, float time) {
    return sin(world.x * 0.82 + world.y * 0.53 + time * 1.45) * 0.5
         + sin(world.x * -1.71 + world.y * 1.27 + time * 1.93) * 0.3
         + sin(world.x * 3.13 + world.y * 2.29 - time * 2.61) * 0.2;
}

// How high a vertex is in its block, 0 at the bottom and 1 at the top, from Iris's at_midBlock (the way to the
// block's middle, in 64ths of a block). A plant bends by it, the more the higher, so every part of it moves
// together: the game's crossed plants, and the 3D plants of resource packs (Mikey Jeo's and the like), whose
// many small faces would each bend on their own if the bend went by their textures instead.
float mx_height_in_block(vec4 mid_block) {
    return 0.5 - mid_block.y / 64.0;
}

// `position` is relative to the eye, in world orientation. `height`: from mx_height_in_block.
vec3 mx_wave(vec3 position, int type, float height) {
    if (!MxWaving || type == 0 || type == MX_BLOCK_GLOWING || type == MX_BLOCK_GLOW_SPECKS) {
        return position;
    }
    // Glow berries hang on vines that sway like the ones without.
    if (type == MX_BLOCK_GLOW_BERRIES) {
        type = MX_BLOCK_LEAVES;
    }
    vec3 world = position + MxCameraPos.xyz;
    float time = MxCameraPos.w;

    if (type == MX_BLOCK_WATER) {
        // Only the water's surface moves. Its sides and bottom end on whole block heights; the surface does not.
        float height = fract(world.y);
        if (height > 0.05 && height < 0.95) {
            position.y += mx_water_height(world.xz, time) * 0.035;
        }
        return position;
    }

    if (type == MX_BLOCK_LEAVES || mx_is_plant(type)) {
        // A slow sway shared by everything nearby, with a faster flutter on top; stronger in the rain.
        float wind = 1.0 + 1.5 * MxSkyAmbient.w;
        float sway = sin(world.x * 0.35 + world.z * 0.22 + time * 1.2) + 0.5 * sin(world.x * 0.9 - world.z * 1.3 + time * 2.7);
        float flutter = sin(world.x * 2.3 + world.y * 1.7 + world.z * 2.9 + time * 2.6);
        float amount;
        if (type == MX_BLOCK_LEAVES) {
            amount = 0.015;
        } else if (type == MX_BLOCK_PLANT || type == MX_BLOCK_PLANT_LOWER) {
            // Rooted at the bottom; some models reach a little below it.
            amount = 0.07 * max(height, 0.0);
        } else {
            // The upper half's bottom meets the lower half's top.
            amount = 0.07 + 0.05 * height;
        }
        position.x += (sway + 0.25 * flutter) * amount * wind;
        position.z += (sway * 0.6 - 0.25 * flutter) * amount * wind;
        return position;
    }

    return position;
}

#endif
