# Qt/GTK theming, Dolphin, XDG directories and default applications.
{
  config,
  lib,
  pkgs,
  darkly,
  ...
}:
{
  qt = {
    enable = true;
    platformTheme = {
      name = "kde";
      package = pkgs.kdePackages.plasma-integration;
    };
    style.package = darkly.packages.x86_64-linux.darkly-qt6;
  };
  gtk = {
    enable = true;
    iconTheme = {
      name = "candy-icons";
      package = pkgs.candy-icons;
    };
  };
  home.activation.dolphinColorScheme = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run ${pkgs.kdePackages.kconfig}/bin/kwriteconfig6 \
      --file "$HOME/.config/dolphinrc" \
      --group UiSettings \
      --key ColorScheme "*"
  '';
  # Enable every installed KIO thumbnailer; several are off by default.
  home.activation.dolphinPreviewPlugins = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run ${pkgs.kdePackages.kconfig}/bin/kwriteconfig6 \
      --file "$HOME/.config/dolphinrc" \
      --group PreviewSettings \
      --key Plugins "${
        lib.concatStringsSep "," [
          "appimagethumbnail"
          "audiothumbnail"
          "blenderthumbnail"
          "comicbookthumbnail"
          "cursorthumbnail"
          "directorythumbnail"
          "djvuthumbnail"
          "ebookthumbnail"
          "exrthumbnail"
          "ffmpegthumbs"
          "gsthumbnail"
          "imagethumbnail"
          "jpegthumbnail"
          "kraorathumbnail"
          "mobithumbnail"
          "opendocumentthumbnail"
          "pothumbnail"
          "rawthumbnail"
          "svgthumbnail"
          "textthumbnail"
          "windowsexethumbnail"
          "windowsimagethumbnail"
        ]
      }"
  '';
  home.activation.kdeIconTheme = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run ${pkgs.kdePackages.kconfig}/bin/kwriteconfig6 \
      --file "$HOME/.config/kdeglobals" \
      --group Icons \
      --key Theme "candy-icons"
  '';
  xdg.userDirs = {
    enable = true;
    createDirectories = true;
    projects = "${config.home.homeDirectory}/Projects";
  };
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "application/vnd.flatpak" = [ "org.kde.discover.desktop" ];
      "application/vnd.flatpak.ref" = [ "org.kde.discover.desktop" ];
      "application/vnd.flatpak.repo" = [ "org.kde.discover.desktop" ];
      "text/plain" = [ "dev.zed.Zed.desktop" ];
      "application/xhtml+xml" = [ "helium.desktop" ];
      "text/html" = [ "helium.desktop" ];
      "text/xml" = [ "helium.desktop" ];
      "x-scheme-handler/about" = [ "helium.desktop" ];
      "x-scheme-handler/http" = [ "helium.desktop" ];
      "x-scheme-handler/https" = [ "helium.desktop" ];
      "image/avif" = [ "org.kde.gwenview.desktop" ];
      "image/bmp" = [ "org.kde.gwenview.desktop" ];
      "image/gif" = [ "org.kde.gwenview.desktop" ];
      "image/heic" = [ "org.kde.gwenview.desktop" ];
      "image/heif" = [ "org.kde.gwenview.desktop" ];
      "image/jpeg" = [ "org.kde.gwenview.desktop" ];
      "image/jxl" = [ "org.kde.gwenview.desktop" ];
      "image/openraster" = [ "org.kde.gwenview.desktop" ];
      "image/png" = [ "org.kde.gwenview.desktop" ];
      "image/svg+xml" = [ "org.kde.gwenview.desktop" ];
      "image/svg+xml-compressed" = [ "org.kde.gwenview.desktop" ];
      "image/tiff" = [ "org.kde.gwenview.desktop" ];
      "image/webp" = [ "org.kde.gwenview.desktop" ];
      "image/x-eps" = [ "org.kde.gwenview.desktop" ];
      "image/x-icns" = [ "org.kde.gwenview.desktop" ];
      "image/x-ico" = [ "org.kde.gwenview.desktop" ];
      "image/x-portable-bitmap" = [ "org.kde.gwenview.desktop" ];
      "image/x-portable-graymap" = [ "org.kde.gwenview.desktop" ];
      "image/x-portable-pixmap" = [ "org.kde.gwenview.desktop" ];
      "image/x-psd" = [ "org.kde.gwenview.desktop" ];
      "image/x-tga" = [ "org.kde.gwenview.desktop" ];
      "image/x-webp" = [ "org.kde.gwenview.desktop" ];
      "image/x-xbitmap" = [ "org.kde.gwenview.desktop" ];
      "image/x-xcf" = [ "org.kde.gwenview.desktop" ];
      "image/x-xpixmap" = [ "org.kde.gwenview.desktop" ];
    };
  };
  home.file.".local/share/applications/ut2004.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=Unreal Tournament 2004
    Comment=Play Unreal Tournament 2004 with the OldUnreal patch
    TryExec=ut2004
    Exec=ut2004 -norunaway
    Icon=applications-games
    Terminal=false
    Categories=Game;ActionGame;
    StartupNotify=true
  '';
}
