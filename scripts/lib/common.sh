#!/usr/bin/env bash

PROJECT_ROOT=${PROJECT_ROOT:-"$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P)"}
BUILD_STATE_DIR=${BUILD_STATE_DIR:-"${PROJECT_ROOT}/.build"}
CUSTOM_REPO_DIR=${CUSTOM_REPO_DIR:-"${PROJECT_ROOT}/custom_repo"}
OUTPUT_DIR=${OUTPUT_DIR:-"${PROJECT_ROOT}/output"}
TMPFS_MOUNT=${TMPFS_MOUNT:-/mnt/archiso_tmpfs}
TMPFS_SIZE=${TMPFS_SIZE:-8G}
AUR_BUILD_ROOT=${AUR_BUILD_ROOT:-/tmp/lumarchy-aur-builds}
STAGED_PROFILE=${STAGED_PROFILE:-"${TMPFS_MOUNT}/profile"}
ARCHISO_WORK_DIR=${ARCHISO_WORK_DIR:-"${BUILD_STATE_DIR}/archiso-work"}
ARCHISO_BASE_PROFILE=${ARCHISO_BASE_PROFILE:-/usr/share/archiso/configs/releng}
BUILD_USER=${BUILD_USER:-aurbuild}
LAST_ISO=

log() {
  printf '\033[1;36m[Lumarchy]\033[0m %s\n' "$*"
}

warn() {
  printf '\033[1;33m[Lumarchy warning]\033[0m %s\n' "$*" >&2
}

die() {
  printf '\033[1;31m[Lumarchy error]\033[0m %s\n' "$*" >&2
  exit 1
}

require_root() {
  [[ ${EUID} -eq 0 ]] || die "Run this command with sudo."
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "Missing command '$1'. Rebuild ze dev container."
}

canonical_path() {
  realpath -m -- "$1"
}

assert_child_path() {
  local child parent
  child=$(canonical_path "$1")
  parent=$(canonical_path "$2")
  [[ ${child} == "${parent}/"* ]] || die "Refusing unsafe path outside ${parent}: ${child}"
  [[ ${child} != "${parent}" ]] || die "Refusing to operate on parent directory ${parent}."
}

safe_remove_tree() {
  local target=$1
  local allowed_parent=$2
  assert_child_path "${target}" "${allowed_parent}"
  if [[ -e ${target} ]]; then
    rm -rf -- "${target}"
  fi
}

prepare_persistent_dirs() {
  mkdir -p -- "${BUILD_STATE_DIR}" "${CUSTOM_REPO_DIR}" "${OUTPUT_DIR}"
}

repo_packages() {
  find "${CUSTOM_REPO_DIR}" -maxdepth 1 -type f -name '*.pkg.tar.zst' -print0
}

print_summary() {
  local checksum_file="${LAST_ISO}.sha256"
  log "Build complete."
  printf '  ISO:      %s\n' "${LAST_ISO}"
  printf '  SHA-256:  %s\n' "${checksum_file}"
  printf '  AUR repo: %s\n' "${CUSTOM_REPO_DIR}"
}
