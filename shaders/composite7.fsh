#version 330 compatibility

#include "/lib/settings.glsl"
/* RENDERTARGETS: 14 */
uniform sampler2D colortex13;
#define MX_BLOOM_IN colortex13
#include "/program/bloom_downsample.fsh"
