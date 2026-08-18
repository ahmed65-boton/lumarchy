#!/usr/bin/env bash
set -Eeuo pipefail

live_user=liveuser

sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
locale-gen
printf 'LANG=en_US.UTF-8\n' > /etc/locale.conf
ln -sf /usr/share/zoneinfo/UTC /etc/localtime

if ! id "${live_user}" >/dev/null 2>&1; then
  useradd --create-home --shell /bin/zsh "${live_user}"
fi

for group in wheel audio video storage optical; do
  if getent group "${group}" >/dev/null; then
    usermod -aG "${group}" "${live_user}"
  fi
done

passwd -d "${live_user}"
chage -E -1 "${live_user}"
install -d -m 0750 /etc/sudoers.d
printf '%%wheel ALL=(ALL:ALL) NOPASSWD: ALL\n' > /etc/sudoers.d/10-liveuser
chmod 0440 /etc/sudoers.d/10-liveuser

chown -R "${live_user}:${live_user}" "/home/${live_user}"
chmod 0755 /usr/local/bin/lumarchy-*

systemctl enable NetworkManager.service
systemctl enable bluetooth.service
systemctl enable sddm.service
systemctl enable systemd-timesyncd.service
systemctl set-default graphical.target
