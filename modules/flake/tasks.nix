# Task files under tasks/ (tasks/README.md) and the erebor-tasks tests, run by
# `nix flake check`.
{
  perSystem =
    { pkgs, ... }:
    let
      inherit (pkgs) lib;
      root = ../..;
    in
    {
      checks.tasks =
        pkgs.runCommand "erebor-tasks-check"
          {
            src = lib.fileset.toSource {
              inherit root;
              fileset = lib.fileset.unions [
                (lib.fileset.difference (lib.fileset.fileFilter (f: f.hasExt "md") root) (root + "/apps"))
                (root + "/scripts/erebor-tasks")
                (root + "/scripts/tests")
              ];
            };
            nativeBuildInputs = [
              pkgs.python3
              pkgs.git
            ];
          }
          ''
            python3 "$src/scripts/erebor-tasks" check "$src"
            # The tests create throwaway git repositories.
            export HOME=$TMPDIR
            python3 -m unittest discover -s "$src/scripts/tests"
            touch "$out"
          '';
    };
}
