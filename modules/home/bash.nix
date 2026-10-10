{ pkgs, lib, ... }:

lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
  programs.bash = {
    enable = true;
    enableCompletion = true;

    historyControl = [ "ignoreboth" ];
    historySize = 1000;
    historyFileSize = 2000;

    shellOptions = [
      "histappend"
      "checkwinsize"
    ];

    bashrcExtra = ''
      # fancy prompt with color support
      case "$TERM" in
      xterm-color | *-256color) color_prompt=yes ;;
      esac

      if [ -x "$(command -v tput)" ] && tput setaf 1 >&/dev/null; then
        color_prompt=yes
      else
        color_prompt=
      fi

      if [ "$color_prompt" = yes ]; then
        PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
      else
        PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
      fi
      unset color_prompt

      # xterm title: user@host:dir
      case "$TERM" in
      xterm* | rxvt*)
        PS1="\[\e]0;\u@\h: \w\a\]$PS1"
        ;;
      *) ;;
      esac

      # optional per-VM aliases
      if [ -f ~/.bash_aliases ]; then
        . ~/.bash_aliases
      fi

      # optional company environment (if present on the VM)
      if [ -f /etc/profile.d/cloudops.sh ]; then
        . /etc/profile.d/cloudops.sh
      fi
    '';
  };
}
