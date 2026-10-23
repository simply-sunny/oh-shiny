#version 330 compatibility

#include "/lib/settings.glsl"
/* RENDERTARGETS: 12 */
uniform sampler2D colortex13;
uniform sampler2D colortex12;
#define MX_BLOOM_IN colortex13
#define MX_BLOOM_OUT colortex12
#include "/program/bloom_upsample.fsh"
