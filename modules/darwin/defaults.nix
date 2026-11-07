# Values mirror the live Mac preferences. Do not add a key whose current value
# is unset without checking the GUI first: writing the key can change behavior.
{ host, ... }:

{
  system.defaults = {
    dock = {
      autohide = true;
      tilesize = 56;
      mineffect = "scale";
      launchanim = false;
      show-recents = false;
      expose-group-apps = false;
    };

    finder = {
      ShowPathbar = true;
      ShowStatusBar = true;
      FXPreferredViewStyle = "Nlsv";
      _FXSortFoldersFirst = true;
      FXDefaultSearchScope = "SCcf";
      FXRemoveOldTrashItems = true;
      ShowHardDrivesOnDesktop = false;
      ShowExternalHardDrivesOnDesktop = false;
      ShowRemovableMediaOnDesktop = false;
      ShowMountedServersOnDesktop = false;
    };

    NSGlobalDomain = {
      AppleInterfaceStyle = "Dark";
      AppleScrollerPagingBehavior = true;
    };

    trackpad = {
      Clicking = true;
      TrackpadThreeFingerDrag = true;
    };

    screencapture.location = "${host.home}/Pictures/Screenshots";

    WindowManager = {
      EnableTiledWindowMargins = true;
      StandardHideDesktopIcons = true;
    };
  };

  security.pam.services.sudo_local.touchIdAuth = true;
}
