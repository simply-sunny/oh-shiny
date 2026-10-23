#version 330 compatibility

#include "/lib/settings.glsl"
/* RENDERTARGETS: 10 */
uniform sampler2D colortex11;
uniform sampler2D colortex10;
#define MX_BLOOM_IN colortex11
#define MX_BLOOM_OUT colortex10
#include "/program/bloom_upsample.fsh"
