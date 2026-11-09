// Liquid-glass body for layer surfaces (Noctalia bar, dock, panels, OSD).
// Needs Umbriel's backdrop effect kind with layer-rule support
// (patches/umbriel-backdrop-effect.patch).
//
// A layer's blur node covers the whole surface rectangle and is cut to the
// shapes the client draws by `blur_ignore_alpha`, so the shader cannot know
// where those shapes' edges are: no lens rim or fold here, only the body of
// liquid-glass-backdrop.glsl (frost with Apple-like vibrancy and lift).

const float VIBRANCY = 1.25;   // saturation of the glass
const float LIFT = 1.08;       // brightness of the glass (multiplicative)
const float MILK = 0.02;       // mix towards white

vec4 backdrop(vec2 uv) {
  vec3 col = umbriel_sample(uv).rgb;
  float lum = dot(col, vec3(0.2126, 0.7152, 0.0722));
  col = max(mix(vec3(lum), col, VIBRANCY), 0.0);
  col = mix(col * LIFT, vec3(1.0), MILK);
  return vec4(col, 1.0);
}
