# Development

## Commands

```bash
nix develop
nix fmt
nix build .#cod-plutonium
nix build .#cod-t7x
nix build .#cod-steamlink
nix flake check
```

- `nix develop` enters the dev shell, which carries the git hooks and the nil
  language server.
- `nix fmt` formats the Nix files with nixfmt-rfc-style.
- `nix build .#<name>` builds one launcher or helper. Every `cod-*` command is
  a package of the same name, and `default` is `cod-plutonium`.
- `nix flake check` runs the evaluation, the builds, std-conformance and the
  module evaluation.

## Checks this flake declares

| Check | What it covers |
|---|---|
| `module-eval-hm` | Evaluates the Home Manager module with every client and helper enabled |
| `sub-proton-build` | Builds CB Launcher with a `cblauncher.subProton` entry |
| `steam-add-logic` | Runs `pkgs/cod-launcher/steam-add-test.py` against `steam-add.py` |
| `steam-native-logic` | Runs `pkgs/cod-launcher/steam-native-test.py` against `steam-native.py` |

## Platform and inputs

The flake builds for `x86_64-linux` only and follows nixpkgs `nixos-unstable`.
There is no aarch64 build: these are Windows game clients under Proton and
Wine, and umu-launcher and proton-ge-bin are x86_64 only.

## CI

CI runs from [ci.yml](../.github/workflows/ci.yml). The scheduled lock refresh
runs from [maintenance.yml](../.github/workflows/maintenance.yml). The
workflows and what the standard supplies are described in
[ARCHITECTURE.md](../ARCHITECTURE.md), which also has the steps for adding a
client.
