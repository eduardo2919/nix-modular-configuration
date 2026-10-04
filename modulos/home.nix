{ pkgs, lib, vars, vscodeExts, ... }:
{
  home.username = vars.usuario;
  home.homeDirectory = "/home/" + vars.usuario;
  home.stateVersion = "26.05"; # NUNCA cambiar

  # Paquetes de usuario
  home.packages = with pkgs; [
    firefox librewolf croc jdk21 lolcat fortune cowsay brave mousepad
    python3 uv deno renpy
    dive podman-tui podman-compose
    ffmpeg-headless ffmpegthumbnailer gdk-pixbuf libjxl webp-pixbuf-loader
  ]
  ++ lib.optionals (vars.entornoEscritorio == "gnome") [
    gnome-tweaks adwaita-icon-theme gnome-control-center
  ]
  ++ lib.optionals vars.gaming [
    wineWow64Packages.stable winetricks protonup-qt mangohud gamescope steam-run discord
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

  # Enlace (en activación, no declarativo) a la config personal de gallery-dl
  home.activation.linkGalleryConfig = lib.hm.dag.entryAfter ["writeBoundary"] ''
    $DRY_RUN_CMD mkdir -p $VERBOSE_ARG "$HOME/.config/gallery-dl"
    $DRY_RUN_CMD ln -sf $VERBOSE_ARG "/etc/nixos/archivos/gallery-dl.config.json" "$HOME/.config/gallery-dl/config.json"
  '';

  # Descarga diaria de la galería personal
  systemd.user.services.galeria-gallery = {
    Unit.Description = "Descargar mi galeria 'personal' con gallery-dl";
    Service = {
      Type = "oneshot";
      WorkingDirectory = "/home/${vars.usuario}/Imágenes";
      ExecStart = "${pkgs.bash}/bin/bash /etc/nixos/archivos/galeria.sh";
    };
  };
  systemd.user.timers.galeria-gallery = {
    Unit.Description = "Timer para galeria-gallery";
    Timer = {
      OnCalendar = "*-*-* 21:00:00";
      Persistent = false;
    };
    Install.WantedBy = [ "timers.target" ];
  };

  # Actualización semanal de las apps instaladas con uv
  systemd.user.services.uv-upgrade = {
    Unit.Description = "Actualizar todas las herramientas descargadas mediante uv";
    Service = {
      Type = "oneshot";
      ExecStart = "${pkgs.uv}/bin/uv tool upgrade --all";
    };
  };
  systemd.user.timers.uv-upgrade = {
    Unit.Description = "Timer para actualizaciones de apps instaladas desde uv";
    Timer = {
      OnCalendar = "weekly";
      Persistent = true;
    };
    Install.WantedBy = [ "timers.target" ];
  };

  # VSCode
  programs.vscode = {
    enable = true;
    profiles.default.extensions = with vscodeExts; [
      rangav.vscode-thunder-client
    ];
  };
}
