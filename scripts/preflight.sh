#!/usr/bin/env bash

preflight() {
  require_root

  [[ -r /etc/os-release ]] || die "Cannot identify ze builder operating system."
  # shellcheck disable=SC1091
  source /etc/os-release
  [[ ${ID:-} == arch ]] || die "Lumarchy must build inside ze Arch dev container, not ${PRETTY_NAME:-this host}."
  [[ $(uname -m) == x86_64 ]] || die "Only x86_64 builders are supported."

  local command
  for command in awk bash find git makepkg mkarchiso mount mountpoint pacman repo-add runuser sha256sum sort umount xorriso; do
    require_cmd "${command}"
  done

  [[ -d ${ARCHISO_BASE_PROFILE} ]] || die "Archiso releng profile not found at ${ARCHISO_BASE_PROFILE}."
  [[ ${PROJECT_ROOT} != *' '* ]] || die "Move ze repository to a path without spaces."

  local free_kib available_kib
  free_kib=$(df -Pk "${PROJECT_ROOT}" | awk 'NR == 2 {print $4}')
  available_kib=$(awk '/^MemAvailable:/ {print $2}' /proc/meminfo)
  (( free_kib >= 15 * 1024 * 1024 )) || die "At least 15 GiB of free disk space is required."
  (( available_kib >= 6 * 1024 * 1024 )) || die "At least 6 GiB of available RAM is required; 16 GiB is recommended."

  log "Preflight passed on ${PRETTY_NAME}; disk and memory look usable."
}
