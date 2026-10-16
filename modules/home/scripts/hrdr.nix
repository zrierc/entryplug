# herdr's companion scripts. herdr and nvim only exist in the agents profile
{ pkgs, inputs, ... }:

let
  herdr = inputs.herdr.packages.${pkgs.stdenv.hostPlatform.system}.default;
in

{
  home.packages = [
    (pkgs.writeShellApplication {
      name = "hrdr-sessionizer";
      runtimeInputs = [ pkgs.coreutils pkgs.fd pkgs.fzf pkgs.jq herdr ];
      text = ''
        if [ "$#" -gt 1 ]; then
          echo "usage: hrdr-sessionizer [dir-name|session-name]" >&2
          exit 1
        fi

        # HERDR_ENV is set in pane processes (popup and pane commands included),
        # HERDR_SOCKET_PATH in every custom command herdr spawns; both mean a
        # server is already known and the unit of work is a workspace. Outside
        # both, the unit is a session and attach starts it.
        if [ "''${HERDR_ENV:-}" = 1 ] || [ -n "''${HERDR_SOCKET_PATH:-}" ]; then
          if ! workspaces=$(herdr workspace list 2>/dev/null); then
            echo "hrdr-sessionizer: herdr's server is not running" >&2
            exit 1
          fi

          if [ "$#" -eq 1 ]; then
            pick=$(cd -- "$1" 2>/dev/null && pwd) || {
              echo "hrdr-sessionizer: cannot cd to '$1'" >&2
              exit 1
            }
          else
            pick=$(
              {
                fd --type d --min-depth 1 --max-depth 3 \
                  --exclude .git --exclude node_modules --exclude .venv --exclude build-sources \
                  . "$HOME/Dev" 2>/dev/null || true
                fd --type d --min-depth 1 --max-depth 1 . "$HOME" 2>/dev/null || true
              } | sort -u | fzf --border --layout=reverse
            ) || exit 0
            [ -n "$pick" ] || exit 0
          fi

          # a workspace carries no cwd, so its label is the path below $HOME
          label=''${pick#"$HOME"/}

          id=$(printf '%s' "$workspaces" \
            | jq -r --arg l "$label" \
                '.result.workspaces[] | select(.label == $l) | .workspace_id' | head -1)

          if [ -n "$id" ]; then
            herdr workspace focus "$id"
          else
            herdr workspace create --cwd "$pick" --label "$label" --focus
          fi
          exit 0
        fi

        # outside herdr a session is the unit; attach starts one that is stopped or missing
        if [ "$#" -eq 1 ]; then
          # herdr's validate_name rules plus no leading dash:
          # session attach takes the name positionally and has no `--`, so a dash
          # name could never attach. Refusing here keeps every argument failure
          # one line and exit 1.
          ok=1
          case $1 in
            . | .. | -* | *[!A-Za-z0-9._-]*) ok=0 ;;
            *) [ "''${#1}" -le 64 ] || ok=0 ;;
          esac
          if [ -z "$1" ] || [ "$ok" = 0 ]; then
            echo "hrdr-sessionizer: invalid session name: '$1'" >&2
            exit 1
          fi
          exec herdr session attach "$1"
        fi

        if ! sessions=$(herdr session list --json); then
          echo "hrdr-sessionizer: cannot list sessions" >&2
          exit 1
        fi

        # only a stopped session is marked; the name stays the row and attaching
        # starts a stopped one anyway
        sel=$(
          printf '%s' "$sessions" \
            | jq -r '.sessions[] | if .running then .name else "\(.name) " end' \
            | fzf --border --layout=reverse --height=~20
        ) || exit 0
        [ -n "$sel" ] || exit 0

        exec herdr session attach "''${sel%% *}"
      '';
    })

    (pkgs.writeShellApplication {
      name = "hrdr-cheat";
      runtimeInputs = [ pkgs.coreutils pkgs.curl pkgs.fzf pkgs.gnugrep pkgs.less ];
      text = ''
        topics=${../../../config/cht-languages}
        commands=${../../../config/cht-commands}

        entries=$(cat "$topics" "$commands")
        selected=$(printf '%s\n' "$entries" | fzf --border --layout=reverse) || exit 0
        [ -n "$selected" ] || exit 0

        read -r -p "Enter query: " query

        if grep -qx "$selected" "$topics"; then
          path="$selected/$(printf '%s' "$query" | tr ' ' '+')"
        else
          path="$selected~$(printf '%s' "$query" | tr ' ' '+')"
        fi

        if ! curl -fsS "https://cht.sh/$path"; then
          echo "hrdr-cheat: cht.sh is unreachable" >&2
          exit 1
        fi
      '';
    })

    (pkgs.writeShellApplication {
      name = "hrdr-todo";
      runtimeInputs = [ pkgs.coreutils pkgs.neovim ];
      text = ''
        dir=''${HERDR_ACTIVE_PANE_CWD:-$PWD}

        if [ -f "$dir/TODO.md" ]; then
          file="$dir/TODO.md"
        else
          file="$HOME/Documents/notes/todo.md"
          mkdir -p "$(dirname "$file")"
        fi

        exec nvim "$file"
      '';
    })

    (pkgs.writeShellApplication {
      name = "hrdr-windowizer";
      runtimeInputs = [ pkgs.coreutils pkgs.jq herdr ];
      text = ''
        if [ $# -lt 2 ]; then
          echo "usage: hrdr-windowizer <label> <command...>" >&2
          exit 1
        fi

        label=$(printf '%s' "$1" | tr './' '__')
        shift

        workspace=''${HERDR_ACTIVE_WORKSPACE_ID:-}
        if [ -z "$workspace" ]; then
          echo "hrdr-windowizer: not running inside a herdr pane" >&2
          exit 1
        fi

        tab=$(herdr tab list --workspace "$workspace" \
          | jq -r --arg l "$label" '.result.tabs[] | select(.label == $l) | .tab_id' | head -1)

        if [ -z "$tab" ]; then
          pane=$(herdr tab create --workspace "$workspace" --label "$label" --no-focus \
            | jq -r '.result.root_pane.pane_id')
        else
          # a tab carries no pane reference, so its pane is found through its tab_id
          pane=$(herdr pane list --workspace "$workspace" \
            | jq -r --arg t "$tab" '.result.panes[] | select(.tab_id == $t) | .pane_id' | head -1)
        fi

        if [ -z "$pane" ]; then
          echo "hrdr-windowizer: could not resolve a pane for '$label'" >&2
          exit 1
        fi

        herdr pane run "$pane" "$*"
      '';
    })
  ];
}
