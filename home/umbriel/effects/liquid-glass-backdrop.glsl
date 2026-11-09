// Liquid-glass backdrop: drawn by the window's blur node, under the window.
// Needs Umbriel's backdrop effect kind (patches/umbriel-backdrop-effect.patch):
//   umbriel_sample(uv)      the blurred backdrop
//   umbriel_sample_raw(uv)  the unblurred backdrop
// both readable up to the preset's padding past the window edge.
//
// Matched against macOS 26 `macos-glass-regular` (Ghostty) on the same
// wallpaper. Apple's rim is a wide band that pulls in what lies *beyond* the
// window edge, magnified as it wraps round the edge, while the body shows the backdrop
// with its colours a little brighter and more saturated. The edge is a faint
// dark hairline with a faint light line just inside it.

const float R = 18.0;          // must match the glass window rule's corner_radius
const float BAND = 60.0;       // width of the lens band, logical px
const float REACH = 24.0;      // how far beyond the edge the rim pixel looks (<= preset padding)
const float SHARP = 0.35;      // unblurred share at the very edge, fading to 0 inward
const float SPLIT = 0.015;      // colour split along the bend, fraction of it
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

  float band = min(BAND, min(halfSize.x, halfSize.y) * 0.5);
  float t = 1.0 - clamp(s / band, 0.0, 1.0);  // 1 at the edge, 0 at the band's inner side

  vec3 col;
  if (t > 0.0) {
    // The band shows the strip from its inner side to REACH past the edge.
    // f is a Hermite curve: slope band/(band+REACH) at the inner side, so the
    // band joins the body without a seam, and slope 0 at the edge, so what
    // lies just past the edge is stretched across the outer band (magnified).
    float k = band / (band + REACH);
    float f = k * (t * t * t - 2.0 * t * t + t) + (3.0 * t * t - 2.0 * t * t * t);
    float bend = (band + REACH) * f - band * t;
    float sharp = SHARP * t * t;
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
