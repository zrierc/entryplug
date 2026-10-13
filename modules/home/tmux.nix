{ pkgs, lib, ... }:

{
  # The fallback multiplexer
  programs.tmux = {
    enable = true;
    prefix = "C-a";
    baseIndex = 1;
    keyMode = "vi";
    customPaneNavigationAndResize = true;
    escapeTime = 0;
    historyLimit = 2000;
    mouse = true;

    extraConfig = ''
      set -g pane-base-index 1
      set -g renumber-windows on

      bind -n M-h previous-window
      bind -n M-l next-window

      # splits keep the working directory, which tmux's own defaults do not
      bind '"' split-window -v -c "#{pane_current_path}"
      bind % split-window -h -c "#{pane_current_path}"
    ''
    # a VM may have no clipboard tool, so the copy binding exists where pbcopy does
    + lib.optionalString pkgs.stdenv.hostPlatform.isDarwin ''
      bind -T copy-mode-vi v send-keys -X begin-selection
      bind -T copy-mode-vi y send-keys -X copy-pipe-and-cancel 'pbcopy'
    '';
  };
}
