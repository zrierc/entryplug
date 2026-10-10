# pi + current extensions. settings.json is declared here; the activation step
# runs `pi update --extensions`, which installs packages under ~/.pi/agent/npm
# and never rewrites settings.json (verified against the pi bundle).
{ pkgs, lib, inputs, ... }:

let
  pi = inputs.pi.packages.${pkgs.stdenv.hostPlatform.system}.pi;

  settings = {
    packages = [
      "npm:pi-commandcode-provider"
      "npm:@juicesharp/rpiv-todo"
      "npm:@juicesharp/rpiv-ask-user-question"
      "npm:pi-subagents"
      "npm:@aliou/pi-guardrails"
      "npm:@dietrichgebert/ponytail"
      "npm:pi-web-access"
    ];
    markdown.mermaid = "streaming";
    tuiMode = "fullscreen";
    theme = "dark";
    hideThinkingBlock = false;
    defaultProvider = "commandcode";
    defaultModel = "deepseek/deepseek-v4.1-flash";
    defaultThinkingLevel = "max";
    retry = {
      enabled = true;
      maxRetries = 3;
      baseDelayMs = 2000;
      provider = {
        timeoutMs = 1800000;
        maxRetries = 0;
        maxRetryDelayMs = 60000;
      };
    };
  };

  coreutils = pkgs.coreutils;
in

{
  home.packages = [ pi ];

  home.file.".pi/agent/settings.json".text = builtins.toJSON settings;

  home.file.".pi/agent/extensions/commandcode-transient-403-retry.ts".source =
    ./extensions/commandcode-transient-403-retry.ts;

  home.file.".pi/agent/extensions/no-terminal-title.ts".source =
    ./extensions/no-terminal-title.ts;

  # The guardrails extension rewrites this file itself, so copy it once instead
  # of symlinking it into the read-only store.
  home.activation.piGuardrails = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ ! -e "$HOME/.pi/agent/extensions/guardrails.json" ]; then
      ${coreutils}/bin/install -m 0644 ${./guardrails.json} \
        "$HOME/.pi/agent/extensions/guardrails.json"
    fi
  '';

  # Best-effort: an offline switch must not fail because npm cannot be reached.
  home.activation.piSync = lib.hm.dag.entryAfter [ "piGuardrails" ] ''
    if command -v pi >/dev/null 2>&1; then
      ${pi}/bin/pi update --extensions \
        || echo "entry-plug: 'pi update --extensions' failed; run it again when online" >&2
    fi
  '';
}
