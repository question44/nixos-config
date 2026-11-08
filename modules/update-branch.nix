# Weekly tested update branch (my.updateBranch.enable): a user timer runs
# scripts/erebor-update-branch, which updates nixpkgs and home-manager on
# agent/flake-update, builds erebor and runs erebor-diff. It never activates;
# the user reviews the report and lands the branch.
{
  flake.modules.nixos.update-branch =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.my.updateBranch;
      script = pkgs.writeShellApplication {
        name = "erebor-update-branch";
        runtimeInputs = with pkgs; [
          bash # erebor-rebuild and erebor-diff run through env bash
          coreutils
          diffutils
          findutils
          gnugrep
          gnused
          git
          jq
          libnotify
          util-linux # flock, for erebor-rebuild
          config.system.build.nixos-rebuild
        ];
        text = builtins.readFile ../scripts/erebor-update-branch;
      };
    in
    {
      options.my.updateBranch = {
        enable = lib.mkEnableOption "a weekly user timer that prepares a tested flake update branch";
        onCalendar = lib.mkOption {
          type = lib.types.str;
          default = "Sun 03:00";
          description = "systemd OnCalendar expression for the run.";
        };
      };

      config = lib.mkIf cfg.enable {
        systemd.user.services.erebor-update-branch = {
          description = "Prepare a tested flake update on agent/flake-update";
          # nix comes from the system profile so the daemon's version is used.
          path = [ config.nix.package ];
          environment.EREBOR_REPO = config.my.flakePath;
          serviceConfig = {
            Type = "oneshot";
            ExecStart = lib.getExe script;
            Nice = 19;
            IOSchedulingClass = "idle";
            CPUSchedulingPolicy = "idle";
          };
          # Only for the main user; other accounts have no checkout.
          unitConfig.ConditionUser = config.my.user.name;
        };
        systemd.user.timers.erebor-update-branch = {
          description = "Weekly tested flake update branch";
          wantedBy = [ "timers.target" ];
          timerConfig = {
            OnCalendar = cfg.onCalendar;
            Persistent = true;
            RandomizedDelaySec = "30min";
          };
        };
      };
    };
}
