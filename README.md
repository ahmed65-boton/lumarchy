# Lumarchy

Lumarchy is an installable Arch Linux ISO with a polished Hyprland desktop. It
uses your three wallpapers and preinstalls Google Chrome, Visual Studio Code,
Git, Python, and PowerShell. It intentionally excludes Chromium, Neovim, Vim,
and Lazygit.

## Build in GitHub Codespaces

1. Push this repository to GitHub.
2. Create a **4-core / 16-GB** Codespace.
3. Wait for ze Arch Linux dev container setup to finish.
4. Run:

   ```bash
   ./lumarchy-build.sh check
   sudo ./lumarchy-build.sh all 2>&1 | tee lumarchy-run.log
   ```

Ze ISO and checksum are written to `output/`. After desktop or wallpaper
changes, rebuild `lumarchy-config` and ze ISO so both ze live session and ze
installed system receive them:

```bash
sudo ./lumarchy-build.sh clean
sudo ./lumarchy-build.sh all 2>&1 | tee lumarchy-run.log
```

Use `iso` without `aur` only for Archiso-only changes when `custom_repo` is
already complete.

## Use Lumarchy

Boot ze ISO. Ze live desktop starts automatically. Press `Super+Space` for ze
application launcher or click **Install** in ze top bar to start ze guided disk
installer. Review ze disk choice carefully: installation can erase a disk.

Important shortcuts:

| Shortcut | Action |
| --- | --- |
| `Super+Space` | Application launcher |
| `Super+Enter` | Terminal |
| `Super+B` | Google Chrome |
| `Super+E` | Visual Studio Code |
| `Super+F` | Files |
| `Super+Ctrl+Space` | Next Lumarchy wallpaper |
| `Super+L` | Lock screen |
| `Print` | Screenshot a region |

## Cloud test

After building, run `scripts/cloud-test.sh`. It starts QEMU and noVNC on port
6080. Forward that port privately in Codespaces and open:

```text
/vnc.html?autoconnect=1&resize=scale
```

Ze installer is based on Archinstall's guided flow. Lumarchy supplies its
package list and post-install setup, while Archinstall collects disk, account,
locale, and bootloader choices.
