// What Iris hands every program. Unused ones cost nothing.
#ifndef MX_UNIFORMS
#define MX_UNIFORMS

uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform mat4 shadowModelView;
uniform mat4 shadowModelViewInverse;
uniform mat4 shadowProjection;

uniform vec3 sunPosition;
uniform vec3 moonPosition;
uniform vec3 cameraPosition;
uniform vec3 skyColor;
uniform vec3 fogColor;

uniform float rainStrength;
uniform float frameTimeCounter;
uniform float viewWidth;
uniform float viewHeight;
uniform float far;
uniform float fogStart;
uniform float fogEnd;
uniform float nightVision;
uniform float darknessFactor;
uniform float blindness;
uniform float screenBrightness;
uniform float ambientLight;

uniform int isEyeInWater;
uniform int renderStage;
uniform ivec2 eyeBrightnessSmooth;
uniform bool hasSkylight;
uniform bool hasCeiling;

#endif
