#version 330 compatibility

#include "/lib/settings.glsl"
/* RENDERTARGETS: 12 */
uniform sampler2D colortex11;
#define MX_BLOOM_IN colortex11
#include "/program/bloom_downsample.fsh"
