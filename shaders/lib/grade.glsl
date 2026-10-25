// Color grading: the last touch on the finished picture, after bloom, in final.fsh. With every control at Normal
// none of this is compiled in.
#ifndef MX_GRADE
#define MX_GRADE

#include "/lib/frame.glsl"
#include "/lib/color.glsl"

// (GLSL 330 has no line continuation, hence the three tests.)
#if GRADE_EXPOSURE != 0 || GRADE_CONTRAST != 0 || GRADE_SATURATION != 0 || GRADE_VIBRANCE != 0
#define MX_GRADING
#endif
#if GRADE_TEMPERATURE != 0 || GRADE_TINT != 0 || GRADE_SHADOWS != 0 || GRADE_HIGHLIGHTS != 0 || GRADE_FADE != 0
#define MX_GRADING
#endif
#if GRADE_SHADOW_TONE_AMOUNT != 0 || GRADE_HIGHLIGHT_TONE_AMOUNT != 0 || GRADE_VIGNETTE != 0
#define MX_GRADING
#endif

#ifdef MX_GRADING

struct MxGrade {
    float exposure;      // stops
    float contrast;      // -0.5..0.5
    float saturation;    // -1..1
    float vibrance;      // -0.5..0.5
    float temperature;   // -0.5..0.5: cooler, warmer
    float tint;          // -0.5..0.5: greener, more magenta
    float shadows;       // -0.5..0.5: deeper, lifted
    float highlights;    // -0.5..0.5: held back, brighter
    float fade;          // 0..0.5: the blacks lifted to a grey, like a faded print
    vec4 shadowTone;     // rgb: color laid over the dark parts. a: how much
    vec4 highlightTone;  // rgb: color laid over the bright parts. a: how much
    float vignette;      // 0..1: how much the corners darken
};

// The colors split toning can lay over the shadows or the highlights, in display colors. Their brightness is
// taken out before they are used, so toning shifts the color and not how bright things are.
vec3 mx_tone_color(int hue) {
    if (hue == 0) return vec3(0.90, 0.25, 0.20); // red
    if (hue == 1) return vec3(0.95, 0.55, 0.20); // orange
    if (hue == 2) return vec3(0.95, 0.78, 0.35); // gold
    if (hue == 3) return vec3(0.45, 0.80, 0.30); // green
    if (hue == 4) return vec3(0.20, 0.62, 0.65); // teal
    if (hue == 5) return vec3(0.25, 0.45, 0.90); // blue
    if (hue == 6) return vec3(0.55, 0.35, 0.85); // purple
    return vec3(0.90, 0.40, 0.65);               // pink
}

// The Color Grading screen's settings.
MxGrade mx_grade_settings() {
    MxGrade g;
    g.exposure = float(GRADE_EXPOSURE) / 100.0;
    g.contrast = float(GRADE_CONTRAST) / 100.0;
    g.saturation = float(GRADE_SATURATION) / 100.0;
    g.vibrance = float(GRADE_VIBRANCE) / 100.0;
    g.temperature = float(GRADE_TEMPERATURE) / 100.0;
    g.tint = float(GRADE_TINT) / 100.0;
    g.shadows = float(GRADE_SHADOWS) / 100.0;
    g.highlights = float(GRADE_HIGHLIGHTS) / 100.0;
    g.fade = float(GRADE_FADE) / 100.0;
    g.vignette = float(GRADE_VIGNETTE) / 100.0;
    g.shadowTone = vec4(mx_tone_color(GRADE_SHADOW_TONE), float(GRADE_SHADOW_TONE_AMOUNT) / 100.0);
    g.highlightTone = vec4(mx_tone_color(GRADE_HIGHLIGHT_TONE), float(GRADE_HIGHLIGHT_TONE_AMOUNT) / 100.0);
    return g;
}

// A color with its brightness set to one, so multiplying by it shifts the color and keeps the brightness.
vec3 mx_hue_only(vec3 color) {
    return color / max(mx_luminance(color), 1.0e-4);
}

// Contrast as an S-curve through the middle grey, steeper for more, flatter for less, so whites and blacks are
// pushed towards their ends or pulled in without ever clipping.
vec3 mx_contrast(vec3 c, float amount) {
    c = clamp(c, 0.0, 1.0);
    if (amount >= 0.0) {
        return mix(c, c * c * (3.0 - 2.0 * c), amount * 2.0);
    }
    vec3 flat_curve = 0.5 - sin(asin(clamp(1.0 - 2.0 * c, -1.0, 1.0)) / 3.0);
    return mix(c, flat_curve, -amount * 2.0);
}

// The picture as shown (display colors) -> the graded picture. `uv` is where on the screen, for the vignette.
vec3 mx_color_grade(vec3 display, vec2 uv) {
    MxGrade g = mx_grade_settings();

    // Exposure and white balance work on light, so they are done in linear colors.
    vec3 c = mx_to_linear(display) * exp2(g.exposure);
    vec3 balance = vec3(1.0 + g.temperature * 0.30, 1.0 - g.tint * 0.25, 1.0 - g.temperature * 0.30);
    c *= balance / mx_luminance(balance);

    // The rest works on the picture as the eye sees its steps of brightness.
    c = mx_to_display(c);

    // Shadows and highlights move the brightness of the dark and the bright parts, each fading out towards the
    // other end, with the color kept.
    float before = max(mx_luminance(c), 1.0e-4);
    float after = before + g.shadows * 1.6 * before * (1.0 - before) * (1.0 - before)
                         + g.highlights * 1.6 * before * before * (1.0 - before);
    c *= max(after, 0.0) / before;

    c = mx_contrast(c, g.contrast);

    // Split toning: a color over the dark parts and another over the bright ones.
    float light = clamp(mx_luminance(c), 0.0, 1.0);
    float darkShare = (1.0 - light) * (1.0 - light) * g.shadowTone.a;
    float brightShare = light * light * g.highlightTone.a;
    c *= mix(vec3(1.0), mx_hue_only(g.shadowTone.rgb), darkShare);
    c *= mix(vec3(1.0), mx_hue_only(g.highlightTone.rgb), brightShare);

    // Saturation moves all color alike; vibrance moves the dull colors most and leaves the strong ones be.
    float grey = mx_luminance(c);
    c = mix(vec3(grey), c, 1.0 + g.saturation);
    float colorful = clamp(max(c.r, max(c.g, c.b)) - min(c.r, min(c.g, c.b)), 0.0, 1.0);
    c = mix(vec3(grey), c, 1.0 + g.vibrance * 2.0 * (1.0 - colorful));

    c = mix(vec3(g.fade), vec3(1.0), clamp(c, 0.0, 1.0));

    // The vignette: round, whatever the shape of the screen, darkening towards the corners.
    vec2 fromMiddle = (uv - 0.5) * vec2(MxScreen.x * MxScreen.w, 1.0);
    float edge = smoothstep(0.25, 0.95, length(fromMiddle) * 1.2);
    c *= 1.0 - g.vignette * 0.7 * edge * edge;

    return clamp(c, 0.0, 1.0);
}

#endif

#endif
