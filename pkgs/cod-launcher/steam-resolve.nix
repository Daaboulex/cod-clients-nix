''
  _steam_roots() {
    printf '%s\n' \
      "$HOME/.steam/steam" \
      "$HOME/.steam/root" \
      "$HOME/.local/share/Steam" \
      "$HOME/.local/share/steam" \
      "$HOME/.var/app/com.valvesoftware.Steam/.local/share/Steam" \
      "$HOME/.var/app/com.valvesoftware.Steam/.steam/steam" \
      "$HOME/snap/steam/common/.local/share/Steam" \
      "$HOME/snap/steam/common/.steam/steam"
  }

  resolve_steam_dir() {
    local appid="$1" root lf steamlib manifest installdir cand libs
    while IFS= read -r root; do
      [ -d "$root/steamapps" ] || continue
      libs=("$root")
      lf="$root/steamapps/libraryfolders.vdf"
      if [ -f "$lf" ]; then
        while IFS= read -r cand; do
          libs+=("$cand")
        done < <(grep -oP '"path"[[:space:]]*"\K[^"]+' "$lf" 2>/dev/null || true)
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
    done < <(_steam_roots)
    return 1
  }

  list_steam_libraries() {
    local root lf
    {
      while IFS= read -r root; do
        [ -d "$root/steamapps" ] || continue
        printf '%s\n' "$root"
        lf="$root/steamapps/libraryfolders.vdf"
        if [ -f "$lf" ]; then
          grep -oP '"path"[[:space:]]*"\K[^"]+' "$lf" 2>/dev/null || true
        fi
      done < <(_steam_roots)
    } | sort -u
  }
''
