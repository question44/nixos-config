// Border effect for focused glass windows: a light hairline whose brightness
// follows the same top-left light as liquid-glass.glsl, in place of the accent
// ring. Unfocused glass windows keep the native (dark) unfocused ring.

const vec2 LIGHT = vec2(-0.5, -0.866);  // from the top-left (y down)

vec4 border(vec2 uv) {
  vec2 px = 1.0 / umbriel_size;
  vec2 g = vec2(
    umbriel_border_distance(uv + vec2(px.x, 0.0)) - umbriel_border_distance(uv - vec2(px.x, 0.0)),
    umbriel_border_distance(uv + vec2(0.0, px.y)) - umbriel_border_distance(uv - vec2(0.0, px.y)));
  vec2 n = length(g) > 0.0 ? normalize(g) : vec2(0.0);  // outward

  float facing = dot(n, LIGHT);
  float level = 0.30
    + 0.45 * pow(max(facing, 0.0), 1.5)
    + 0.15 * pow(max(-facing, 0.0), 1.5);

  float coverage = umbriel_sample(uv).a;  // the native ring, antialiased
  return vec4(vec3(level), level) * coverage;
}
