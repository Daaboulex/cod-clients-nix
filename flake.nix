{
  description = "Call of Duty custom clients (Plutonium, t7x) packaged for NixOS - Home Manager launcher module";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    git-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    std = {
      url = "github:Daaboulex/nix-packaging-standard?ref=v2.12.0";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.git-hooks.follows = "git-hooks";
    };
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" ];

      imports = [ inputs.std.flakeModules.base ];

      flake.homeManagerModules.default = import ./hm-module.nix;
      flake.homeManagerModules.cod-clients = import ./hm-module.nix;

      perSystem =
        { system, ... }:
        let
          pkgs = import inputs.nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };
          clients = (pkgs.callPackage ./pkgs/cod-launcher/clients.nix { }) { };
        in
        {
          _module.args.pkgs = pkgs;

          packages.cod-plutonium = clients.plutonium;
          packages.cod-t7x = clients.t7x;
          packages.cod-steamlink = clients.steamlink;
          packages.default = clients.plutonium;

          checks.module-eval-hm = inputs.std.lib.homeModuleCheck {
            inherit (inputs) nixpkgs home-manager;
            inherit system;
            module = ./hm-module.nix;
            config.myModules.home.codClients = {
              enable = true;
              plutonium.enable = true;
              t7x.enable = true;
            };
          };
        };
    };
}
