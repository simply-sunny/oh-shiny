#version 330 compatibility

#include "/lib/settings.glsl"
/* RENDERTARGETS: 13 */
uniform sampler2D colortex12;
#define MX_BLOOM_IN colortex12
#include "/program/bloom_downsample.fsh"
