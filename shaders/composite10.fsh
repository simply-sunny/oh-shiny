#version 330 compatibility

#include "/lib/settings.glsl"
/* RENDERTARGETS: 11 */
uniform sampler2D colortex12;
uniform sampler2D colortex11;
#define MX_BLOOM_IN colortex12
#define MX_BLOOM_OUT colortex11
#include "/program/bloom_upsample.fsh"
