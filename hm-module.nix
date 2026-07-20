{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.myModules.home.codClients;
in
{
  options.myModules.home.codClients = {
    enable = lib.mkEnableOption "Call of Duty custom clients launcher (Plutonium + t7x) via umu + Proton";

    protonPath = lib.mkOption {
      type = lib.types.str;
      default = "${pkgs.proton-ge-bin.steamcompattool}";
      defaultText = lib.literalExpression ''"''${pkgs.proton-ge-bin.steamcompattool}"'';
      description = ''
        Proton directory umu runs the clients under (must contain the `proton` script).
        The default pins nixpkgs GE-Proton reproducibly; override with a path to a
        ProtonPlus-managed GE-Proton to reuse that instead of pulling a second copy.
      '';
    };

    sandbox = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Run every client inside a bubblewrap sandbox that exposes only game files
        (Steam libraries, read-only), the client's own prefix/state (read-write),
        and GPU/audio/input/display/network -- no $HOME or unrelated files. Set the
        COD_SANDBOX=0 environment variable at runtime to bypass it for one launch.
      '';
    };

    plutonium = {
      enable = lib.mkEnableOption "the Plutonium client launcher (Black Ops 1/2, MW3, WaW)";
      dotnet = lib.mkEnableOption ''
        MW3/IW5 support in the Plutonium prefix (installs dotnet472). Slower first-run,
        and MW3/IW5 has an unfixed no-cursor bug on NixOS + GE-Proton'';
      extraWinetricks = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Extra winetricks verbs added to the Plutonium prefix.";
      };
      extraArgs = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Extra arguments passed to plutonium.exe (advanced/LAN use).";
      };
    };

    t7x = {
      enable = lib.mkEnableOption "the t7x client launcher (Black Ops III) -- experimental on Linux";
      blackOps3Dir = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = ''
          Path to the owned retail Black Ops III Steam install directory. Empty =
          auto-detect from Steam's libraryfolders.vdf (app 311210).
        '';
      };
      extraWinetricks = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = ''
          Extra winetricks verbs for the t7x prefix, e.g. [ "mf" "mfplat" ] if you hit
          the media-foundation codec error.
        '';
      };
      extraArgs = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Extra arguments passed to t7x.exe.";
      };
    };

    alterware = {
      iw4x.enable = lib.mkEnableOption "the iw4x launcher (Modern Warfare 2, 2009) -- experimental";
      iw5.enable = lib.mkEnableOption "the iw5-mod launcher (Modern Warfare 3, 2011) -- experimental";
      iw6.enable = lib.mkEnableOption "the iw6-mod launcher (Ghosts) -- experimental";
      s1.enable = lib.mkEnableOption "the s1-mod launcher (Advanced Warfare) -- experimental";
      iw2.enable = lib.mkEnableOption "the iw2-mod launcher (Call of Duty 2) -- experimental";
    };
  };

  config = lib.mkIf cfg.enable (
    let
      clients = (pkgs.callPackage ./pkgs/cod-launcher/clients.nix { }) {
        inherit (cfg) protonPath;
        plutoniumDotnet = cfg.plutonium.dotnet;
        plutoniumExtraWinetricks = cfg.plutonium.extraWinetricks;
        plutoniumExtraArgs = cfg.plutonium.extraArgs;
        inherit (cfg.t7x) blackOps3Dir;
        t7xExtraWinetricks = cfg.t7x.extraWinetricks;
        t7xExtraArgs = cfg.t7x.extraArgs;
        inherit (cfg) sandbox;
      };
    in
    {
      home.packages =
        lib.optional cfg.plutonium.enable clients.plutonium
        ++ lib.optional cfg.plutonium.enable clients.steamlink
        ++ lib.optional cfg.t7x.enable clients.t7x
        ++ lib.optional cfg.alterware.iw4x.enable clients.iw4x
        ++ lib.optional cfg.alterware.iw5.enable clients.iw5
        ++ lib.optional cfg.alterware.iw6.enable clients.iw6
        ++ lib.optional cfg.alterware.s1.enable clients.s1
        ++ lib.optional cfg.alterware.iw2.enable clients.iw2;
    }
  );
}
