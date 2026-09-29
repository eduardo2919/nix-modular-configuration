{ config, pkgs, vars, ... }:
{
  # Cuenta de usuario.
  users.mutableUsers = true;
  security.sudo.wheelNeedsPassword = true;
  security.sudo.execWheelOnly = true;
  users.users."alan" = {
    isNormalUser = true;
    description = "Alan Eduardo";
    # Quité "input": ese grupo puede leer /dev/input/* (todos los teclados
    # y ratones del sistema), no hace falta para uso normal.
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [
      # Paquetes para el usuario "alan"
    ];
  };

  # Bootloader
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
    # 2 bloquea gdb/strace incluso para procesos propios; 1 (el default de
    # Yama) ya evita que un proceso normal escanee la memoria de otro.
    "kernel.yama.ptrace_scope" = 1;
  };
  # "kernel.unprivileged_userns_clone" no existe en el kernel mainline
  # (es un parche de Debian/Zen); en NixOS lo controla
  # security.unprivilegedUsernsClone, que ya viene en true por omisión.

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
    # Sin "flake" intenta usar canales, que este sistema no tiene, y falla.
    # Apunta al propio /etc/nixos (mismo repo que ya usas para el switch manual).
    flake = "/etc/nixos#" + vars.hostname;
    # --update-input está deprecado mas sigue funcionando: solo avisa.
    flags = [ "--print-build-logs" "--update-input" "nixpkgs" ];
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
  # cpuFreqGovernor se quitó de aquí: en el escritorio TLP ya lo pisa, y en
  # intel_pstate (que es tu driver) "schedutil" ni siquiera es un gobernador
  # disponible. Si algún host lo necesita, decláralo en su propio módulo.

  # Direnv
  programs.direnv.enable = true;

  # fstrim: para mantener el sistema de archivos optimizado y mejorar el rendimiento del almacenamiento.
  services.fstrim.enable = true;

  # Auditorias de seguridad: para monitorear y registrar eventos de seguridad en el sistema.
  security.audit.enable = true;
  security.auditd.enable = true;
  # Sin reglas, security.audit no registra nada útil todavía; agrega
  # security.audit.rules cuando decidas qué syscalls/paths vigilar.

  # AppArmor: para mejorar la seguridad del sistema mediante el control de acceso a aplicaciones y procesos.
  security.apparmor = {
    enable = true;
    killUnconfinedConfinables = false;
  };

  # Disko se quitó de aquí: no está en tus inputs, chocaría con
  # hardware-configuration.nix (ambos definirían fileSystems), mezclaba una
  # partición EF02/GRUB con systemd-boot, y como base.nix es común se
  # aplicaría a los dos equipos. Disko es para *instalar*: si lo quieres,
  # va en un archivo aparte por host, fuera de la config que corre a diario.

  # NUNCA cambiar:
  system.stateVersion = "26.05"; # ¿Leíste el comentario?
}
