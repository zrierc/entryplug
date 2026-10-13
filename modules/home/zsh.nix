{ config, pkgs, lib, ... }:

lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    defaultKeymap = "emacs";

    # size and save come from shell-common.nix, which both shells read; these are
    # the parts bash has no equivalent for
    history = {
      append = true;
      share = true;
      extended = true;
      ignoreSpace = true;
      ignoreAllDups = true;
      saveNoDups = true;
      ignoreDups = true;
      findNoDups = true;
    };

    # hist_verify is superseded by magic-space below, and flowcontrol is already 
    # off in a stock zsh -- based on oh-my-zsh
    setOptions = [
      "AUTO_CD"
      "INTERACTIVE_COMMENTS"
      "MULTIOS"
      "AUTO_MENU"
      "COMPLETE_IN_WORD"
      "ALWAYS_TO_END"
      "AUTO_PUSHD"
      "PUSHD_IGNORE_DUPS"
    ];

    syntaxHighlighting.enable = true;
    autosuggestion.enable = true;
    historySubstringSearch.enable = true;

    shellGlobalAliases = {
      "..." = "../..";
      "...." = "../../..";
    };

    shellAliases = {
      godsWords10 = "godsWords 10";
      godsWords64 = "godsWords 64";
      godsWords100 = "godsWords 100";
      zcp = "zmv -C";
      zln = "zmv -L";
    };

    initContent = lib.mkMerge [
      # skipped when starship manages the prompt
      (lib.mkIf (!config.programs.starship.enable) ''
        PROMPT='%F{green}%n@%m%f:%F{blue}%~%f%# '
      '')

      # nixpkgs gives terraform a bash completion only, and bashcompinit has to
      # come after compinit, which home-manager runs at order 570
      ''
        if command -v terraform >/dev/null; then
          autoload -U +X bashcompinit && bashcompinit
          complete -o nospace -C terraform terraform
        fi
      ''

      ''
        zmodload -i zsh/complist
        WORDCHARS=""
        zstyle ':completion:*:*:*:*:*' menu select
        zstyle ':completion:*' matcher-list 'm:{[:lower:][:upper:]}={[:upper:][:lower:]}' 'r:|=*' 'l:|=* r:|=*'
        zstyle ':completion:*' special-dirs true
        zstyle ':completion:*' list-colors ""

        autoload -Uz edit-command-line
        zle -N edit-command-line
        bindkey '^X^E' edit-command-line
        bindkey '^Y' redo        # zsh has redo, unbound by default
        bindkey ' ' magic-space  # expand !! and !$ before running them

        # a macOS terminal only sends these when something binds them
        bindkey '^[[1;5C' forward-word
        bindkey '^[[1;5D' backward-word

        autoload -Uz zmv add-zsh-hook

        # direnv owns any tree with an .envrc, and its hook is registered after this
        # one, so ownership is decided by the file rather than by $DIRENV_DIR, which
        # is still unset on the cd that enters the directory
        function auto_venv() {
          [[ -n "$DIRENV_DIR" ]] && return

          # an .envrc anywhere above belongs to direnv, whichever directory holds the venv
          local probe=$PWD
          while [[ $probe != / ]]; do
            [[ -e "$probe/.envrc" ]] && return
            probe=''${probe:h}
          done

          local dir=$PWD target= candidate
          while [[ $dir != / ]]; do
            for candidate in .venv venv; do
              if [[ -r "$dir/$candidate/bin/activate" ]]; then
                target="$dir/$candidate"
                break 2
              fi
            done
            dir=''${dir:h}
          done

          # a hand-run deactivate must not leave us thinking we still own one
          [[ -z "$VIRTUAL_ENV" ]] && unset _auto_venv_active

          if [[ -n "$target" ]]; then
            [[ "$VIRTUAL_ENV" == "$target" ]] && return
            # replace a venv this hook activated, rather than stacking its PATH on top
            if [[ -n "$VIRTUAL_ENV" && -n "$_auto_venv_active" ]] && (( $+functions[deactivate] )); then
              deactivate
            fi
            source "$target/bin/activate"
            typeset -g _auto_venv_active=$target
          # only release what was activated here; a uv or handmade VIRTUAL_ENV is not ours
          elif [[ -n "$_auto_venv_active" && "$VIRTUAL_ENV" == "$_auto_venv_active" && "$PWD" != "$VIRTUAL_ENV"/* ]]; then
            (( $+functions[deactivate] )) && deactivate
            unset _auto_venv_active
          fi
        }
        add-zsh-hook chpwd auto_venv

        # macOS has no shuf; coreutils-prefixed provides this one, and the g prefix
        # keeps the rest of GNU coreutils out of the BSD tools' way
        # Taken from TempleOS -- RIP Terry A. Davis.
        function godsWords() {
          local words=/usr/share/dict/words
          [[ -r "$words" ]] || { print -u2 "godsWords: $words is not readable"; return 1 }

          if [[ -z "$1" ]]; then
            echo "$(gshuf -n 32 "$words" --random-source=/dev/urandom | tr '\n' ' ' | fold -s)"
          else
            echo "$(gshuf -n "$1" "$words" --random-source=/dev/urandom | tr '\n' ' ' | fold -w 64 -s)"
          fi
        }
      ''
    ];
  };
}
