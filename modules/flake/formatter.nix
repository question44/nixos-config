# `nix fmt` and the format check run by `nix flake check`.
{
  perSystem =
    { pkgs, ... }:
    let
      inherit (pkgs) lib;
      root = ../..;
      # Every .nix file the repo formats; the dashboard submodule is its own repo.
      nixFiles = lib.fileset.difference (lib.fileset.fileFilter (f: f.hasExt "nix") root) (
        root + "/apps"
      );
    in
    {
      # `nix fmt` formats the whole repo, or only the files given.
      formatter = pkgs.writeShellScriptBin "erebor-fmt" ''
        if [ "$#" -eq 0 ]; then
          cd "$(${pkgs.git}/bin/git rev-parse --show-toplevel)"
          ${pkgs.git}/bin/git ls-files -z -- '*.nix' ':!:apps/**' \
            | ${pkgs.findutils}/bin/xargs -0 ${pkgs.nixfmt}/bin/nixfmt
        else
          exec ${pkgs.nixfmt}/bin/nixfmt "$@"
        fi
      '';

      # Rebuilds only when a .nix file changes.
      checks.format =
        pkgs.runCommand "erebor-format-check"
          {
            src = lib.fileset.toSource {
              inherit root;
              fileset = nixFiles;
            };
          }
          ''
            cd "$src"
            find . -name '*.nix' -print0 | xargs -0 ${pkgs.nixfmt}/bin/nixfmt --check
            touch "$out"
          '';
    };
}
