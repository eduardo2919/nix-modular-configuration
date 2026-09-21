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
      system = "x86_64-linux";
      mkHost = hostName: extraModules:
        let
          vars = import ./hosts/${hostName}/variables.nix;
        in
        nixpkgs.lib.nixosSystem {
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
              home-manager.users.alan = import ./modules/home.nix;
              home-manager.extraSpecialArgs = {
                inherit vars;
                vscodeExts = nix-vscode-extensions.extensions.${system}.open-vsx;
              };
            }
          ] ++ extraModules;
        };
    in {
      nixosConfigurations = {
        fiduardo = mkHost "fiduardo" [ ./modules/escritorio.nix ];
        inspiron3048 = mkHost "inspiron3048" [ ./modules/servidor.nix ];
      };
    };
}