#!/usr/bin/env bash
set -Eeuo pipefail

if [[ ${EUID} -ne 0 ]]; then
  printf 'post-create must run as root\n' >&2
  exit 1
fi

pacman -Syu --needed --noconfirm \
  archiso \
  base-devel \
  git \
  shellcheck \
  shfmt \
  sudo

printf '\nLumarchy builder ready. Run: sudo ./lumarchy-build.sh all\n'
