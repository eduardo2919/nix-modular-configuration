{
  description = "Configuración flakes global de fiduardo";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-flatpak.url = "github:gmodena/nix-flatpak";
    nix-vscode-extensions = {
      url = "github:nix-community/nix-vscode-extensions";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, sops-nix, nix-flatpak, nix-vscode-extensions, ... }:
    let
      inherit (nixpkgs) lib;
      system = "x86_64-linux";

      defaultVars = hostName: {
        hostname = hostName;
        isDesktop = false;
        isServer = false;
      };

      mkHost = hostName:
        let
          vars = defaultVars hostName // import ./hosts/${hostName}/variables.nix;
        in
        lib.nixosSystem {
          inherit system;
          specialArgs = { inherit vars; };
          modules = [
            ./hosts/${hostName}/hardware-configuration.nix
            ./modules/base.nix
            sops-nix.nixosModules.sops
            nix-flatpak.nixosModules.nix-flatpak
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              # Si ya existe un archivo real donde HM quiere poner un enlace,
              # lo renombra a *.hm-bak en vez de abortar el switch.
              home-manager.backupFileExtension = "hm-bak";
              home-manager.users.alan = import ./modules/home.nix;
              home-manager.extraSpecialArgs = {
                inherit vars;
                vscodeExts = nix-vscode-extensions.extensions.${system}.open-vsx;
              };
            }
          ]
          # El rol de cada equipo lo deciden los flags de su variables.nix
          ++ lib.optional vars.isDesktop ./modules/escritorio.nix
          ++ lib.optional vars.isServer ./modules/server.nix;
        };

      # Cada carpeta dentro de hosts/ es un host: agregar un PC = crear hosts/<nombre>/
      hosts = builtins.attrNames
        (lib.filterAttrs (_: type: type == "directory") (builtins.readDir ./hosts));
    in
    {
      nixosConfigurations = lib.genAttrs hosts mkHost;
    };
}
