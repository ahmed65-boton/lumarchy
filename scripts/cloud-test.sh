#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
iso=${1:-}
if [[ -z ${iso} ]]; then
  mapfile -t images < <(find "${PROJECT_ROOT}/output" -maxdepth 1 -type f -name 'lumarchy-*.iso' -print)
  (( ${#images[@]} == 1 )) || {
    printf 'Expected one ISO in output; pass its path explicitly.\n' >&2
    exit 1
  }
  iso=${images[0]}
fi

for command in qemu-system-x86_64 git python; do
  command -v "${command}" >/dev/null || {
    printf "Missing %s. Install qemu-desktop git python first.\n" "${command}" >&2
    exit 1
  }
done

novnc=/tmp/lumarchy-noVNC
[[ -d ${novnc}/.git ]] || git clone --depth 1 https://github.com/novnc/noVNC.git "${novnc}"
[[ -e ${novnc}/utils/websockify ]] || git clone --depth 1 https://github.com/novnc/websockify.git "${novnc}/utils/websockify"

disk=/tmp/lumarchy-test.qcow2
[[ -e ${disk} ]] || qemu-img create -f qcow2 "${disk}" 48G

accel=tcg
cpu=max
if [[ -r /dev/kvm && -w /dev/kvm ]]; then
  accel=kvm
  cpu=host
fi

qemu-system-x86_64 \
  -name Lumarchy-Cloud-Test \
  -machine "q35,accel=${accel}" \
  -cpu "${cpu}" \
  -m 6144 \
  -smp 4 \
  -boot order=d \
  -cdrom "${iso}" \
  -drive "file=${disk},if=virtio,format=qcow2" \
  -device virtio-vga \
  -nic user,model=virtio-net-pci \
  -vnc 127.0.0.1:0 \
  -display none \
  -daemonize \
  -pidfile /tmp/lumarchy-qemu.pid

nohup "${novnc}/utils/novnc_proxy" --vnc localhost:5900 --listen 6080 \
  >/tmp/lumarchy-novnc.log 2>&1 &
printf '%s\n' "$!" >/tmp/lumarchy-novnc.pid
printf 'Lumarchy VM started. Forward private port 6080 and open /vnc.html?autoconnect=1&resize=scale\n'
