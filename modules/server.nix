# modules/servidor.nix
# Rol "servidor casero" para inspiron3048 (i3 Haswell, 4GB RAM) — todo pensado
# para uso SOLO-LAN, sin exposición a internet ni dominio público.

{ config, pkgs, ... }:

{
  # Descubrimiento en la red local
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    publish = {
      enable = true;
      addresses = true;
      workstation = true;
    };
  };

  # SSH endurecido
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  # Compartición de archivos: Samba + WSDD (para que Windows lo vea en Red)
  services.samba = {
    enable = true;
    openFirewall = true;
    settings = {
      global = {
        "workgroup" = "WORKGROUP";
        "server string" = "servidor-chambeador";
        "security" = "user";
        "map to guest" = "bad user";
      };
      compartido = {
        path = "/srv/compartido";
        browseable = "yes";
        "read only" = "no";
        "guest ok" = "no";
        "force user" = "alan";
      };
    };
  };

  services.samba-wsdd = {
    enable = true;
    openFirewall = true;
  };

  systemd.tmpfiles.rules = [
    "d /srv/compartido 0775 alan users -"
  ];

  # Sincronización de archivos
  services.syncthing = {
    enable = true;
    user = "alan";
    dataDir = "/home/alan/.syncthing";
    openDefaultPorts = true;
  };

  # DNS / bloqueador de anuncios para toda la LAN
  services.adguardhome = {
    enable = true;
    openFirewall = true;
  };

  # Git self-hosted (SSH interno desactivado, se usa el sshd del sistema)
  services.gitea = {
    enable = true;
    database.type = "sqlite3";
    settings = {
      server = {
        DOMAIN = "servidor-chambeador.local";
        ROOT_URL = "http://servidor-chambeador.local:3000/";
        DISABLE_SSH = true;
      };
      service.DISABLE_REGISTRATION = true;
    };
  };

  # Streaming multimedia
  services.navidrome = {
    enable = true;
    settings = {
      MusicFolder = "/srv/musica";
    };
  };

  # Jellyfin apagado: el i3 Haswell no aguanta transcodificar video, lo desactivaré por ahora
  # services.jellyfin.enable = true;
  
  # Descargas torrent headless (solo accesible desde la LAN, sin auth)
  services.transmission = {
    enable = true;
    openFirewall = true;
    settings = {
      rpc-bind-address = "0.0.0.0";
      rpc-whitelist-enabled = true;
      rpc-whitelist = "192.168.*.*";
      rpc-authentication-required = false;
      download-dir = "/srv/descargas";
    };
  };

  # Panel de administración web
  services.cockpit = {
    enable = true;
    openFirewall = true;
  };

  services.homepage-dashboard = {
    enable = true;
    openFirewall = true;
  };

  # Firewall: nada de esto debe salir a internet
  networking.firewall.enable = true;
}