# flake-parts setup: the systems this flake builds for, and the
# `flake.modules.<class>.<aspect>` option every other file under modules/
# contributes to (nixos, darwin and homeManager aspects).
{ inputs, ... }:
{
  imports = [ inputs.flake-parts.flakeModules.modules ];
  systems = [ "x86_64-linux" ];
}
