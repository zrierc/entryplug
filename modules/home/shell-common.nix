{ pkgs, lib, config, ... }:

let
  # declared once for both shells: bash and zsh
  historySize = 8000;

  shared = {
    g = "git";
    gl = "git pull";
    gd = "git diff";
    gp = "git push";
    gf = "git fetch";

    ll = "ls -alF";
    la = "ls -A";
    l = "ls -CF";

    cat = "bat";
    k = "kubectl";
    please = "sudo";
    svi = "sudo vi";

    # the tmux project picker; agents forced-overrides it to the herdr one
    ts = "tmux-sessionizer";
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
  # bat comes from the headless layer; without that module the alias below would
  # point at a binary nobody installs
  assertions = [
    {
      assertion = config.programs.bat.enable;
      message = "shell-common aliases cat to bat, but programs.bat is not enabled in this profile";
    }
  ];

  programs.bash.shellAliases = lib.mkIf pkgs.stdenv.hostPlatform.isLinux linux;
  programs.zsh.shellAliases = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin darwin;

  programs.bash.historySize = historySize;
  programs.bash.historyFileSize = historySize;
  programs.zsh.history.size = historySize;
  programs.zsh.history.save = historySize;

  programs.bash.bashrcExtra = lib.mkIf pkgs.stdenv.hostPlatform.isLinux bashCompletions;
  programs.zsh.initContent = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin (completions "zsh");
}
