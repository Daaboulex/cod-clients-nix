{
  lib,
  writeShellApplication,
  curl,
  coreutils,
  gnugrep,
}:

{ resolver }:

writeShellApplication {
  name = "cod-cleanops";
  runtimeInputs = [
    curl
    coreutils
    gnugrep
  ];
  text = ''
    ${resolver}

    appid="311210"
    gamedir=""
    undo=0
    while [ "$#" -gt 0 ]; do
      case "$1" in
      --dir)
        gamedir="''${2:?--dir needs a value}"
        shift 2
        ;;
      --undo)
        undo=1
        shift
        ;;
      -h | --help)
        echo "usage: cod-cleanops [--dir PATH] [--undo]"
        echo "Drops the CleanOps d3d11.dll into your owned retail Black Ops III (app 311210)"
        echo "so launching BlackOps3.exe through Steam loads CleanOps (cheat-removal + P2P hosting)."
        exit 0
        ;;
      *)
        echo "cod-cleanops: unknown argument: $1" >&2
        exit 1
        ;;
      esac
    done

    if [ -z "$gamedir" ]; then
      gamedir="$(resolve_steam_dir "$appid" || true)"
    fi
    if [ -z "$gamedir" ] || [ ! -d "$gamedir" ]; then
      echo "cod-cleanops: Black Ops III (app $appid) not found in any Steam library." >&2
      echo "Own + install it on Steam, or pass --dir \"/path/to/Call of Duty Black Ops III\"." >&2
      exit 1
    fi

    dll="$gamedir/d3d11.dll"
    backup="$gamedir/d3d11.dll.cod-orig"

    if [ "$undo" -eq 1 ]; then
      if [ -f "$backup" ]; then
        mv -f "$backup" "$dll"
        echo "cod-cleanops: restored the original d3d11.dll."
      elif [ -f "$dll" ]; then
        rm -f "$dll"
        echo "cod-cleanops: removed the CleanOps d3d11.dll."
      else
        echo "cod-cleanops: nothing to undo at $gamedir." >&2
        exit 1
      fi
      exit 0
    fi

    if [ -f "$dll" ] && [ ! -f "$backup" ]; then
      cp -f --no-preserve=mode "$dll" "$backup"
      echo "cod-cleanops: backed up the existing d3d11.dll -> d3d11.dll.cod-orig"
    fi
    echo "cod-cleanops: fetching the CleanOps d3d11.dll"
    curl -fL --remove-on-error --output "$dll" \
      "https://raw.githubusercontent.com/notnightwolf/cleanopsT7/main/d3d11.dll"

    echo "cod-cleanops: installed into $gamedir"
    echo "In Steam, set Black Ops III -> Properties -> Launch Options to:"
    echo '  WINEDLLOVERRIDES="d3d11=n,b" %command%'
    echo "then launch Black Ops III through Steam as usual. Undo any time: cod-cleanops --undo"
  '';
  meta = {
    description = "CleanOps installer for retail Black Ops III MP (d3d11.dll cheat-removal + P2P) on NixOS";
    homepage = "https://github.com/Daaboulex/cod-clients-nix";
    license = lib.licenses.mit;
    mainProgram = "cod-cleanops";
    platforms = [ "x86_64-linux" ];
  };
}
