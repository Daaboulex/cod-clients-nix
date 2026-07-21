import json
import os
import shutil
import sys
import zlib

import vdf

TAG = "cod-clients-nix"


def shortcut_appid(exe, name):
    crc = zlib.crc32((exe + name).encode("utf-8")) & 0xFFFFFFFF
    value = crc | 0x80000000
    return value - 0x100000000 if value >= 0x80000000 else value


def userdata_shortcut_files(roots):
    seen = set()
    files = []
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
            files.append(os.path.join(config_dir, "shortcuts.vdf"))
    return files


def load_shortcuts(path):
    if os.path.exists(path):
        try:
            with open(path, "rb") as handle:
                data = vdf.binary_load(handle)
        except Exception as error:
            sys.stderr.write(
                "cod-steam-add: cannot parse " + path + " (" + str(error) + ") -- left untouched.\n"
            )
            raise SystemExit(1)
    else:
        data = {}
    data.setdefault("shortcuts", {})
    return data


def write_shortcuts(path, data):
    if os.path.exists(path) and not os.path.exists(path + ".cod-bak"):
        shutil.copy2(path, path + ".cod-bak")
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


def make_entry(exe, name):
    return {
        "appid": shortcut_appid(exe, name),
        "appname": name,
        "exe": '"' + exe + '"',
        "StartDir": '"' + os.path.dirname(exe) + '"',
        "icon": "",
        "ShortcutPath": "",
        "LaunchOptions": "",
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
    keys = [int(key) for key in shortcuts.keys() if key.isdigit()]
    return str(max(keys, default=-1) + 1)


def add(files, launchers):
    for path in files:
        os.makedirs(os.path.dirname(path), exist_ok=True)
        data = load_shortcuts(path)
        shortcuts = data["shortcuts"]
        owned = {entry_name(e): key for key, e in shortcuts.items() if is_ours(e)}
        for item in launchers:
            entry = make_entry(item["exe"], item["display"])
            if item["display"] in owned:
                shortcuts[owned[item["display"]]] = entry
            else:
                shortcuts[next_key(shortcuts)] = entry
        write_shortcuts(path, data)
        print("cod-steam-add: wrote " + str(len(launchers)) + " client(s) to " + path)


def remove(files):
    for path in files:
        if not os.path.exists(path):
            continue
        data = load_shortcuts(path)
        kept = {}
        removed = 0
        for entry in data["shortcuts"].values():
            if is_ours(entry):
                removed += 1
                continue
            kept[str(len(kept))] = entry
        data["shortcuts"] = kept
        write_shortcuts(path, data)
        print("cod-steam-add: removed " + str(removed) + " client(s) from " + path)


def show(files):
    for path in files:
        if not os.path.exists(path):
            continue
        data = load_shortcuts(path)
        names = [entry_name(e) for e in data["shortcuts"].values() if is_ours(e)]
        print(path + ": " + (", ".join(names) if names else "(none)"))


def main():
    command = sys.argv[1] if len(sys.argv) > 1 else "add"
    payload = json.load(sys.stdin)
    files = userdata_shortcut_files(payload["roots"])
    if not files:
        sys.stderr.write(
            "cod-steam-add: no Steam userdata/<id>/config found -- install Steam and log in once.\n"
        )
        sys.exit(1)
    if command == "list":
        show(files)
        return
    if command == "remove":
        remove(files)
    else:
        add(files, payload["launchers"])
    print("cod-steam-add: restart Steam to apply.")


if __name__ == "__main__":
    main()
