# Menu bar keys live in user defaults, and control center keys are split between
# the normal and ByHost domains. Values mirror the live Mac preferences.
{ pkgs, lib, ... }:

lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
  targets.darwin.defaults = {
    NSGlobalDomain = {
      NSGlassDiffusionSetting = true;
      SLSMenuBarUseBlurredAppearance = true;
    };

    "com.apple.controlcenter" = {
      "NSStatusItem VisibleCC WiFi" = true;
      "NSStatusItem VisibleCC Bluetooth" = true;
      "NSStatusItem VisibleCC Battery" = true;
    };
  };

  targets.darwin.currentHostDefaults."com.apple.controlcenter" = {
    BatteryShowPercentage = true;
    Bluetooth = 2;
    FocusModes = 8;
    Timer = 2;
  };
}
