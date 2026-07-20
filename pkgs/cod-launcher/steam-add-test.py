import importlib.util
import os
import sys
import tempfile

import vdf

spec = importlib.util.spec_from_file_location("steam_add", sys.argv[1])
sa = importlib.util.module_from_spec(spec)
spec.loader.exec_module(sa)

tmp = tempfile.mkdtemp()
cfg = os.path.join(tmp, "userdata", "7", "config")
os.makedirs(cfg)
scpath = os.path.join(cfg, "shortcuts.vdf")
with open(scpath, "wb") as handle:
    vdf.binary_dump(
        {"shortcuts": {"0": {"appid": 42, "appname": "MyGame", "exe": '"/usr/bin/mygame"', "tags": {}}}},
        handle,
    )

files = sa.userdata_shortcut_files([tmp, os.path.join(tmp, "missing")])
assert files == [scpath], files

os.makedirs(os.path.join(tmp, "userdata", "0", "config"))
link_root = tmp + "_link"
os.symlink(tmp, link_root)
assert sa.userdata_shortcut_files([tmp, link_root]) == [scpath], "dedup/skip-0 failed"

launchers = [
    {"exe": "/nix/x/bin/cod-plutonium", "display": "Plutonium"},
    {"exe": "/nix/x/bin/cod-t7x", "display": "Call of Duty: Black Ops III (t7x)"},
]
sa.add(files, launchers)

with open(scpath, "rb") as handle:
    after_add = vdf.binary_load(handle)
names = sorted(sa.entry_name(e) for e in after_add["shortcuts"].values())
assert names == sorted(["MyGame", "Plutonium", "Call of Duty: Black Ops III (t7x)"]), names
assert os.path.exists(scpath + ".cod-bak"), "backup not written"

sa.add(files, launchers)
with open(scpath, "rb") as handle:
    after_readd = vdf.binary_load(handle)
assert len(after_readd["shortcuts"]) == 3, ("re-add duplicated", len(after_readd["shortcuts"]))

pluto = next(e for e in after_readd["shortcuts"].values() if sa.entry_name(e) == "Plutonium")
assert pluto["exe"] == '"/nix/x/bin/cod-plutonium"', pluto["exe"]
assert pluto["StartDir"] == '"/nix/x/bin"', pluto["StartDir"]
assert isinstance(pluto["appid"], int) and -(2**31) <= pluto["appid"] < 2**31, pluto["appid"]
assert sa.is_ours(pluto), "cod entry not tagged"

mygame = next(e for e in after_readd["shortcuts"].values() if sa.entry_name(e) == "MyGame")
assert not sa.is_ours(mygame), "foreign shortcut wrongly claimed"

sa.remove(files)
with open(scpath, "rb") as handle:
    after_remove = vdf.binary_load(handle)
assert [sa.entry_name(e) for e in after_remove["shortcuts"].values()] == ["MyGame"], after_remove

print("steam-add logic: OK")
