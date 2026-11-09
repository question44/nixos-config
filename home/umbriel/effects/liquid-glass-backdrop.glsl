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

const float R = 18.0;          // must match the glass window rule's corner_radius
const float FOLD = 11.0;       // the rim mirrors the strip inside this line, logical px from the edge
const float CREASE = 1.5;      // softness of the fold, px
const float MAG = 1.2;         // the reflection is this much larger than what it mirrors
const float SHARP = 0.6;       // unblurred share in the rim
const float CLEAR = 3.2;       // the rim stays sharp out to this many folds from the edge
const float SPLIT = 0.06;      // colour split along the bend, fraction of it
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

vec3 tap(vec2 uv, vec2 n, float px, float sharp) {
  vec2 q = uv + n * px / umbriel_size;
  vec3 frosted = umbriel_sample(q).rgb;
  return sharp > 0.0 ? mix(frosted, umbriel_sample_raw(q).rgb, sharp) : frosted;
}

vec4 backdrop(vec2 uv) {
  vec2 halfSize = umbriel_size * 0.5;
  float r = min(R, min(halfSize.x, halfSize.y));
  vec2 p = uv * umbriel_size - halfSize;
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

  vec3 col;
  if (s < CLEAR * fold) {
    // Sharp in the reflection and the strip it mirrors, frosted further in.
    float sharp = SHARP * (1.0 - smoothstep(2.0 * fold, CLEAR * fold, s));
    col = vec3(
      tap(uv, n, bend * (1.0 + SPLIT), sharp).r,
      tap(uv, n, bend, sharp).g,
      tap(uv, n, bend * (1.0 - SPLIT), sharp).b);
  } else {
    col = umbriel_sample(uv).rgb;
  }

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
