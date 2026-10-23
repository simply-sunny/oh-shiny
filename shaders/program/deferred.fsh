// After solid things and before water and glass: a copy of the picture so far, which water reflects and refracts.

/*
const int colortex0Format = RGB10_A2;
const int colortex5Format = RGB10_A2;
const int colortex6Format = RGBA16F;
const int colortex7Format = RGBA16F;
const int colortex10Format = R11F_G11F_B10F;
const int colortex11Format = R11F_G11F_B10F;
const int colortex12Format = R11F_G11F_B10F;
const int colortex13Format = R11F_G11F_B10F;
const int colortex14Format = R11F_G11F_B10F;
const int colortex15Format = R32F;
*/
const bool colortex5Clear = false;

uniform sampler2D colortex0;

in vec2 texCoord;

layout(location = 0) out vec4 sceneCopy;

void main() {
    sceneCopy = texelFetch(colortex0, ivec2(gl_FragCoord.xy), 0);
}
