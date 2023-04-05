{
  config,
  pkgs,
  inputs,
  ...
}: {
  imports = [
    ./defaults.nix
    inputs.nixos-hardware.nixosModules.common-pc-ssd
  ];

  boot.kernel.sysctl = {
    "fs.inotify.max_user_watches" = 12288;
  };

  boot.kernelModules = ["v4l2loopback"];
  boot.extraModulePackages = [
    config.boot.kernelPackages.v4l2loopback.out
  ];

  boot.extraModprobeConfig = ''
    options v4l2loopback exclusive_caps=1 video_nr=9 card_label=v4l2loopback
  '';

  hardware.opengl.enable = true;
  hardware.opengl.driSupport = true;

  hardware.opengl.extraPackages = [
    pkgs.intel-media-driver
    pkgs.vaapiIntel
    pkgs.vaapiVdpau
    pkgs.libvdpau-va-gl
    pkgs.rocm-opencl-icd
    pkgs.rocm-opencl-runtime
    pkgs.amdvlk
  ];

  sound.enable = false; ## see pipewire config below
  security.rtkit.enable = true;
  hardware.bluetooth.enable = true;
  networking.wireless.iwd.enable = true;

  environment.pathsToLink = ["/etc/gconf"];

  security.pam.services.swaylock = {
    text = ''
      auth include login
    '';
  };

  powerManagement.enable = true;
  powerManagement.powertop.enable = true;

  environment.state."/keep".directories = ["/var/cache/powertop"];

  virtualisation.docker.enable = false;
  virtualisation.podman.enable = true;
  virtualisation.podman.dockerCompat = true;

  programs.ssh.startAgent = true;

  programs.dconf.enable = true;

  services.avahi.enable = true;
  services.avahi.nssmdns = true;
  services.avahi.openFirewall = true;
  services.gvfs.enable = true;
  services.gnome.sushi.enable = true;
  services.openssh.enable = true;

  services.fwupd.enable = true;

  services.printing.enable = true;
  services.printing.drivers = [pkgs.gutenprint];
  services.ipp-usb.enable = true;

  services.dbus.packages = with pkgs; [gcr dconf gnome.sushi];
  services.udev.packages = with pkgs; [gnome.gnome-settings-daemon];

  environment.etc."systemd/sleep.conf".text = "HibernateDelaySec=8h";

  services.write-iwd-secrets.enable = true;

  ## taken from NixOS wiki
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };
  xdg.portal.enable = true;
  xdg.portal.extraPortals = [pkgs.xdg-desktop-portal-wlr pkgs.xdg-desktop-portal-gtk];

  fonts.fonts = with pkgs; [
    google-fonts
    font-awesome_5
    powerline-fonts
    roboto
    mynerdfonts
    etBook
    emacs-all-the-icons-fonts
  ];

  security.wrappers.netns-exec = {
    source = "${pkgs.netns-exec}/bin/netns-exec";
    owner = "root";
    group = "root";
    setuid = true;
  };

  machinePurpose = "workstation";
}
