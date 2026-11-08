# Neovim's LazyVim config (home/nvim), on every platform. The editor itself
# comes from the system (erebor) or Homebrew (the Mac).
{
  flake.modules.homeManager.nvim = {
    xdg.configFile."nvim".source = ../../home/nvim;
  };
}
