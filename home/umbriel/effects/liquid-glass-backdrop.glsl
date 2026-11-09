// Liquid-glass backdrop: drawn by the window's blur node, under the window.
// Needs Umbriel's backdrop effect kind (patches/umbriel-backdrop-effect.patch):
//   umbriel_sample(uv)      the blurred backdrop
//   umbriel_sample_raw(uv)  the unblurred backdrop
// both readable up to the preset's padding past the window edge.
//
// Matched against macOS 26 `macos-glass-regular` (Ghostty) on the same
// wallpaper. Apple's rim mirrors the strip just inside it (total internal
// reflection: glyphs near the edge appear next to their mirror image), while
// the body shows the backdrop
// with its colours a little brighter and more saturated. The edge is a faint
// dark hairline with a faint light line just inside it.

const float FOLD = 11.0;       // the rim mirrors the strip inside this line, logical px from the edge
const float CREASE = 1.5;      // softness of the fold, px
const float MAG = 1.2;         // the reflection is this much larger than what it mirrors
const float FADE = 80.0;       // the blur weakens over this distance towards the edge, logical px
const float KERNEL = 5.0;      // radius of the shader's own blur where it hands over to the frost, px
const float EDGE_BLUR = 2.0;   // blur radius left right at the edge, px
const float SPLIT = 0.12;      // colour split along the bend, fraction of it
const float MILK = 0.02;       // mix towards white over the whole glass
const float LIFT = 1.08;       // brightness of the glass (multiplicative)
const float VIBRANCY = 1.25;   // saturation of the glass
const float LINE = 0.10;       // light edge line strength, all round
const float LINE_TOP = 0.08;   // extra strength where the edge faces up
const float OUTLINE = 0.22;    // darkening of the outermost pixel (a faint dark hairline)
const float GLINT = 0.0;       // soft brightening of the band towards the edge

float sdRoundBox(vec2 p, vec2 b, float r) {
  vec2 q = abs(p) - b + r;
  return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - r;
}

// The unblurred backdrop, softened by a small 5-tap blur: Apple's reflection
// is slightly soft, which keeps the rim from looking sharper than the body.
// The backdrop blurred by w: 0 at the edge (almost clear), 1 in the body (the
// compositor's frost). Umbriel provides only the full frost and the unblurred
// backdrop, so the in-between strengths blur the unblurred one here with a
// 20-tap golden-angle disc whose radius grows with w, then hand over to the frost.
vec3 graded(vec2 q, float w) {
  vec3 frost = umbriel_sample(q).rgb;
  if (w >= 1.0) {
    return frost;
  }
  float rad = mix(EDGE_BLUR, KERNEL, w);
  vec3 acc = umbriel_sample_raw(q).rgb;
  for (int i = 0; i < 19; i++) {
    float a = float(i) * 2.39996;
    float rr = rad * sqrt((float(i) + 0.5) / 19.0);
    acc += umbriel_sample_raw(q + vec2(cos(a), sin(a)) * rr / umbriel_size).rgb;
  }
  return mix(acc / 20.0, frost, smoothstep(0.3, 1.0, w));
}

vec3 tap(vec2 uv, vec2 n, float px, float w) {
  return graded(uv + n * px / umbriel_size, w);
}

vec4 backdrop(vec2 uv) {
  vec2 halfSize = umbriel_size * 0.5;
  vec2 p = uv * umbriel_size - halfSize;
  // The window's own corner radius (tl, tr, br, bl), as Umbriel rounds it.
  vec4 c = umbriel_corner_radius;
  float r = p.y < 0.0 ? (p.x < 0.0 ? c.x : c.y) : (p.x < 0.0 ? c.w : c.z);
  r = min(r, min(halfSize.x, halfSize.y));
  float d = sdRoundBox(p, halfSize, r);
  float s = max(-d, 0.0);  // px in from the edge

  // Smooth outward direction: a wide difference keeps the corners from creasing.
  float h = 3.0;
  vec2 g = vec2(
    sdRoundBox(p + vec2(h, 0.0), halfSize, r) - sdRoundBox(p - vec2(h, 0.0), halfSize, r),
    sdRoundBox(p + vec2(0.0, h), halfSize, r) - sdRoundBox(p - vec2(0.0, h), halfSize, r));
  vec2 n = length(g) > 0.0 ? normalize(g) : vec2(0.0);

  // Total internal reflection in the rim: within FOLD of the edge the glass
  // shows the strip just inside the fold, mirrored (soft at the crease).
  float fold = min(FOLD, min(halfSize.x, halfSize.y) * 0.25);
  float x = fold - s;
  // Soft |x| that tends to |x| exactly, so the body past the fold is unshifted.
  float k = x > 0.0 ? 1.0 / MAG : 1.0;  // the reflected strip covers less source: magnified
  float mirrored = fold + k * x * x / sqrt(x * x + CREASE * CREASE);  // ~s past the fold, mirrored inside it
  float bend = s - mirrored;  // <= 0: along -n, i.e. inward
  float t = clamp(1.0 - s / fold, 0.0, 1.0);

  // Blur strength: weak at the edge, full frost from FADE inwards. Ease-out,
  // so the frost returns quickly and only the outermost strip is near clear.
  float x = 1.0 - clamp(s / FADE, 0.0, 1.0);
  float w = 1.0 - x * x;
  vec3 col = vec3(
    tap(uv, n, bend * (1.0 + SPLIT), w).r,
    tap(uv, n, bend, w).g,
    tap(uv, n, bend * (1.0 - SPLIT), w).b);

  float lum = dot(col, vec3(0.2126, 0.7152, 0.0722));
  col = max(mix(vec3(lum), col, VIBRANCY), 0.0);
  col = mix(col * LIFT, vec3(1.0), MILK);
  col += GLINT * t * t;

  // A faint dark hairline on the outermost pixel, a faint light one just inside.
  float up = max(-n.y, 0.0);
  col *= 1.0 - OUTLINE * exp(-pow(s / 0.7, 2.0));
  float line = exp(-pow((s - 1.6) / 0.6, 2.0));
  col += line * (LINE + LINE_TOP * up);

  return vec4(col, 1.0);
}
