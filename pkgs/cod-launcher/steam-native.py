import json
import os
import shutil
import sys
import urllib.request
import zlib

import vdf

TAG = "cod-clients-nix"
ART_HOST = "https://cdn.cloudflare.steamstatic.com/steam/apps"
ART_MAP = {
    "p.jpg": "library_600x900.jpg",
    "_hero.jpg": "library_hero.jpg",
    "_logo.png": "logo.png",
    ".jpg": "header.jpg",
}


def shortcut_appid(exe, name):
    crc = zlib.crc32((exe + name).encode("utf-8")) & 0xFFFFFFFF
    value = crc | 0x80000000
    return value - 0x100000000 if value >= 0x80000000 else value


def unsigned32(appid):
    return appid + 0x100000000 if appid < 0 else appid


def userdata_dirs(roots):
    seen = set()
    out = []
    for root in roots:
        userdata = os.path.join(root, "userdata")
        if not os.path.isdir(userdata):
            continue
        for account in os.listdir(userdata):
            if account == "0":
                continue
            config_dir = os.path.join(userdata, account, "config")
            if not os.path.isdir(config_dir):
                continue
            key = os.path.realpath(config_dir)
            if key in seen:
                continue
            seen.add(key)
            out.append(config_dir)
    return out


def config_vdf_paths(roots):
    seen = set()
    out = []
    for root in roots:
        path = os.path.join(root, "config", "config.vdf")
        if not os.path.exists(path):
            continue
        key = os.path.realpath(path)
        if key in seen:
            continue
        seen.add(key)
        out.append(path)
    return out


def backup(path):
    if os.path.exists(path) and not os.path.exists(path + ".cod-bak"):
        shutil.copy2(path, path + ".cod-bak")


def load_shortcuts(path):
    if os.path.exists(path):
        try:
            with open(path, "rb") as handle:
                data = vdf.binary_load(handle)
        except Exception as error:
            sys.stderr.write("cod-steam-add: cannot parse %s (%s) -- left untouched.\n" % (path, error))
            raise SystemExit(1)
    else:
        data = {}
    data.setdefault("shortcuts", {})
    return data


def write_binary(path, data):
    backup(path)
    tmp = path + ".cod-tmp"
    with open(tmp, "wb") as handle:
        vdf.binary_dump(data, handle)
    os.replace(tmp, path)


def is_ours(entry):
    tags = entry.get("tags", {})
    values = tags.values() if isinstance(tags, dict) else tags
    return TAG in values


def entry_name(entry):
    return entry.get("appname", entry.get("AppName", ""))


def make_entry(sc):
    exe = sc["exe"]
    return {
        "appid": shortcut_appid(exe, sc["name"]),
        "appname": sc["name"],
        "exe": '"' + exe + '"',
        "StartDir": '"' + sc.get("startdir", os.path.dirname(exe)) + '"',
        "icon": "",
        "ShortcutPath": "",
        "LaunchOptions": sc.get("launchopts", ""),
        "IsHidden": 0,
        "AllowDesktopConfig": 1,
        "AllowOverlay": 1,
        "OpenVR": 0,
        "Devkit": 0,
        "DevkitGameID": "",
        "DevkitOverrideAppID": 0,
        "LastPlayTime": 0,
        "tags": {"0": TAG},
    }


def next_key(shortcuts):
    keys = [int(k) for k in shortcuts.keys() if k.isdigit()]
    return str(max(keys, default=-1) + 1)


def set_compat_tool(config_paths, appids, tool):
    if not tool:
        return
    for path in config_paths:
        try:
            with open(path, encoding="utf-8") as handle:
                data = vdf.load(handle)
        except Exception as error:
            sys.stderr.write("cod-steam-add: cannot parse %s (%s) -- skipping compat tool.\n" % (path, error))
            continue
        store = data
        for key in ("InstallConfigStore", "Software", "Valve", "Steam"):
            store = store.setdefault(key, {})
        mapping = store.setdefault("CompatToolMapping", {})
        for appid in appids:
            mapping[str(unsigned32(appid))] = {"name": tool, "config": "", "priority": "250"}
        backup(path)
        tmp = path + ".cod-tmp"
        with open(tmp, "w", encoding="utf-8") as handle:
            vdf.dump(data, handle, pretty=True)
        os.replace(tmp, path)


