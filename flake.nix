{
  description = "kozaxo system configuration";

  # --- inputs ---

  inputs = {
    nixpkgs.url      = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url    = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-darwin = {
      url    = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  # --- outputs ---

  outputs = { nixpkgs, home-manager, nix-darwin, ... }:
  let
    # Build a nixpkgs package set for a given system with unfree packages allowed.
    pkgsFor = system: import nixpkgs {
      inherit system;
      config.allowUnfree = true;
    };

    linuxSystems  = [ "x86_64-linux"  "aarch64-linux"  ];
    darwinSystems = [ "x86_64-darwin" "aarch64-darwin" ];

    # Helper: build an attrset keyed by system string.
    forSystems = systems: f:
      builtins.listToAttrs (map (system: { name = system; value = f system; }) systems);

  in {

    # -- nixos --
    nixosConfigurations = forSystems linuxSystems (system:
      nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          home-manager.nixosModules.home-manager
          ./modules/nixos.nix
        ];
      }
    );

    # -- macos --
    darwinConfigurations = forSystems darwinSystems (system:
      nix-darwin.lib.darwinSystem {
        inherit system;
        modules = [
          home-manager.darwinModules.home-manager
          ./modules/darwin.nix
        ];
      }
    );

    # -- ubuntu --
    homeConfigurations = forSystems linuxSystems (system:
      home-manager.lib.homeManagerConfiguration {
        pkgs    = pkgsFor system;
        modules = [ ./modules/ubuntu.nix ];
      }
    );

  };
}
