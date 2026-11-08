# Encrypted secrets with sops-nix. secrets/<host>.yaml is encrypted to the
# recipients in .sops.yaml (the user's age key and each host's SSH host key);
# the host decrypts at activation into /run/secrets, never into the store.
# Services declare `sops.secrets.<name>` (or `sops.templates`) next to the
# code that uses them; see the secrets skill.
{ inputs, ... }:
{
  flake.modules.nixos.secrets =
    { config, lib, ... }:
    let
      file = ../secrets + "/${config.networking.hostName}.yaml";
    in
    {
      imports = [ inputs.sops-nix.nixosModules.sops ];

      sops = {
        # Hosts without a secrets file (the template) declare no secrets.
        defaultSopsFile = lib.mkIf (builtins.pathExists file) file;
        # Decrypt with the SSH host key; no separate age key on the host.
        age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
        gnupg.sshKeyPaths = [ ];
      };
    };
}
