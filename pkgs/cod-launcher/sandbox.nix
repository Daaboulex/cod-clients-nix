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
      --dev-bind-try /dev/input /dev/input
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

    local rd="''${XDG_RUNTIME_DIR:-}"
    if [ -n "$rd" ]; then
      bw+=(--tmpfs "$rd")
      [ -S "$rd/pipewire-0" ] && bw+=(--ro-bind "$rd/pipewire-0" "$rd/pipewire-0")
      [ -S "$rd/pulse/native" ] && bw+=(--bind "$rd/pulse/native" "$rd/pulse/native")
      if [ -n "''${WAYLAND_DISPLAY:-}" ] && [ -S "$rd/$WAYLAND_DISPLAY" ]; then
        bw+=(--ro-bind "$rd/$WAYLAND_DISPLAY" "$rd/$WAYLAND_DISPLAY")
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

    if [ -n "''${gamedir:-}" ]; then
      bw+=(--ro-bind-try "$gamedir" "$gamedir")
    fi
    if [ -n "''${gamedir_rw:-}" ]; then
      bw+=(--bind-try "$gamedir_rw" "$gamedir_rw")
    fi

    exec "''${bw[@]}" "$@"
  }
''
