{ runCommand, python3, woff2, ttyd, nerd-fonts, unifont_upper }:

# Keep the custom page in sync with the packaged ttyd client, without rebuilding JS.
runCommand "ttyd-web-assets" {
  nativeBuildInputs = [ (python3.withPackages (ps: [ ps.fonttools ps.brotli ])) woff2 ];
  ttydSource = ttyd.src;
  fontDirectory = "${nerd-fonts.jetbrains-mono}/share/fonts/truetype/NerdFonts/JetBrainsMono";
  legacyFont = "${unifont_upper}/share/fonts/opentype/unifont_upper.otf";
} ''
  mkdir -p "$out/fonts"
  for variant in Regular Bold Italic BoldItalic; do
    cp "$fontDirectory/JetBrainsMonoNerdFontMono-$variant.ttf" "$out/fonts/"
    woff2_compress "$out/fonts/JetBrainsMonoNerdFontMono-$variant.ttf"
    rm "$out/fonts/JetBrainsMonoNerdFontMono-$variant.ttf"
  done
  # Only ship the legacy-computing block used by fastfetch's small NixOS logo.
  python3 -m fontTools.subset "$legacyFont" --unicodes=U+1FB00-1FBFF \
    --no-prune-unicode-ranges \
    --flavor=woff2 --output-file="$out/fonts/TerminalLegacySymbols.woff2"
  python3 <<'PY'
  import gzip
  import os
  import re
  from pathlib import Path

  header = (Path(os.environ["ttydSource"]) / "src/html.h").read_text()
  page = gzip.decompress(bytes.fromhex("".join(re.findall(r"0x([0-9a-fA-F]{2})", header)))).decode()
  faces = []
  loads = []
  for variant, weight, style in [
      ("Regular", 400, "normal"), ("Bold", 700, "normal"),
      ("Italic", 400, "italic"), ("BoldItalic", 700, "italic"),
  ]:
      faces.append(
          '@font-face { font-family: "Erebor Terminal"; '
          f'font-weight: {weight}; font-style: {style}; font-display: block; '
          f'src: url("/fonts/JetBrainsMonoNerdFontMono-{variant}.woff2") format("woff2"); }}'
      )
      loads.append(f'document.fonts.load(\'{style} {weight} 16px "Erebor Terminal"\')')
  # A range-specific face supplements JetBrains Mono without replacing text/icons.
  faces.append(
      '@font-face { font-family: "Erebor Terminal Symbols"; font-weight: 400 700; '
      'font-style: normal; font-display: block; unicode-range: U+1FB00-1FBFF; '
      'src: url("/fonts/TerminalLegacySymbols.woff2") format("woff2"); }'
  )
  loads.append('document.fonts.load(\'16px "Erebor Terminal Symbols"\', "\\u{1FB0B}\\u{1FB83}")')
  # xterm draws a transparent background (allowTransparency); the page supplies the colour,
  # except when framed by the dashboard, which tints and blurs behind it instead.
  faces.append(
      'html, body { background: #2b2b2b !important; } '
      'html.embedded, html.embedded body, html.embedded #terminal-container, html.embedded .xterm, '
      'html.embedded .xterm-viewport, html.embedded .xterm-screen { background: transparent !important; }'
  )
  embedded = '<script>if (window.top !== window) document.documentElement.classList.add("embedded");</script>'
  assert page.count("</head>") == 1
  page = page.replace("</head>", '<link rel="preload" href="/fonts/JetBrainsMonoNerdFontMono-Regular.woff2" as="font" type="font/woff2" crossorigin><style>' + "\n".join(faces) + "</style></head>")
  # Wait for web fonts before xterm measures cells or initializes its renderer.
  start = '<script type="text/javascript">'
  assert page.count(start) == 1 and page.count("</script>") == 1
  page = page.replace(start, start + "Promise.all([" + ",".join(loads) + "]).catch(console.warn).then(() => {\n")
  page = page.replace("</script>", "\n});</script>")
  # After the font wrapper, which expects the page's single script.
  assert page.count("<head>") == 1
  page = page.replace("<head>", "<head>" + embedded)
  (Path(os.environ["out"]) / "index.html").write_text(page)
  PY
''
