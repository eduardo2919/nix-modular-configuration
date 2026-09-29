{ config, pkgs, vars, ... }:
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

  users.users.alan.openssh.authorizedKeys.keys = [
  ];
  assertions = [
    {
      assertion = config.users.users.alan.openssh.authorizedKeys.keys != [ ];
      message = "Agrega al menos una llave pública en users.users.alan.openssh.authorizedKeys.keys antes de compilar: con PasswordAuthentication = false y sin llave te quedas fuera por SSH.";
    }
  ];

  # Compartición de archivos: Samba + WSDD (para que Windows lo vea en Red)
  # Nota: la contraseña de Samba no es declarativa. Tras el primer switch,
  # corre: sudo smbpasswd -a alan
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
    # GUI 127.0.0.1:8384
    guiAddress = "0.0.0.0:8384";
    openDefaultPorts = true;
  };

  # DNS / bloqueador de anuncios para toda la LAN
  services.adguardhome = {
    enable = true;
    # El puerto 3000 por omisión choca con Gitea (más abajo), así que la
    # interfaz web de AdGuard se mueve al 3001. openFirewall solo abre esa
    # web; el puerto 53 (DNS) lo abre networking.firewall más abajo.
    port = 3001;
    openFirewall = true;
  };

  # Git self-hosted (SSH interno desactivado: con DISABLE_SSH = true no hay
  # clonado por SSH en absoluto, solo por HTTP/HTTPS; el sshd del sistema de
  # arriba es solo para que tú entres a administrar la máquina)
  services.gitea = {
    enable = true;
    database.type = "sqlite3";
    settings = {
      server = {
        DOMAIN = "servidor-chambeador.local";
        HTTP_PORT = 3000;
        ROOT_URL = "http://servidor-chambeador.local:3000/";
        DISABLE_SSH = true;
      };
      service.DISABLE_REGISTRATION = true;
    };
  };
  networking.firewall.allowedTCPPorts = [ 3000 ];

  # Streaming multimedia
  services.navidrome = {
    enable = true;
    # Escucha solo en 127.0.0.1
    settings = {
      Address = "0.0.0.0";
      MusicFolder = "/srv/musica";
    };
    openFirewall = true;
  };

  # Jellyfin apagado: el i3 Haswell no aguanta transcodificar video, lo desactivaré por ahora
  # services.jellyfin.enable = true;
  # (si lo reactivas algún día en este hardware, usa intel-vaapi-driver,
  # no intel-media-driver: para Haswell es el driver correcto)

  # Descargas torrent headless (solo accesible desde la LAN, sin auth)
  services.transmission = {
    enable = true;
    # openFirewall solo abre el puerto de pares (P2P); el puerto RPC (webUI/
    # API, el que de verdad usas para controlarlo) lo abre openRPCPort.
    openPeerPorts = true;
    openRPCPort = true;
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
    # Desde la 1.0 el módulo exige declarar los hosts permitidos; sin esto
    # verás "Host validation failed" al entrar por algo distinto de
    # localhost. Ajusta si le pones otro nombre/IP.
    allowedHosts = "servidor-chambeador.local:3000,127.0.0.1:3000,localhost:3000";
  };

  # Firewall: nada de esto debe salir a internet
  # (openFirewall/openPeerPorts/openRPCPort de arriba abren en TODAS las
  # interfaces, IPv6 incluido — este comentario no lo garantiza por sí solo.
  # Tu router probablemente ya te protege del exterior, pero si quieres que
  # sea de verdad "solo LAN" a nivel de este equipo, restringe por interfaz
  # con networking.firewall.interfaces.<iface>.allowedTCPPorts en vez de los
  # openFirewall globales, o usa extraInputRules.)
  networking.firewall.enable = true;
}
