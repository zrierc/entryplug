{
  inputs,
  host,
  homeModule,
  pkgs,
  ...
}:

{
  # unit-314's /etc/nixos says never to change this; 26.11 is what the device was installed with
  system.stateVersion = "26.11";

  # needed to run `nixos-rebuild --flake` on the device itself
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # explicit even though nixos-hardware's raspberry-pi-4 module mkDefaults the same values
  boot.loader = {
    grub.enable = false;
    generic-extlinux-compatible.enable = true;
  };

  hardware.enableRedistributableFirmware = true;

  systemd.defaultUnit = "multi-user.target";

  time.timeZone = "Asia/Jakarta";

  networking = {
    hostName = host.hostname;
    networkmanager.enable = true;

    firewall = {
      enable = true;
      allowPing = true;
      trustedInterfaces = [ "tailscale0" ];
    };
  };

  services = {
    # headless: the device config sets this, so keep it explicit rather than inherited
    xserver.enable = false;

    openssh = {
      enable = true;
      ports = [ 666 ];
      openFirewall = true;
      settings = {
        PermitRootLogin = "no";
        PasswordAuthentication = false;
      };
    };

    avahi = {
      enable = true;
      nssmdns4 = true;
      # nixpkgs defaults this true and would add 5353/udp; the firewall is the operator's call
      openFirewall = true;
      # `services.avahi.publish.{enable,addresses}` are obsolete at this nixpkgs rev;
      # these are the same avahi-daemon.conf settings the device has
      settings.publish = {
        "disable-publishing" = false;
        "publish-addresses" = true;
      };
    };

    tailscale = {
      enable = true;
      extraSetFlags = [ "--operator=${host.primaryUser}" ];
      openFirewall = true;
    };
  };

  security.sudo.wheelNeedsPassword = false;

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICsTpq50T1yvwnlHcuyPx28wZmlz6NSX+5nzAV/9qRbi zrie@unit-05"
  ];

  # home-manager takes home.username/home.homeDirectory from users.users.<name>
  users.users.${host.primaryUser} = {
    isNormalUser = true;
    home = host.home;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICsTpq50T1yvwnlHcuyPx28wZmlz6NSX+5nzAV/9qRbi zrie@unit-05"
    ];
    packages = with pkgs; [
      tree
      vim
    ];
  };

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = {
      inherit inputs host;
      devRoot = host.devRoot;
    };
    users.${host.primaryUser}.imports = [
      ../home/base.nix
      (import homeModule)
    ];
  };
}
