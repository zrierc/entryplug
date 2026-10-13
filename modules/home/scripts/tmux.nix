# The tmux counterparts of the herdr helpers, in the headless layer: a machine without
# herdr still needs a project picker, a named-window runner and a cheat sheet. Same
# names unit-00 used, so the muscle memory and any hook keep working.
{ pkgs, ... }:

let
  # the project picker both multiplexers use; only the action differs
  picker = ''
    pick=$(
      {
        fd --type d --min-depth 1 --max-depth 3 \
          --exclude .git --exclude node_modules --exclude .venv --exclude build-sources \
          . "$HOME/Dev" 2>/dev/null || true
        fd --type d --min-depth 1 --max-depth 1 . "$HOME" 2>/dev/null || true
      } | sort -u | fzf --border --layout=reverse
    ) || exit 0
    [ -n "$pick" ] || exit 0
  '';
in

{
  home.packages = [
    (pkgs.writeShellApplication {
      name = "tmux-sessionizer";
      runtimeInputs = [ pkgs.coreutils pkgs.fd pkgs.fzf pkgs.tmux ];
      text = ''
        ${picker}
        session=$(basename "$pick" | tr . _)

        if [ -z "''${TMUX:-}" ] && ! pgrep tmux >/dev/null; then
          exec tmux new-session -s "$session" -c "$pick"
        fi

        if ! tmux has-session -t "$session" 2>/dev/null; then
          tmux new-session -ds "$session" -c "$pick"
        fi

        if [ -z "''${TMUX:-}" ]; then
          tmux attach -t "$session"
        else
          tmux switch-client -t "$session"
        fi
      '';
    })

    (pkgs.writeShellApplication {
      name = "tmux-windowizer";
      runtimeInputs = [ pkgs.coreutils pkgs.tmux ];
      text = ''
        if [ $# -lt 2 ]; then
          echo "usage: tmux-windowizer <label> <command...>" >&2
          exit 1
        fi

        label=$(printf '%s' "$1" | tr './' '__')
        shift
        target="$(tmux display-message -p '#S'):$label"

        if ! tmux has-session -t "$target" 2>/dev/null; then
          tmux neww -dn "$label"
        fi

        tmux send-keys -t "$target" "$*"
      '';
    })

    (pkgs.writeShellApplication {
      name = "tmux-cht.sh";
      runtimeInputs = [ pkgs.coreutils pkgs.curl pkgs.fzf pkgs.gnugrep pkgs.less pkgs.tmux ];
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

        tmux neww "curl -s 'https://cht.sh/$path' | less -R"
      '';
    })
  ];
}
