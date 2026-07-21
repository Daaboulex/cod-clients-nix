{
  writeShellApplication,
  python3,
  coreutils,
  procps,
  jq,
}:

let
  resolver = import ./steam-resolve.nix;
  py = python3.withPackages (ps: [ ps.vdf ]);
in
writeShellApplication {
  name = "cod-steam-add";
  runtimeInputs = [
    py
    coreutils
    procps
    jq
  ];
  text = ''
    ${resolver}

    cmd="add"
    case "''${1:-}" in
    add | remove | list)
      cmd="$1"
      ;;
    -h | --help)
      echo "usage: cod-steam-add [add|remove|list]"
      echo "  add     register installed cod-* launchers as Steam non-Steam shortcuts (default)"
      echo "  remove  remove the cod-clients shortcuts again"
      echo "  list    show the cod-clients shortcuts currently registered"
      echo "Close Steam before add/remove; restart it afterwards. Pick Proton + launch"
      echo "options per shortcut in Steam (COD_PROTON=<path> %command% for a specific Proton)."
      exit 0
      ;;
    "")
      ;;
    *)
      echo "cod-steam-add: unknown argument: $1" >&2
      exit 1
      ;;
    esac

    if [ "$cmd" != list ]; then
      if pgrep -x steam >/dev/null 2>&1 || pgrep -x steamwebhelper >/dev/null 2>&1; then
        echo "cod-steam-add: Steam is running -- fully close it first (Steam rewrites shortcuts.vdf on exit)." >&2
        exit 1
      fi
    fi

    launchers_json="[]"
    add_launcher() {
      local name="$1" display="$2" exe
      if exe="$(command -v "cod-$name" 2>/dev/null)"; then
        launchers_json="$(jq -c --arg exe "$exe" --arg display "$display" \
          '. + [{exe: $exe, display: $display}]' <<< "$launchers_json")"
      fi
    }
    add_launcher plutonium "Plutonium"
    add_launcher t7x "Call of Duty: Black Ops III (t7x)"
    add_launcher h1 "Call of Duty: Modern Warfare Remastered (h1-mod)"
    add_launcher h2 "Call of Duty: MW2 Campaign Remastered (h2-mod)"
    add_launcher hmw "Horizon MW"
    add_launcher boiii "Call of Duty: Black Ops III (BOIII)"
    add_launcher iw5 "Call of Duty: Modern Warfare 3 (iw5-mod)"
    add_launcher iw6 "Call of Duty: Ghosts (iw6-mod)"
    add_launcher s1 "Call of Duty: Advanced Warfare (s1-mod)"
    add_launcher iw2 "Call of Duty 2 (iw2-mod)"
    add_launcher cblauncher "CB Launcher"

    if [ "$cmd" = add ] && [ "$launchers_json" = "[]" ]; then
      echo "cod-steam-add: no cod-* launchers on PATH -- enable clients in the module first." >&2
      exit 1
    fi

    roots_json="$(_steam_roots | jq -R -s -c 'split("\n") | map(select(length > 0))')"
    payload="$(jq -c -n --argjson roots "$roots_json" --argjson launchers "$launchers_json" \
      '{roots: $roots, launchers: $launchers}')"

    printf '%s' "$payload" | python3 ${./steam-add.py} "$cmd"
  '';
}
