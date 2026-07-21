{
  lib,
  writeShellApplication,
  coreutils,
  gnused,
}:
let
  resolver = import ./steam-resolve.nix;
in
writeShellApplication {
  name = "cod-proton";
  runtimeInputs = [
    coreutils
    gnused
  ];
  text = ''
    ${resolver}
    cfg="''${XDG_CONFIG_HOME:-$HOME/.config}/cod-clients"

    list_protons() {
      local root d
      while IFS= read -r root; do
        for d in "$root"/compatibilitytools.d/*/; do
          [ -f "''${d}proton" ] && basename "''${d%/}"
        done
      done < <(_steam_roots) | sort -u
    }

    show_state() {
      local f found=0
      echo "installed Protons (compatibilitytools.d):"
      list_protons | sed 's/^/  /'
      echo
      echo "current overrides (delete the file to revert to auto-detect):"
      for f in "$cfg"/*.proton "$cfg/proton"; do
        [ -f "$f" ] || continue
        printf '  %s -> %s\n' "$(basename "$f")" "$(head -n1 "$f")"
        found=1
      done
      [ "$found" = 0 ] && echo "  (none - every client auto-detects the newest)"
    }

    client="''${1:-}"
    choice="''${2:-}"

    if [ -z "$client" ]; then
      echo "usage: cod-proton <client> [<proton>|auto]   e.g. cod-proton cblauncher"
      echo "       cod-proton proton ...    sets the global default for every client"
      echo
      show_state
      exit 0
    fi

    file="$cfg/$client.proton"
    [ "$client" = proton ] && file="$cfg/proton"

    if [ "$choice" = auto ] || [ "$choice" = clear ]; then
      rm -f "$file"
      echo "cod-proton: $client -> auto-detect (override cleared)."
      exit 0
    fi

    if [ -z "$choice" ]; then
      mapfile -t protons < <(list_protons)
      if [ "''${#protons[@]}" -eq 0 ]; then
        echo "cod-proton: no Proton found in any compatibilitytools.d (install one via ProtonPlus)." >&2
        exit 1
      fi
      if command -v kdialog >/dev/null 2>&1; then
        menu=()
        i=0
        for p in "''${protons[@]}"; do
          menu+=("$i" "$p")
          i=$((i + 1))
        done
        sel="$(kdialog --menu "Proton for $client" "''${menu[@]}" 2>/dev/null || true)"
        [ -n "$sel" ] && choice="''${protons[$sel]}"
      elif command -v zenity >/dev/null 2>&1; then
        choice="$(printf '%s\n' "''${protons[@]}" | zenity --list --title "Proton for $client" --column "Proton" 2>/dev/null || true)"
      else
        echo "Pick a Proton for $client:"
        i=1
        for p in "''${protons[@]}"; do
          printf '  %d) %s\n' "$i" "$p"
          i=$((i + 1))
        done
        echo "  0) auto-detect"
        read -r -p "number: " n
        if [ "$n" = 0 ]; then
          rm -f "$file"
          echo "cod-proton: $client -> auto-detect."
          exit 0
        fi
        choice="''${protons[$((n - 1))]:-}"
      fi
    fi

    [ -n "$choice" ] || {
      echo "cod-proton: nothing selected." >&2
      exit 1
    }
    mkdir -p "$cfg"
    printf '%s\n' "$choice" > "$file"
    echo "cod-proton: $client now uses '$choice'."
  '';
  meta = {
    description = "Pick the Proton a cod-clients launcher uses (GUI or terminal) on NixOS";
    homepage = "https://github.com/Daaboulex/cod-clients-nix";
    license = lib.licenses.mit;
    mainProgram = "cod-proton";
    platforms = [ "x86_64-linux" ];
  };
}
