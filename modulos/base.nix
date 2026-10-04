{ config, pkgs, vars, ... }:
{
  # Usuario principal
  users.mutableUsers = true;
  security.sudo.wheelNeedsPassword = true;
  security.sudo.execWheelOnly = true;
  users.users.${vars.usuario} = {
    isNormalUser = true;
    description = "Alan Eduardo";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [ ];
  };

  # Esto es de ideapad, sigo viendo como separarlo en un módulo aparte
  imports =[../host/hardware-configuration.nix];

  # Disco cifrado con LUKS
  boot.initrd.luks.devices."luks-573cb347-ee82-4ace-a8cc-ab3414216ca1".device = "/dev/disk/by-uuid/573cb347-ee82-4ace-a8cc-ab3414216ca1";
  

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.editor = false;
  boot.loader.timeout = 3;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.systemd-boot.configurationLimit = 10;
  boot.tmp.cleanOnBoot = true;

  # Plymouth
  boot.plymouth.enable = true;
  boot.consoleLogLevel = 3;
  boot.initrd.verbose = false;
  boot.kernelParams = [ "quiet" "rd.udev.log_level=3" "rd.systemd.show_status=auto" ];

  # Red
  networking.hostName = vars.hostname;
  networking.networkmanager.enable = true;
  networking.firewall.enable = true;
  networking.firewall.logRefusedConnections = false;
  networking.firewall.allowedTCPPorts = [ 6767 ];

  # Kernel
  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.kernel.sysctl = {
    "net.ipv4.conf.all.rp_filter" = 1;
    "net.ipv4.conf.default.rp_filter" = 1;
    "net.ipv4.tcp_syncookies" = 1;
    "net.ipv4.conf.all.accept_redirects" = 0;
    "net.ipv6.conf.all.accept_redirects" = 0;
    "kernel.kptr_restrict" = 2;
    "kernel.dmesg_restrict" = 1;
    "kernel.yama.ptrace_scope" = 1;
  };

  # Apps base
  nixpkgs.config.allowUnfree = true;
  environment.systemPackages = with pkgs; [
    git vim htop btop rsync wget curl tree tmux fastfetch unzip unrar ffmpeg
  ];

  # Internacionalización
  time.timeZone = "America/Mexico_City";
  i18n.defaultLocale = "es_MX.UTF-8";
  console.keyMap = "la-latin1";
  services.xserver.xkb = {
    layout = "latam";
    variant = "";
  };

  # zram como swap
  zramSwap = {
    enable = true;
    memoryMax = 4 * 1024 * 1024 * 1024;
  };

  # Nix / flakes
  nix.settings.auto-optimise-store = true;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };
  system.autoUpgrade = {
    enable = true;
    dates = "03:00";
    randomizedDelaySec = "45min";
    allowReboot = false;
    flake = "/etc/nixos#" + vars.hostname;
    flags = [ "--print-build-logs" "--update-input" "nixpkgs" ];
  };

  # nix-ld
  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [ ];
  };

  # Audio (pipewire)
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Podman
  virtualisation.containers.enable = true;
  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
    defaultNetwork.settings.dns_enabled = true;
  };

  # oomd
  systemd.oomd.enable = true;
  systemd.oomd.enableRootSlice = true;
  systemd.oomd.enableUserSlices = true;

  # direnv
  programs.direnv.enable = true;

  # fstrim
  services.fstrim.enable = true;

  # Auditoría
  security.audit.enable = true;
  security.auditd.enable = true;

  # AppArmor
  security.apparmor = {
    enable = true;
    killUnconfinedConfinables = false;
  };

  system.stateVersion = "26.05"; # ¿Leíste el comentario?
}
