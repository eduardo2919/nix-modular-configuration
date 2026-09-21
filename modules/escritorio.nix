{ pkgs, ... }:
{
  # Gaming / Steam
  hardware.steam-hardware.enable = true;
  hardware.xpadneo.enable = true;
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    gamescopeSession.enable = true;
    extest.enable = true;
  };

  # GNOME DE
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;
  environment.pathsToLink = [ "share/thumbnailers" ];
  services.xserver.enable = true;
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      intel-media-driver
      vpl-gpu-rt
    ];
  };

  # Flatpak
  services.flatpak = {
    enable = true;
    packages = [
      "org.fedoraproject.MediaWriter"
      "com.stremio.Stremio"
      "org.qbittorrent.qBittorrent"
    ];
  };

  # TLP
  services.power-profiles-daemon.enable = false;
  services.tlp = {
    enable = true;
    settings = {
      # CPU
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";

      CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
      CPU_ENERGY_PERF_POLICY_ON_BAT = "power";

      CPU_MIN_PERF_ON_AC = 0;
      CPU_MAX_PERF_ON_AC = 100;

      CPU_MIN_PERF_ON_BAT = 0;
      CPU_MAX_PERF_ON_BAT = 60;

      # Turbo
      CPU_BOOST_ON_AC = 1;
      CPU_BOOST_ON_BAT = 0;

      # Platform
      PLATFORM_PROFILE_ON_AC = "performance";
      PLATFORM_PROFILE_ON_BAT = "balanced";

      # Wi-Fi
      WIFI_PWR_ON_BAT = "on";

      # Battery charge limits
      START_CHARGE_THRESH_BAT0 = 40;
      STOP_CHARGE_THRESH_BAT0 = 80;
    };
  };

  # localSend: para compartir archivos de manera segura y rápida en la red local.
  programs.localsend.enable = true;
}
