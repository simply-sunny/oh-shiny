// The kind of block a piece of terrain came from, from the ids block.properties gives each block (Iris hands
// them to vertex shaders as mc_Entity.x). Must agree with block.properties.
#ifndef MX_BLOCK_IDS
#define MX_BLOCK_IDS

const int MX_BLOCK_WATER = 1;
const int MX_BLOCK_LAVA = 2;
const int MX_BLOCK_LEAVES = 3;
const int MX_BLOCK_PLANT = 4;
const int MX_BLOCK_PLANT_UPPER = 5;
const int MX_BLOCK_SHINY = 6;
const int MX_BLOCK_METAL = 7;
// The lower half of a two-block plant (PLANT_UPPER is its upper half).
const int MX_BLOCK_PLANT_LOWER = 10;
bool mx_is_plant(int type) {
    return type == MX_BLOCK_PLANT || type == MX_BLOCK_PLANT_LOWER || type == MX_BLOCK_PLANT_UPPER;
}

// A block that gives off light. How bright it is comes from the block light on its own faces.
const int MX_BLOCK_GLOWING = 32;

// block.properties numbers kinds from 10000 (10000 + kind), and blocks that give off light from 10100, one id
// for each color of light (10100 + its place in mx_light_palette, light_colors.glsl).
int mx_block_type(float id) {
    int value = int(id + 0.5);
    if (value >= 10100 && value < 10116) return MX_BLOCK_GLOWING;
    if (value > 10000 && value < 10100) return value - 10000;
    return 0;
}

// The color of the light a block gives (its place in the palette), or -1 for a block that gives none. Lava gives
// the light of fire.
int mx_light_index(float id) {
    int value = int(id + 0.5);
    if (value >= 10100 && value < 10116) return value - 10100;
    if (value == 10000 + MX_BLOCK_LAVA) return 1;
    return -1;
}

#endif
