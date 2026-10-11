# Neovim is the editor in this profile. Its config is a LazyVim tree kept in
# config/nvim and linked read-only out of the store, so neither lazy.nvim nor
# LazyVim can write lazy-lock.json or lazyvim.json next to init.lua. Both of
# those paths are repointed at stdpath("data") in config/nvim/init.lua and
# config/nvim/lua/config/lazy.lua.
{ ... }:

{
  home.file = {
    ".config/nvim/init.lua".source = ../../config/nvim/init.lua;
    ".config/nvim/lua".source = ../../config/nvim/lua;
    ".config/nvim/stylua.toml".source = ../../config/nvim/stylua.toml;
    ".config/nvim/.neoconf.json".source = ../../config/nvim/.neoconf.json;
  };
}
