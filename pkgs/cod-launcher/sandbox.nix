''
  cod_launch() {
    if [ "''${COD_SANDBOX:-1}" != "1" ]; then
      exec "$@"
    fi

    local -a bw=(
      bwrap
      --unshare-user --unshare-pid --unshare-uts --unshare-cgroup
      --die-with-parent --new-session
      --proc /proc --dev /dev --tmpfs /tmp
      --ro-bind /nix/store /nix/store
      --ro-bind-try "$PROTONPATH" "$PROTONPATH"
      --ro-bind-try /etc/static /etc/static
      --ro-bind-try /etc/passwd /etc/passwd
      --ro-bind-try /etc/group /etc/group
      --ro-bind-try /etc/nsswitch.conf /etc/nsswitch.conf
      --ro-bind-try /etc/resolv.conf /etc/resolv.conf
      --ro-bind-try /etc/hosts /etc/hosts
      --ro-bind-try /etc/ssl /etc/ssl
      --ro-bind-try /etc/pki /etc/pki
      --ro-bind-try /etc/fonts /etc/fonts
      --ro-bind-try /etc/machine-id /etc/machine-id
      --ro-bind-try /sys/dev/char /sys/dev/char
      --ro-bind-try /sys/devices /sys/devices
      --ro-bind-try /run/opengl-driver /run/opengl-driver
      --ro-bind-try /run/opengl-driver-32 /run/opengl-driver-32
      --dev-bind-try /dev/dri /dev/dri
      --tmpfs /dev/input
      --dev-bind-try /dev/ntsync /dev/ntsync
      --ro-bind-try /run/udev /run/udev
      --share-net
      --bind "$state" "$state"
      --setenv UMU_FOLDERS_PATH "$state/umu"
      --chdir "$PWD"
    )

    local dev
    for dev in /dev/nvidiactl /dev/nvidia-modeset /dev/nvidia-uvm /dev/nvidia-uvm-tools /dev/nvidia0 /dev/nvidia1 /dev/nvidia2; do
      [ -e "$dev" ] && bw+=(--dev-bind-try "$dev" "$dev")
    done

    local bound_input=0 node syspath
    for node in /dev/input/event* /dev/input/js* /dev/input/mouse*; do
      [ -e "$node" ] || continue
      syspath="$(readlink -f "/sys/class/input/$(basename "$node")" 2>/dev/null || true)"
      case "$syspath" in
        */devices/virtual/*) : ;;
        *)
          bw+=(--dev-bind-try "$node" "$node")
          bound_input=1
          ;;
      esac
    done
    if [ "$bound_input" = 0 ]; then
      bw+=(--dev-bind-try /dev/input /dev/input)
    fi

    local hid jsnode
    for hid in /dev/hidraw*; do
      [ -e "$hid" ] || continue
      for jsnode in "/sys/class/hidraw/$(basename "$hid")/device"/input/input*/js*; do
        if [ -e "$jsnode" ]; then
          bw+=(--dev-bind-try "$hid" "$hid")
          break
        fi
      done
    done

    local rd="''${XDG_RUNTIME_DIR:-}"
    if [ -n "$rd" ]; then
      bw+=(--tmpfs "$rd")
      [ -S "$rd/pipewire-0" ] && bw+=(--bind "$rd/pipewire-0" "$rd/pipewire-0")
      [ -S "$rd/pulse/native" ] && bw+=(--bind "$rd/pulse/native" "$rd/pulse/native")
      [ -S "$rd/bus" ] && bw+=(--bind "$rd/bus" "$rd/bus")
      if [ -n "''${WAYLAND_DISPLAY:-}" ] && [ -S "$rd/$WAYLAND_DISPLAY" ]; then
        bw+=(--bind "$rd/$WAYLAND_DISPLAY" "$rd/$WAYLAND_DISPLAY")
      fi
    fi

    if [ -n "''${DISPLAY:-}" ]; then
      bw+=(--ro-bind-try /tmp/.X11-unix /tmp/.X11-unix)
      [ -n "''${XAUTHORITY:-}" ] && bw+=(--ro-bind-try "$XAUTHORITY" "$XAUTHORITY")
    fi

    local sl
    while IFS= read -r sl; do
      bw+=(--ro-bind-try "$sl/steamapps" "$sl/steamapps")
    done < <(list_steam_libraries)

    while IFS= read -r sl; do
      bw+=(
        --ro-bind-try "$sl/linux64" "$sl/linux64"
        --ro-bind-try "$sl/linux32" "$sl/linux32"
        --ro-bind-try "$sl/ubuntu12_64" "$sl/ubuntu12_64"
        --ro-bind-try "$sl/ubuntu12_32" "$sl/ubuntu12_32"
      )
    done < <(_steam_roots)
    bw+=(
      --ro-bind-try "$HOME/.steam/sdk64" "$HOME/.steam/sdk64"
      --ro-bind-try "$HOME/.steam/sdk32" "$HOME/.steam/sdk32"
    )

    if [ -n "''${gamedir:-}" ]; then
      bw+=(--ro-bind-try "$gamedir" "$gamedir")
    fi
    if [ -n "''${gamedir_rw:-}" ]; then
      bw+=(--bind-try "$gamedir_rw" "$gamedir_rw")
    fi

    if [ -n "''${cod_rw_dirs:-}" ]; then
      local rwd
      while IFS= read -r rwd; do
        [ -n "$rwd" ] && bw+=(--bind-try "$rwd" "$rwd")
      done <<< "$cod_rw_dirs"
    fi

    exec "''${bw[@]}" "$@"
  }
''
