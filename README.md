# Lumarchy

Lumarchy is a reproducible Arch Linux live ISO with Hyprland, Quickshell,
Alacritty, Nautilus, Google Chrome, Visual Studio Code, PowerShell, networking,
Bluetooth and PipeWire. It builds inside an Arch-based GitHub Codespace so Arch
tools never install packages into an Ubuntu root filesystem.

## Repository structure

```text
lumarchy/
├── .devcontainer/              # Arch Linux Codespaces environment
├── lumarchy-build.sh           # Master six-stage pipeline
├── scripts/                    # Preflight, tmpfs, AUR, Archiso and checksums
├── profile/
│   ├── packages.x86_64         # Lumarchy packages merged with releng
│   ├── pacman.conf.append.in   # Local repository hook
│   ├── lumarchy-customize.sh   # liveuser and service setup
│   └── airootfs/               # Files copied into ze live system
├── tests/static-checks.sh
├── Makefile
└── output/                     # Generated ISO, checksum and log (ignored)
```

Ze build script copies Archiso's current `releng` profile at build time. This
keeps bootloader files compatible with ze installed Archiso version; Lumarchy
then merges its package manifest and `airootfs` overlay into that staged copy.

## Build in GitHub Codespaces

1. Push this repository to GitHub.
2. Open **Code → Codespaces → New with options**.
3. Choose a **4-core / 16 GB RAM** machine or larger.
4. Wait for `post-create.sh` to finish installing Archiso and validation tools.
5. In ze VS Code terminal, run:

   ```bash
   ./lumarchy-build.sh check
   sudo ./lumarchy-build.sh all 2>&1 | tee lumarchy-run.log
   ```

Ze complete build does this:

1. verifies Arch Linux, x86_64, commands, disk and RAM;
2. builds three AUR packages as unprivileged `aurbuild`;
3. indexes packages in `custom_repo/` using `repo-add`;
4. mounts a safe tmpfs (up to 8 GiB) and stages ze Archiso profile;
5. runs `mkarchiso`, checks its El Torito boot metadata and writes SHA-256;
6. unmounts tmpfs even when a later step fails.

Artifacts appear in:

```text
output/lumarchy-YYYY.MM.DD-x86_64.iso
output/lumarchy-YYYY.MM.DD-x86_64.iso.sha256
output/lumarchy-build.log
```

## Useful commands

```bash
make check                 # no root and no build
sudo ./lumarchy-build.sh aur
sudo ./lumarchy-build.sh iso
sudo ./lumarchy-build.sh clean
```

`iso` reuses `custom_repo/`, which saves time when only desktop configuration
changes. `clean` keeps ze AUR packages and final outputs. Set `KEEP_TMPFS=1` only
for debugging.

## Test safely

Download ze ISO and boot it in a virtual machine first. A simple QEMU BIOS test
on a Linux machine is:

```bash
qemu-system-x86_64 -enable-kvm -m 4096 -smp 4 \
  -boot d -cdrom output/lumarchy-*.iso
```

Also test UEFI boot using your VM application's UEFI/OVMF option before writing
ze image to USB hardware.

Ze live desktop logs in automatically as `liveuser`. Its password is empty and
its `wheel` sudo policy is passwordless, which is convenient for a live ISO but
must not be copied unchanged into an installed production system.

## AUR trust note

AUR PKGBUILDs are user-produced build instructions. Ze script clones their
current Git state and builds without root, but you should still inspect each
PKGBUILD and its commit before distributing an ISO. Binary packages are placed
in a local repository configured with `Optional TrustAll`; that trust setting is
limited to packages built by this pipeline.

## Blueprint adjustments

- Ze builder is Arch-based, avoiding Ubuntu/Pacman filesystem mixing.
- Paths are repository-relative, so Codespaces repo names do not break builds.
- Ze official Archiso releng profile supplies compatible boot files.
- Ze requested Nord SDDM theme is not declared because no Nord theme package is
  in ze package manifest; SDDM uses its installed default instead of referencing
  a missing theme.
- VS Code MIME entries use `visual-studio-code.desktop`, ze desktop file shipped
  by `visual-studio-code-bin`.

## License

MIT. Packages and desktop components retain their own licenses.
