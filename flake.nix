{
  description = "Community Call of Duty clients packaged for NixOS - Home Manager launcher module (umu + Proton + bubblewrap)";

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
          cod-h1 = clients.h1;
          cod-h2 = clients.h2;
          cod-steamlink = clients.steamlink;
          cod-steam-add = clients.steamadd;
          cod-steam-native = clients.steamnative;
          cod-cleanops = clients.cleanops;
          cod-iw5 = clients.iw5;
          cod-iw6 = clients.iw6;
          cod-s1 = clients.s1;
          cod-iw2 = clients.iw2;
          cod-hmw = clients.hmw;
          cod-boiii = clients.boiii;
          cod-cblauncher = clients.cblauncher;
          cod-proton = clients.protonpicker;
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
          packages.cod-h1 = pkgs.cod-h1;
          packages.cod-h2 = pkgs.cod-h2;
          packages.cod-steamlink = pkgs.cod-steamlink;
          packages.cod-steam-add = pkgs.cod-steam-add;
          packages.cod-steam-native = pkgs.cod-steam-native;
          packages.cod-cleanops = pkgs.cod-cleanops;
          packages.cod-iw5 = pkgs.cod-iw5;
          packages.cod-iw6 = pkgs.cod-iw6;
          packages.cod-s1 = pkgs.cod-s1;
          packages.cod-iw2 = pkgs.cod-iw2;
          packages.cod-hmw = pkgs.cod-hmw;
          packages.cod-boiii = pkgs.cod-boiii;
          packages.cod-cblauncher = pkgs.cod-cblauncher;
          packages.cod-proton = pkgs.cod-proton;
          packages.default = pkgs.cod-plutonium;

          checks.module-eval-hm = inputs.std.lib.homeModuleCheck {
            inherit (inputs) nixpkgs home-manager;
            inherit system;
            module = ./hm-module.nix;
            config.myModules.home.cod-clients = {
              enable = true;
              plutonium.enable = true;
              t7x.enable = true;
              t7x.extraWinetricks = [ "mf" ];
              h1.enable = true;
              h1.extraWinetricks = [ "mf" ];
              h2.enable = true;
              h2.extraWinetricks = [ "mf" ];
              alterware = {
                iw5.enable = true;
                iw6.enable = true;
                s1.enable = true;
                iw2.enable = true;
              };
              hmw.enable = true;
              hmw.extraWinetricks = [ "mf" ];
              boiii.enable = true;
              boiii.extraWinetricks = [ "mf" ];
              cblauncher.enable = true;
              cblauncher.gameDirs = [ "/tmp/cb-games" ];
              cblauncher.extraWinetricks = [ "dotnet472" ];
              cblauncher.extraArgs = [ "-someflag" ];
              cblauncher.env.PROTON_LOG = "1";
              cblauncher.subProton."probe.exe" = {
                protonPath = "/probe-proton";
                gameDir = "/tmp/cb-games/probe";
                env.PROTON_ENABLE_WAYLAND = "1";
              };
              steamAdd.enable = true;
              steamNative.enable = true;
              steamLink.enable = true;
              cleanops.enable = true;
            };
          };

          checks.sub-proton-build =
            ((pkgs.callPackage ./pkgs/cod-launcher/clients.nix { }) {
              cblauncherSubProton."probe.exe" = {
                protonPath = "/probe-proton";
                gameDir = "/probe-games";
                winetricks = [ ];
                extraArgs = [ ];
                virtualDesktop = {
                  "probe.exe" = "1920x1080";
                };
                env = { };
              };
            }).cblauncher;

          checks.steam-add-logic =
            let
              py = pkgs.python3.withPackages (ps: [ ps.vdf ]);
            in
            pkgs.runCommand "steam-add-logic" { nativeBuildInputs = [ py ]; } ''
              python3 ${./pkgs/cod-launcher/steam-add-test.py} ${./pkgs/cod-launcher/steam-add.py}
              touch $out
            '';

          checks.steam-native-logic =
            let
              py = pkgs.python3.withPackages (ps: [ ps.vdf ]);
            in
            pkgs.runCommand "steam-native-logic" { nativeBuildInputs = [ py ]; } ''
              python3 ${./pkgs/cod-launcher/steam-native-test.py} ${./pkgs/cod-launcher/steam-native.py}
              touch $out
            '';
        };
    };
}
