// Liquid-glass window effect, an approximation of macOS 26 Liquid Glass.
//
// A window effect sees the window already composited over its blurred
// backdrop, and umbriel_sample returns nothing outside the window, so the
// glass is built from the pixels inside it:
//   lip       a convex, rounded lip along the edge refracts: it pulls pixels
//             outward from inside, mostly right at the rim, and splits the
//             colours slightly there;
//   body      a small saturation and brightness lift (vibrancy);
//   fresnel   the lip reflects more towards the rim;
//   specular  a crisp ~1 px rim line, bright where the edge faces the light
//             (top-left) and fainter on the opposite edge, and a soft sheen
//             across the lip.

const float R = 18.0;           // must match the glass window rule's corner_radius
const float LIP = 16.0;         // width of the refracting lip, logical px
const float DEPTH = 10.0;       // how far the lip shifts the image at the rim, px
const float DISPERSION = 0.18;  // colour split at the rim, fraction of the shift
const float VIBRANCY = 1.12;    // saturation of the body
const float LIFT = 1.04;        // brightness gain on the body (multiplicative: the
                                // buffer can be linear on HDR outputs)
const float FRESNEL = 0.06;     // whitening at the rim
const float RIM = 0.60;         // strength of the specular line
const float SHEEN = 0.06;       // soft highlight across the lip
const vec2 LIGHT = vec2(-0.5, -0.866);  // light direction, from the top-left (y down)

float sdRoundBox(vec2 p, vec2 b, float r) {
  vec2 q = abs(p) - b + r;
  return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - r;
}

vec4 window(vec2 uv) {
  vec2 halfSize = umbriel_size * 0.5;
  float r = min(R, min(halfSize.x, halfSize.y));
  vec2 p = uv * umbriel_size - halfSize;
  float d = sdRoundBox(p, halfSize, r);  // < 0 inside, 0 on the edge

  vec2 e = vec2(1.0, 0.0);
  vec2 g = vec2(
    sdRoundBox(p + e.xy, halfSize, r) - sdRoundBox(p - e.xy, halfSize, r),
    sdRoundBox(p + e.yx, halfSize, r) - sdRoundBox(p - e.yx, halfSize, r));
  vec2 n = length(g) > 0.0 ? normalize(g) : vec2(0.0);  // outward normal

  // 0 at the inner end of the lip, 1 on the rim.
  float t = 1.0 - clamp(-d / LIP, 0.0, 1.0);
  // Slope of a circular (convex) profile, capped at 5; refraction follows it,
  // so the bend stays small across the lip and climbs steeply at the rim.
  float slope = t / sqrt(max(1.0 - t * t, 0.04));
  float shift = DEPTH * slope / 5.0;
  vec2 off = -n * shift / umbriel_size;
  float split = DISPERSION * t;

  vec4 c = umbriel_sample(uv + off);
  float a = c.a;
  vec3 col = vec3(
    umbriel_sample(uv + off * (1.0 + split)).r,
    c.g,
    umbriel_sample(uv + off * (1.0 - split)).b);

  // Body: vibrancy.
  float lum = dot(col, vec3(0.2126, 0.7152, 0.0722));
  col = max(mix(vec3(lum), col, VIBRANCY), 0.0) * LIFT;

  // Lip: fresnel whitening and a soft sheen facing the light.
  float facing = dot(n, LIGHT);
  float key = pow(max(facing, 0.0), 2.0);
  float back = 0.45 * pow(max(-facing, 0.0), 2.0);
  col = mix(col, vec3(a), FRESNEL * t * t * t);
  col += a * SHEEN * (key + 0.5 * back) * t * t;

  // Rim: a thin specular line just inside the edge.
  float line = exp(-pow((d + 1.0) / 0.7, 2.0));
  col += a * line * RIM * (key + back + 0.12);

  return vec4(clamp(col, 0.0, a), a);
}
