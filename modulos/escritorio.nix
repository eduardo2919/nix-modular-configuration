{ config, pkgs, lib, vars, ... }:
lib.mkMerge [
  # Lo común a cualquier sesión gráfica
  (lib.mkIf (vars.entornoEscritorio != null) {
    hardware.graphics = {
      enable = true;
      enable32Bit = true;
      extraPackages = with pkgs; [ intel-media-driver vpl-gpu-rt ];
    };
    environment.pathsToLink = [ "share/thumbnailers" ];

    services.flatpak = {
      enable = true;
      packages = [
        "org.fedoraproject.MediaWriter"
        "com.stremio.Stremio"
        "org.qbittorrent.qBittorrent"
      ];
    };

    # VPN (daemon a nivel de sistema, no solo el paquete)
    services.mullvad-vpn = {
      enable = true;
      package = pkgs.mullvad-vpn;
    };
    services.resolved.enable = true;
    networking.firewall.checkReversePath = "loose";

    # Compartir archivos en la red local
    programs.localsend.enable = true;
  })

  # GNOME
  (lib.mkIf (vars.entornoEscritorio == "gnome") {
    services.xserver.enable = true;
    services.displayManager.gdm.enable = true;
    services.desktopManager.gnome.enable = true;
  })

  # XFCE
  (lib.mkIf (vars.entornoEscritorio == "xfce") {
    services.xserver.enable = true;
    services.xserver.desktopManager.xfce.enable = true;
    services.xserver.displayManager.lightdm.enable = true;
  })

  # Laptop: TLP y umbrales de batería
  (lib.mkIf vars.esLaptop {
    services.power-profiles-daemon.enable = false;
    services.tlp = {
      enable = true;
      settings = {
        CPU_SCALING_GOVERNOR_ON_AC = "performance";
        CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
        CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
        CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
        CPU_MIN_PERF_ON_AC = 0;
        CPU_MAX_PERF_ON_AC = 100;
        CPU_MIN_PERF_ON_BAT = 0;
        CPU_MAX_PERF_ON_BAT = 60;
        CPU_BOOST_ON_AC = 1;
        CPU_BOOST_ON_BAT = 0;
        PLATFORM_PROFILE_ON_AC = "performance";
        PLATFORM_PROFILE_ON_BAT = "balanced";
        WIFI_PWR_ON_BAT = "on";
        START_CHARGE_THRESH_BAT0 = 40;
        STOP_CHARGE_THRESH_BAT0 = 80;
      };
    };
  })

  # Gaming: Steam + hardware de controles
  (lib.mkIf vars.gaming {
    hardware.steam-hardware.enable = true;
    hardware.xpadneo.enable = true;
    programs.steam = {
      enable = true;
      remotePlay.openFirewall = true;
      gamescopeSession.enable = true;
      extest.enable = true;
    };
  })

  # Apps de Android vía Waydroid
  (lib.mkIf vars.androidApps {
    virtualisation.waydroid.enable = true;
    virtualisation.waydroid.package = pkgs.waydroid-nftables;
    environment.systemPackages = with pkgs; [ wl-clipboard waydroid-helper android-tools ];
    systemd.packages = [ pkgs.waydroid-helper ];
    systemd.services.waydroid-mount.wantedBy = [ "multi-user.target" ];
    systemd.user.services.waydroid-monitor.wantedBy = [ "graphical-session.target" ];
  })
]
