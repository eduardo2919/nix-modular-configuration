{
  description = "Configuración flake de esta máquina";

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
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-flatpak.url = "github:gmodena/nix-flatpak";
    nix-vscode-extensions = {
      url = "github:nix-community/nix-vscode-extensions";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, sops-nix, disko, nix-flatpak, nix-vscode-extensions, ... }:
    let
      inherit (nixpkgs) lib;
      system = "x86_64-linux";

      # Valores por omisión, por si variables.nix no define algo
      defaultVars = {
        usuario = "alan";
        esLaptop = false;
        entornoEscritorio = null;
        gaming = false;
        androidApps = false;
      };
      vars = defaultVars // import ./host/variables.nix;
    in
    {
      # El nombre de la config lo decide host/variables.nix, no este archivo
      nixosConfigurations.${vars.hostname} = lib.nixosSystem {
        inherit system;
        specialArgs = { inherit vars; };
        modules = [
          ./host/hardware-configuration.nix
          ./modulos/base.nix
          ./modulos/escritorio.nix
          sops-nix.nixosModules.sops
          nix-flatpak.nixosModules.nix-flatpak
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.backupFileExtension = "hm-bak";
            home-manager.users.${vars.usuario} = import ./modulos/home.nix;
            home-manager.extraSpecialArgs = {
              inherit vars;
              vscodeExts = nix-vscode-extensions.extensions.${system}.open-vsx;
            };
          }
        ]
        # disko.nix es opcional: solo se mete si existe (lo tenías en el
        # árbol anterior; si lo quieres aquí, pon host/disko.nix igual)
        ++ lib.optional (builtins.pathExists ./host/disko.nix) disko.nixosModules.disko
        ++ lib.optional (builtins.pathExists ./host/disko.nix) ./host/disko.nix;
      };
    };
}
