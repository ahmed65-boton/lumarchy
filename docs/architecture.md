# Why Lumarchy v2 is different from ze first live ISO

Ze first Lumarchy image copied a few dotfiles into Archiso's `releng` profile and
autologged into Hyprland. That creates a useful live environment, but it does
not create an installed operating system.

Lumarchy v2 uses four layers:

1. **Archiso profile** — produces BIOS/UEFI boot media and ze live environment.
2. **Bundled repository** — contains Google Chrome, Visual Studio Code,
   PowerShell, and `lumarchy-config` package archives.
3. **Guided installer** — starts Archinstall with Lumarchy's packages and
   post-install commands preselected while leaving disk and account decisions
   to ze user.
4. **Desktop package** — installs ze same Hyprland, Waybar, launcher,
   notifications, lock screen, shortcuts, and wallpaper setup onto ze target
   disk.

This matches ze important shape of Omarchy's official ISO: it bundles packages,
collects configuration, installs Arch Linux, and runs target setup instead of
pretending ze writable live overlay is an installed system.

Primary references:

- [Official Omarchy ISO repository](https://github.com/omacom-io/omarchy-iso)
- [Official Omarchy repository](https://github.com/basecamp/omarchy)
- [Archiso profile documentation](https://github.com/archlinux/archiso/blob/master/docs/README.profile.rst)
- [Archinstall guided configuration](https://archinstall.archlinux.page/installing/guided.html)
- [Current Hyprpaper configuration](https://wiki.hypr.land/Hypr-Ecosystem/hyprpaper/)

Lumarchy does not copy Omarchy's branding or ship unwanted Omarchy application
choices. Chromium, Neovim, Vim, and Lazygit are explicitly filtered out.
