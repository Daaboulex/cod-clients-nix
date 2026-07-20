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

      flake.overlays.default =
        _final: prev:
        let
          clients = (prev.callPackage ./pkgs/cod-launcher/clients.nix { }) { };
        in
        {
          cod-plutonium = clients.plutonium;
          cod-t7x = clients.t7x;
          cod-steamlink = clients.steamlink;
          cod-steam-add = clients.steamadd;
          cod-cleanops = clients.cleanops;
          cod-iw5 = clients.iw5;
          cod-iw6 = clients.iw6;
          cod-s1 = clients.s1;
          cod-iw2 = clients.iw2;
        };

      perSystem =
        { system, ... }:
        let
          pkgs = import inputs.nixpkgs {
            inherit system;
            config.allowUnfree = true;
            overlays = [ inputs.self.overlays.default ];
          };
        in
        {
          _module.args.pkgs = pkgs;

          packages.cod-plutonium = pkgs.cod-plutonium;
          packages.cod-t7x = pkgs.cod-t7x;
          packages.cod-steamlink = pkgs.cod-steamlink;
          packages.cod-steam-add = pkgs.cod-steam-add;
          packages.cod-cleanops = pkgs.cod-cleanops;
          packages.cod-iw5 = pkgs.cod-iw5;
          packages.cod-iw6 = pkgs.cod-iw6;
          packages.cod-s1 = pkgs.cod-s1;
          packages.cod-iw2 = pkgs.cod-iw2;
          packages.default = pkgs.cod-plutonium;

          checks.module-eval-hm = inputs.std.lib.homeModuleCheck {
            inherit (inputs) nixpkgs home-manager;
            inherit system;
            module = ./hm-module.nix;
            config.myModules.home.cod-clients = {
              enable = true;
              plutonium.enable = true;
              t7x.enable = true;
              alterware = {
                iw5.enable = true;
                iw6.enable = true;
                s1.enable = true;
                iw2.enable = true;
              };
            };
          };

          checks.steam-add-logic =
            let
              py = pkgs.python3.withPackages (ps: [ ps.vdf ]);
            in
            pkgs.runCommand "steam-add-logic" { nativeBuildInputs = [ py ]; } ''
              python3 ${./pkgs/cod-launcher/steam-add-test.py} ${./pkgs/cod-launcher/steam-add.py}
              touch $out
            '';
        };
    };
}