def clear_compat_tool(config_paths, appids):
    wanted = {str(unsigned32(a)) for a in appids}
    for path in config_paths:
        try:
            with open(path, encoding="utf-8") as handle:
                data = vdf.load(handle)
        except Exception:
            continue
        store = data
        for key in ("InstallConfigStore", "Software", "Valve", "Steam"):
            store = store.get(key, {}) if isinstance(store, dict) else {}
        mapping = store.get("CompatToolMapping", {}) if isinstance(store, dict) else {}
        removed = [k for k in list(mapping.keys()) if k in wanted]
        for k in removed:
            del mapping[k]
        if removed:
            backup(path)
            tmp = path + ".cod-tmp"
            with open(tmp, "w", encoding="utf-8") as handle:
                vdf.dump(data, handle, pretty=True)
            os.replace(tmp, path)


def fetch_art(config_dir, appid, art_appid):
    grid = os.path.join(config_dir, "grid")
    os.makedirs(grid, exist_ok=True)
    for suffix, remote in ART_MAP.items():
        dest = os.path.join(grid, str(unsigned32(appid)) + suffix)
        if os.path.exists(dest):
            continue
        url = "%s/%s/%s" % (ART_HOST, art_appid, remote)
        try:
            with urllib.request.urlopen(url, timeout=20) as resp:
                if resp.status != 200:
                    continue
                body = resp.read()
            with open(dest, "wb") as handle:
                handle.write(body)
        except Exception:
            continue


def remove_art(config_dir, appid):
    grid = os.path.join(config_dir, "grid")
    for suffix in ART_MAP:
        path = os.path.join(grid, str(unsigned32(appid)) + suffix)
        if os.path.exists(path):
            os.remove(path)


def add(config_dirs, config_paths, shortcuts, tool):
    appids = [shortcut_appid(s["exe"], s["name"]) for s in shortcuts]
    for config_dir in config_dirs:
        path = os.path.join(config_dir, "shortcuts.vdf")
        data = load_shortcuts(path)
        table = data["shortcuts"]
        owned = {entry_name(e): key for key, e in table.items() if is_ours(e)}
        for sc in shortcuts:
            entry = make_entry(sc)
            if sc["name"] in owned:
                table[owned[sc["name"]]] = entry
            else:
                table[next_key(table)] = entry
            if sc.get("art_appid"):
                fetch_art(config_dir, entry["appid"], sc["art_appid"])
        write_binary(path, data)
        print("cod-steam-add: wrote %d shortcut(s) to %s" % (len(shortcuts), path))
    set_compat_tool(config_paths, appids, tool)
    if tool:
        print("cod-steam-add: set compat tool '%s' for %d app(s)" % (tool, len(appids)))


def remove(config_dirs, config_paths):
    removed_appids = []
    for config_dir in config_dirs:
        path = os.path.join(config_dir, "shortcuts.vdf")
        if not os.path.exists(path):
            continue
        data = load_shortcuts(path)
        kept = {}
        for entry in data["shortcuts"].values():
            if is_ours(entry):
                removed_appids.append(entry.get("appid", 0))
                remove_art(config_dir, entry.get("appid", 0))
                continue
            kept[str(len(kept))] = entry
        data["shortcuts"] = kept
        write_binary(path, data)
        print("cod-steam-add: removed cod shortcuts from %s" % path)
    clear_compat_tool(config_paths, removed_appids)


def show(config_dirs):
    for config_dir in config_dirs:
        path = os.path.join(config_dir, "shortcuts.vdf")
        if not os.path.exists(path):
            continue
        data = load_shortcuts(path)
        names = [entry_name(e) for e in data["shortcuts"].values() if is_ours(e)]
        print(path + ": " + (", ".join(names) if names else "(none)"))


def main():
    command = sys.argv[1] if len(sys.argv) > 1 else "add"
    payload = json.load(sys.stdin)
    roots = payload["roots"]
    config_dirs = userdata_dirs(roots)
    config_paths = config_vdf_paths(roots)
    if not config_dirs:
        sys.stderr.write("cod-steam-add: no Steam userdata/<id>/config found -- install Steam and log in once.\n")
        sys.exit(1)
    if command == "list":
        show(config_dirs)
        return
    if command == "remove":
        remove(config_dirs, config_paths)
    else:
        add(config_dirs, config_paths, payload["shortcuts"], payload.get("compat_tool", ""))
    print("cod-steam-add: restart Steam to apply.")


if __name__ == "__main__":
    main()
