# Fish, Starship and command-line tools.
{ lib, pkgs, ... }:
{
  xdg.configFile."fish/functions/shell_welcome.fish".source = pkgs.replaceVars ../fish/shell_welcome.fish { figlet = pkgs.figlet; };
  xdg.configFile."fastfetch/shell.jsonc".source = ../fastfetch/shell.jsonc;
  programs.bat.enable = true;
  programs.fish = {
    enable = true;
    functions.fish_greeting.body = "printf '\\n'; shell_welcome; printf '\\n'";
    functions.imgs = {
      description = "Preview images (default: all in current directory) with filenames";
      body = ''
        set -l files $argv
        test (count $files) -eq 0; and set files *.{png,jpg,jpeg,gif,webp,bmp,svg}
        for f in $files
          test -f $f; or continue
          set_color --bold; echo $f; set_color normal
          chafa --format=sixel --size=60x20 --animate=off $f
        end
      '';
    };
    shellAliases = {
      cat = "bat --style=plain --paging=never";
      catn = "bat --style=numbers --paging=never";
      t3pair = "t3 pair --base-dir /home/janzon/.t3/server";
      ls = "eza --group-directories-first --icons=auto";
      ll = "eza --long --header --group-directories-first --icons=auto";
      la = "eza --all --group-directories-first --icons=auto";
      lla = "eza --long --all --header --group-directories-first --icons=auto";
      lt = "eza --tree --level=2 --group-directories-first --icons=auto";
      # Inline image previews (sixel; works in the ttyd browser terminal).
      img = "chafa --format=sixel";

      # Common Oh My Zsh Git shortcuts, available in Fish.
      g = "git";
      gst = "git status";
      gss = "git status --short";
      gsb = "git status --short --branch";
      ga = "git add";
      gaa = "git add --all";
      gapa = "git add --patch";
      gau = "git add --update";
      gd = "git diff";
      gdca = "git diff --cached";
      gds = "git diff --staged";
      gdw = "git diff --word-diff";
      gc = "git commit --verbose";
      gcmsg = "git commit --message";
      gcam = "git commit --all --message";
      gcfu = "git commit --fixup";
      gb = "git branch";
      gba = "git branch --all";
      gbd = "git branch --delete";
      gco = "git checkout";
      gcb = "git checkout -b";
      gsw = "git switch";
      gswc = "git switch --create";
      gf = "git fetch";
      gfo = "git fetch origin";
      gl = "git pull";
      gpr = "git pull --rebase";
      gp = "git push";
      gcl = "git clone --recurse-submodules";
      glo = "git log --oneline --decorate";
      glog = "git log --oneline --decorate --graph";
      gloga = "git log --oneline --decorate --graph --all";
      gm = "git merge";
      grb = "git rebase";
      grbi = "git rebase --interactive";
      grbc = "git rebase --continue";
      grba = "git rebase --abort";
      gsta = "git stash push";
      gstl = "git stash list";
      gstp = "git stash pop";
      gsts = "git stash show --patch";
    };
  };
  programs.starship = {
    enable = true;
    enableFishIntegration = true;
  };
  home.activation.starshipNoctaliaConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    base="$HOME/.config/noctalia/starship-base.toml"
    palette="$HOME/.cache/noctalia/starship-palette.toml"
    target="$HOME/.config/noctalia/starship.toml"
    run ${pkgs.coreutils}/bin/mkdir -p "$(dirname "$target")"
    if [ -f "$palette" ] && [ ! -v DRY_RUN ]; then
      temporary="$(${pkgs.coreutils}/bin/mktemp "$(dirname "$target")/.starship.toml.XXXXXX")"
      {
        ${pkgs.gawk}/bin/awk '
          $0 == "# >>> NOCTALIA STARSHIP PALETTE >>>" { skip = 1; next }
          skip && $0 == "# <<< NOCTALIA STARSHIP PALETTE <<<" { skip = 0; next }
          !skip { print }
        ' "$base"
        printf '\n# >>> NOCTALIA STARSHIP PALETTE >>>\n'
        ${pkgs.coreutils}/bin/cat "$palette"
        printf '# <<< NOCTALIA STARSHIP PALETTE <<<\n'
      } >"$temporary"
      if ! ${pkgs.diffutils}/bin/cmp -s "$temporary" "$target" 2>/dev/null; then
        ${pkgs.coreutils}/bin/mv "$temporary" "$target"
      else
        ${pkgs.coreutils}/bin/rm "$temporary"
      fi
    elif [ ! -f "$palette" ] && [ ! -e "$target" ]; then
      run ${pkgs.coreutils}/bin/cp "$base" "$target"
    fi
  '';
  xdg.configFile."noctalia/starship-base.toml".source = ../starship.toml;
}
