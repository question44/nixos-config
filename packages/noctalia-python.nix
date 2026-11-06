# Python for Noctalia plugins, with GTK and layer-shell typelibs.
{ pkgs }:

pkgs.symlinkJoin {
  name = "noctalia-plugin-python";
  paths = [
    (pkgs.python3.withPackages (ps: [
      ps.pygobject3
      ps.pillow
      ps.psutil
      ps.speedtest-cli
      ps.syncedlyrics
    ]))
  ];
  nativeBuildInputs = [ pkgs.makeWrapper ];
  postBuild = ''
    wrapProgram "$out/bin/python3" \
      --prefix GI_TYPELIB_PATH : "${pkgs.gobject-introspection.out}/lib/girepository-1.0:${pkgs.at-spi2-core.out}/lib/girepository-1.0:${pkgs.gdk-pixbuf.out}/lib/girepository-1.0:${pkgs.pango.out}/lib/girepository-1.0:${pkgs.harfbuzz.out}/lib/girepository-1.0:${pkgs.gtk3.out}/lib/girepository-1.0:${pkgs.gtk-layer-shell.out}/lib/girepository-1.0" \
      --prefix LD_LIBRARY_PATH : "${pkgs.gtk3}/lib:${pkgs.gtk-layer-shell}/lib"
    if [ ! -e "$out/bin/python" ]; then
      ln -s python3 "$out/bin/python"
    fi
  '';
}
