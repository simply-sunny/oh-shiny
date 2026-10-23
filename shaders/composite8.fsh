#version 330 compatibility

#include "/lib/settings.glsl"
/* RENDERTARGETS: 13 */
uniform sampler2D colortex14;
uniform sampler2D colortex13;
#define MX_BLOOM_IN colortex14
#define MX_BLOOM_OUT colortex13
#include "/program/bloom_upsample.fsh"
