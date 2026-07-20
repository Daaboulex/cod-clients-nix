import importlib.util
import os
import sys
import tempfile

import vdf

spec = importlib.util.spec_from_file_location("steam_native", sys.argv[1])
sn = importlib.util.module_from_spec(spec)
spec.loader.exec_module(sn)

tmp = tempfile.mkdtemp()
cfg = os.path.join(tmp, "userdata", "7", "config")
os.makedirs(cfg)
scpath = os.path.join(cfg, "shortcuts.vdf")
with open(scpath, "wb") as handle:
    vdf.binary_dump(
        {"shortcuts": {"0": {"appid": 42, "appname": "MyGame", "exe": '"/usr/bin/mygame"', "tags": {}}}},
        handle,
    )
os.makedirs(os.path.join(tmp, "config"))
cvpath = os.path.join(tmp, "config", "config.vdf")
with open(cvpath, "w", encoding="utf-8") as handle:
    vdf.dump({"InstallConfigStore": {"Software": {"Valve": {"Steam": {}}}}}, handle, pretty=True)

os.makedirs(os.path.join(tmp, "userdata", "0", "config"))
link_root = tmp + "_link"
os.symlink(tmp, link_root)
roots = [tmp, link_root]

assert sn.userdata_dirs(roots) == [cfg], sn.userdata_dirs(roots)
assert sn.config_vdf_paths(roots) == [cvpath], sn.config_vdf_paths(roots)

shortcuts = [
    {
        "name": "Plutonium: BO2 MP",
        "exe": "/nix/x/plutonium.exe",
        "startdir": "/nix/x",
        "launchopts": "STEAM_COMPAT_DATA_PATH=/s %command% plutonium://play/t6mp",
        "art_appid": "",
    },
    {
        "name": "t7x: BO3",
        "exe": "/nix/y/game/t7x.exe",
        "startdir": "/nix/y/game",
        "launchopts": "STEAM_COMPAT_DATA_PATH=/nix/y %command%",
        "art_appid": "",
    },
]
cds = sn.userdata_dirs(roots)
cps = sn.config_vdf_paths(roots)
sn.add(cds, cps, shortcuts, "GE-Proton10-34")

with open(scpath, "rb") as handle:
    after = vdf.binary_load(handle)
names = sorted(sn.entry_name(e) for e in after["shortcuts"].values())
assert names == sorted(["MyGame", "Plutonium: BO2 MP", "t7x: BO3"]), names
assert os.path.exists(scpath + ".cod-bak"), "shortcuts backup missing"
pluto = next(e for e in after["shortcuts"].values() if sn.entry_name(e) == "Plutonium: BO2 MP")
assert "plutonium://play/t6mp" in pluto["LaunchOptions"], pluto["LaunchOptions"]
assert sn.is_ours(pluto)
assert not sn.is_ours(next(e for e in after["shortcuts"].values() if sn.entry_name(e) == "MyGame"))

with open(cvpath, encoding="utf-8") as handle:
    cv = vdf.load(handle)
mapping = cv["InstallConfigStore"]["Software"]["Valve"]["Steam"]["CompatToolMapping"]
appids = [str(sn.unsigned32(sn.shortcut_appid(s["exe"], s["name"]))) for s in shortcuts]
for appid in appids:
    assert appid in mapping and mapping[appid]["name"] == "GE-Proton10-34", (appid, mapping)
assert os.path.exists(cvpath + ".cod-bak"), "config.vdf backup missing"

sn.add(cds, cps, shortcuts, "GE-Proton10-34")
with open(scpath, "rb") as handle:
    readd = vdf.binary_load(handle)
assert len(readd["shortcuts"]) == 3, ("re-add duplicated", len(readd["shortcuts"]))

sn.remove(cds, cps)
with open(scpath, "rb") as handle:
    after_remove = vdf.binary_load(handle)
assert [sn.entry_name(e) for e in after_remove["shortcuts"].values()] == ["MyGame"], after_remove
with open(cvpath, encoding="utf-8") as handle:
    cv2 = vdf.load(handle)
mapping2 = (
    cv2.get("InstallConfigStore", {}).get("Software", {}).get("Valve", {}).get("Steam", {}).get("CompatToolMapping", {})
)
for appid in appids:
    assert appid not in mapping2, ("compat tool not cleared", appid)

print("steam-native logic: OK")
