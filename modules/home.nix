{ pkgs, lib, vars, vscodeExts, ... }:
{
  home.username = "alan";
  home.homeDirectory = "/home/alan";
  home.stateVersion = "26.05"; # NUNCA cambiar

  home.packages = with pkgs; [  
    firefox
    librewolf
    gnome-tweaks
    adwaita-icon-theme
    gnome-control-center
    croc
    jdk21
    lolcat
    fortune
    cowsay
    mullvad-vpn
    brave
    vscode
    mousepad
    
    # Apps de lenguajes especificos
    python3
    uv
    deno
    
    # Podman
    dive # inspecciona imagenes de contenedores
    podman-tui # interfaz de usuario para podman
    docker-compose # interfaz de usuario para docker-compose

    # Miniaturas
    ffmpeg-headless
    ffmpegthumbnailer
    gdk-pixbuf
    libjxl
    webp-pixbuf-loader

    # Wine / gaming
    wineWow64Packages.stable
    winetricks
    protonup-qt
    mangohud
    gamescope
    steam-run
    discord
  ];

  # Certificados ssl para herramientas instaladas mediante uv
  home.sessionVariables = {
    SSL_CERT_FILE = "/etc/ssl/certs/ca-certificates.crt";
  };
  
  # Instalación de yt-dlp y gallery-dl
    home.activation.uvToolsInstall = lib.hm.dag.entryAfter ["writeBoundary"] ''
    $DRY_RUN_CMD ${pkgs.uv}/bin/uv tool install --force yt-dlp $VERBOSE_ARG
    $DRY_RUN_CMD ${pkgs.uv}/bin/uv tool install --force gallery-dl $VERBOSE_ARG
  '';
  
  # Config de gallery-dl
  home.file.".config/gallery-dl/config.json" = {
    source = ../archivos/gallery-dl.config.json;
    executable = false;
  };

  # Descargar galeria personal con gallery
  systemd.user.services.galeria-gallery = {
    Unit.Description = "Descargar mi galeria 'personal' con gallery-dl";
    Service = {
      Type = "oneshot";
      WorkingDirectory = "/home/alan/Imágenes";
      ExecStart = "${pkgs.bash}/bin/bash /etc/nixos/archivos/galeria.sh";
    };
  };

  # Su temporizador
  systemd.user.timers.galeria-gallery = {
    Unit.Description = "Timer para galeria-gallery";
    Timer = {
      OnCalendar = "*-*-* 21:00:00";
      Persistent = false;
    };
    Install.WantedBy = [ "timers.target" ];
  };
  
  # Actualizar programas (python) instalados mediante uv
  systemd.user.services.uv-upgrade = {
    Unit.Description = "Actualizar todas las herramientas descargadas mediante uv";
    Service = {
      Type = "oneshot";
      ExecStart = "${pkgs.uv}/bin/uv tool upgrade --all";
      };
    };
    
  # Su temporizador
  systemd.user.timers.uv-upgrade = {
    Unit.Description = "Timer para actualizaciones de apps instaladas desde uv";
    Timer = {
      OnCalendar = "weekly";
      Persistent = true;
    };
    Install.WantedBy = [ "timers.target" ];
  };
  
  # Vscode kike extension
  programs.vscode = {
    enable = true;
    profiles.default.extensions = with vscodeExts; [
      rangav.vscode-thunder-client
      ];
  };
}
