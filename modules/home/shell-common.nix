# Aliases and completions shared by both shells, so bash and zsh cannot drift.
{ pkgs, lib, ... }:

let
  shared = {
    ll = "ls -alF";
    la = "ls -A";
    l = "ls -CF";
    cat = "bat --color=auto --decorations=never --paging=never";
    k = "kubectl";
  };

  linux = shared // {
    ls = "ls --color=auto";
    grep = "grep --color=auto";
  };

  darwin = shared // {
    ls = "ls -G";
  };
in

{
  programs.bash.shellAliases = lib.mkIf pkgs.stdenv.hostPlatform.isLinux linux;
  programs.zsh.shellAliases = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin darwin;

  programs.bash.bashrcExtra = lib.mkIf pkgs.stdenv.hostPlatform.isLinux ''
    if command -v kubectl >/dev/null; then
      source <(kubectl completion bash)
    fi
    complete -F __start_kubectl k
  '';

  programs.zsh.initContent = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin ''
    if command -v kubectl >/dev/null; then
      source <(kubectl completion zsh)
    fi
  '';
}
