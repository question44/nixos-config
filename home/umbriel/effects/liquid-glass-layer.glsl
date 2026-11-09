// Liquid glass for layer surfaces (Noctalia bar, dock, panels, OSD).
// Needs Umbriel's backdrop effect kind with layer support
// (patches/umbriel-backdrop-effect.patch): umbriel_shape(uv) is the coverage
// of the shape the client draws (its alpha past blur_ignore_alpha), so the rim
// follows the capsules and panels instead of the layer's rectangle.
//
// Same glass as liquid-glass-backdrop.glsl: a mirrored fold near the edge
// (total internal reflection), colour fringe, blur that weakens towards the
// edge, Apple-like vibrancy and lift, a faint dark-and-light hairline.
// The distance to the edge and its direction come from a search through the
// shape, so it is only exact within REACH of an edge; deeper is plain body.

const float REACH = 28.0;      // how far the edge search looks, logical px
const float FOLD = 9.0;        // the rim mirrors the strip inside this line, px from the edge
const float CREASE = 1.5;      // softness of the fold, px
const float MAG = 1.2;         // the reflection is this much larger than what it mirrors
const float SPLIT = 0.12;      // colour split along the bend, fraction of it
const float KERNEL = 5.0;      // shader blur radius where it hands over to the frost, px
const float EDGE_BLUR = 2.0;   // blur radius left at the edge, px
const float MILK = 0.02;       // mix towards white
const float LIFT = 1.08;       // brightness (multiplicative)
const float VIBRANCY = 1.25;   // saturation
const float LINE = 0.10;       // light edge line strength
const float LINE_TOP = 0.08;   // extra where the edge faces up
const float OUTLINE = 0.22;    // darkening of the outermost pixel

bool outside(vec2 uv, vec2 dir, float px) {
  return umbriel_shape(uv + dir * px / umbriel_size) < 0.5;
}

// x: px from the nearest edge (REACH when none is closer); yz: outward normal.
vec3 edge(vec2 uv) {
  // Deep inside a large shape: no edge within REACH in 8 directions.
  bool near = false;
  for (int i = 0; i < 8; i++) {
    float a = float(i) * 0.785398;
    if (outside(uv, vec2(cos(a), sin(a)), REACH)) {
      near = true;
    }
  }
  if (!near) {
    return vec3(REACH, 0.0, 0.0);
  }
  float best = REACH;
  vec2 bestDir = vec2(0.0);
  vec2 normal = vec2(0.0);
  for (int i = 0; i < 16; i++) {
    float a = float(i) * 0.392699;
    vec2 d = vec2(cos(a), sin(a));
    for (int k = 1; k <= 14; k++) {
      float t = float(k) * 2.0;
      if (t > best + 2.0) {
        break;
      }
      if (outside(uv, d, t)) {
        normal += d / (t * t);
        if (t < best) {
          best = t;
          bestDir = d;
        }
        break;
      }
    }
  }
  if (best >= REACH) {
    return vec3(REACH, 0.0, 0.0);
  }
  // Refine the crossing along the nearest direction to a fraction of a pixel.
  float lo = max(best - 2.0, 0.0);
  float hi = best;
  for (int j = 0; j < 4; j++) {
    float mid = 0.5 * (lo + hi);
    if (outside(uv, bestDir, mid)) {
      hi = mid;
    } else {
      lo = mid;
    }
  }
  vec2 n = length(normal) > 0.0 ? normalize(normal) : bestDir;
  return vec3(0.5 * (lo + hi), n);
}

// The backdrop blurred by w: 0 at the edge, 1 the compositor's frost.
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

vec4 backdrop(vec2 uv) {
  vec3 e = edge(uv);
  float s = e.x;
  vec2 n = e.yz;

  // Mirrored fold, as on the windows.
  float fold = FOLD;
  float x = fold - s;
  float k = x > 0.0 ? 1.0 / MAG : 1.0;
  float mirrored = fold + k * x * x / sqrt(x * x + CREASE * CREASE);
  float bend = s < REACH ? s - mirrored : 0.0;

  float f = 1.0 - clamp(s / REACH, 0.0, 1.0);
  float w = 1.0 - f * f;
  vec2 o = n * bend / umbriel_size;
  vec3 col = vec3(
    graded(uv + o * (1.0 + SPLIT), w).r,
    graded(uv + o, w).g,
    graded(uv + o * (1.0 - SPLIT), w).b);

  float lum = dot(col, vec3(0.2126, 0.7152, 0.0722));
  col = max(mix(vec3(lum), col, VIBRANCY), 0.0);
  col = mix(col * LIFT, vec3(1.0), MILK);

  float up = max(-n.y, 0.0);
  col *= 1.0 - OUTLINE * exp(-pow(s / 0.7, 2.0));
  col += exp(-pow((s - 1.6) / 0.6, 2.0)) * (LINE + LINE_TOP * up);

  return vec4(col, 1.0);
}
