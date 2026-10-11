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

  # guarded: kubectl may be missing, docker/orb come from OrbStack
  completions = shell: ''
    if command -v kubectl >/dev/null; then
      source <(kubectl completion ${shell})
      ${lib.optionalString (shell == "bash") "complete -F __start_kubectl k"}
    fi
    if command -v docker >/dev/null; then
      source <(docker completion ${shell} 2>/dev/null) || true
    fi
    if command -v orb >/dev/null; then
      source <(orb completion ${shell} 2>/dev/null) || true
    fi
    if command -v orbctl >/dev/null; then
      source <(orbctl completion ${shell} 2>/dev/null) || true
    fi
  '';

  # interactive shells only: .bashrc also runs non-interactively
  bashCompletions = ''
    if [[ $- == *i* ]]; then
    ${completions "bash"}
    fi
  '';
in

{
  programs.bash.shellAliases = lib.mkIf pkgs.stdenv.hostPlatform.isLinux linux;
  programs.zsh.shellAliases = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin darwin;

  programs.bash.bashrcExtra = lib.mkIf pkgs.stdenv.hostPlatform.isLinux bashCompletions;
  programs.zsh.initContent = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin (completions "zsh");
}
