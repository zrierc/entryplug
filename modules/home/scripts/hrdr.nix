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
        if ! workspaces=$(herdr workspace list 2>/dev/null); then
          echo "hrdr-sessionizer: herdr's server is not running" >&2
          exit 1
        fi

        pick=$(
          {
            fd --type d --min-depth 1 --max-depth 3 \
              --exclude .git --exclude node_modules --exclude .venv --exclude build-sources \
              . "$HOME/Dev" 2>/dev/null || true
            fd --type d --min-depth 1 --max-depth 1 . "$HOME" 2>/dev/null || true
          } | sort -u | fzf --border --layout=reverse
        ) || exit 0
        [ -n "$pick" ] || exit 0

        # a workspace carries no cwd, so its label is the path below $HOME
        label=$(printf '%s' "$pick" | sed "s|^$HOME/||")

        id=$(printf '%s' "$workspaces" \
          | jq -r --arg l "$label" \
              '.result.workspaces[] | select(.label == $l) | .workspace_id' | head -1)

        if [ -n "$id" ]; then
          herdr workspace focus "$id"
        else
          herdr workspace create --cwd "$pick" --label "$label" --focus
        fi
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
