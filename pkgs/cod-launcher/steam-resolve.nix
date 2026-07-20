''
  resolve_steam_dir() {
    local appid="$1" root lf steamlib manifest installdir cand libs
    local roots=(
      "$HOME/.steam/steam"
      "$HOME/.steam/root"
      "$HOME/.local/share/Steam"
      "$HOME/.local/share/steam"
      "$HOME/.var/app/com.valvesoftware.Steam/.local/share/Steam"
      "$HOME/.var/app/com.valvesoftware.Steam/.steam/steam"
      "$HOME/snap/steam/common/.local/share/Steam"
      "$HOME/snap/steam/common/.steam/steam"
    )
    for root in "''${roots[@]}"; do
      [ -d "$root/steamapps" ] || continue
      libs=("$root")
      lf="$root/steamapps/libraryfolders.vdf"
      if [ -f "$lf" ]; then
        while IFS= read -r cand; do
          libs+=("$cand")
        done < <(grep -oP '"path"[[:space:]]*"\K[^"]+' "$lf")
      fi
      for steamlib in "''${libs[@]}"; do
        manifest="$steamlib/steamapps/appmanifest_$appid.acf"
        [ -f "$manifest" ] || continue
        installdir=$(grep -oP '"installdir"[[:space:]]*"\K[^"]+' "$manifest" | head -n1 || true)
        if [ -n "$installdir" ] && [ -d "$steamlib/steamapps/common/$installdir" ]; then
          printf '%s\n' "$steamlib/steamapps/common/$installdir"
          return 0
        fi
      done
    done
    return 1
  }
''
