#version 330 compatibility

#include "/lib/settings.glsl"
/* RENDERTARGETS: 11 */
uniform sampler2D colortex10;
#define MX_BLOOM_IN colortex10
#include "/program/bloom_downsample.fsh"
