{ config, pkgs, vars, ... }:
{  
  # Cuenta de usuario.
  users.mutableUsers = true;
  security.sudo.wheelNeedsPassword = true;
  security.sudo.execWheelOnly = true;
  users.users."alan" = {
    isNormalUser = true;
    description = "Alan Eduardo";
    extraGroups = [ "networkmanager" "wheel" "input"];
    packages = with pkgs; [
      # Paquetes para el usuario "alan"
    ];
  };

  imports =[../hosts/fiduardo/hardware-configuration.nix];

  # Bootloader
  boot.initrd.luks.devices."luks-573cb347-ee82-4ace-a8cc-ab3414216ca1".device = "/dev/disk/by-uuid/573cb347-ee82-4ace-a8cc-ab3414216ca1";
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.editor = false;
  boot.loader.timeout = 3;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.systemd-boot.configurationLimit = 10;
  boot.tmp.cleanOnBoot = true;

  # Plymouth, GUI para la contraseña del disco
  boot = {
    plymouth.enable = true;
    consoleLogLevel = 3;
    initrd.verbose = false;
    kernelParams = [
      "quiet"
      "rd.udev.log_level=3"
      "rd.systemd.show_status=auto"
    ];
  };

  # Internet
  networking.hostName = "fiduardo"; 
  networking.networkmanager.enable = true;
  networking.firewall.enable = true;
  networking.firewall.logRefusedConnections = false;

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
    "kernel.yama.ptrace_scope" = 2;
    "kernel.unprivileged_userns_clone" = 1;
  };

  # Apps:
  nixpkgs.config.allowUnfree = true;
  environment.systemPackages = with pkgs; [
    git
    vim
    htop
    btop
    rsync
    wget
    curl
    tree
    tmux
    fastfetch    
    unzip
    unrar
    ffmpeg
  ];

  # Propiedades de internalización (keymap).
  time.timeZone = "America/Mexico_City";
  i18n.defaultLocale = "es_MX.UTF-8";
  console.keyMap = "la-latin1";
  services.xserver.xkb = {
    layout = "latam";
    variant = "";
  };

  # zramSwap
  swapDevices = [ { device = "/swapfile"; size = 2048; } ];
  zramSwap = {
    enable = true;
    memoryMax = 4 * 1024 * 1024 * 1024;
  };

  nix.settings.auto-optimise-store = true;
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
    flags = [ "--print-build-logs" ];
  }; 

  # Flakes y mrds
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # ld
  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      # se van agregando aquí según lo que te vaya faltando
      
    ];
  };

  # Habilita sonido con pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Podman
  # Enable common container config files in /etc/containers
  virtualisation.containers.enable = true;
  virtualisation = {
    podman = {
      enable = true;
      dockerCompat = true;
      defaultNetwork.settings.dns_enabled = true;
    };
  };

  # oomd: Out Of Memory Daemon, para mejorar la gestión de memoria y evitar que el sistema se quede sin memoria.
  systemd.oomd.enable = true;
  systemd.oomd.enableRootSlice = true;
  systemd.oomd.enableUserSlices = true;
  powerManagement.cpuFreqGovernor = "schedutil";

  # Direnv
  programs.direnv.enable = true;

  # fstrim: para mantener el sistema de archivos optimizado y mejorar el rendimiento del almacenamiento.
  services.fstrim.enable = true;
  
  # Auditorias de seguridad: para monitorear y registrar eventos de seguridad en el sistema.
  security.audit.enable = true;
  security.auditd.enable = true;

  # AppArmor: para mejorar la seguridad del sistema mediante el control de acceso a aplicaciones y procesos.
  security.apparmor = {
    enable = true;
    killUnconfinedConfinables = false;
  };

  # NUNCA cambiar:
  system.stateVersion = "26.05"; # ¿Leíste el comentario?
}
