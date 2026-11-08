# Proton VPN on a bridged LAN. While connecting, the app always adds a route
# to the VPN server on every ethernet/Wi-Fi device, whatever the kill switch
# setting. It crashes on a bridge port (no IPv4 settings of its own) and never
# considers the bridge that has the gateway. The patch skips ports and counts
# bridges that have a gateway.
{
  flake.modules.nixos.proton-vpn-bridge =
    { ... }:
    {
      nixpkgs.overlays = [
        (_final: prev: {
          pythonPackagesExtensions = (prev.pythonPackagesExtensions or [ ]) ++ [
            (_pythonFinal: pythonPrev: {
              proton-vpn-api-core = pythonPrev.proton-vpn-api-core.overridePythonAttrs (old: {
                patches = (old.patches or [ ]) ++ [ ./proton-vpn-bridge.patch ];
              });
            })
          ];
        })
      ];
    };
}
