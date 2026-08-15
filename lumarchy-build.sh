#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"

# shellcheck source=scripts/lib/common.sh
source "${PROJECT_ROOT}/scripts/lib/common.sh"
# shellcheck source=scripts/preflight.sh
source "${PROJECT_ROOT}/scripts/preflight.sh"
# shellcheck source=scripts/ramdisk.sh
source "${PROJECT_ROOT}/scripts/ramdisk.sh"
# shellcheck source=scripts/build-aur.sh
source "${PROJECT_ROOT}/scripts/build-aur.sh"
# shellcheck source=scripts/stage-profile.sh
source "${PROJECT_ROOT}/scripts/stage-profile.sh"
# shellcheck source=scripts/build-iso.sh
source "${PROJECT_ROOT}/scripts/build-iso.sh"
# shellcheck source=scripts/verify.sh
source "${PROJECT_ROOT}/scripts/verify.sh"

usage() {
  cat <<'USAGE'
Lumarchy Archiso builder

Usage:
  ./lumarchy-build.sh check
  sudo ./lumarchy-build.sh all
  sudo ./lumarchy-build.sh aur
  sudo ./lumarchy-build.sh iso
  sudo ./lumarchy-build.sh clean

Commands:
  check  Run static checks without changing ze host.
  all    Build AUR packages, stage ze profile, build and verify ze ISO.
  aur    Build only google-chrome, visual-studio-code-bin and powershell-bin.
  iso    Use ze existing custom_repo to build and verify ze ISO.
  clean  Unmount ze Lumarchy tmpfs and remove transient build state.

Environment overrides:
  TMPFS_SIZE=8G             Requested tmpfs size (default: 8G).
  TMPFS_MOUNT=/mnt/...      RAM-disk mount point.
  AUR_BUILD_ROOT=/tmp/...   Temporary AUR source directory.
  KEEP_TMPFS=1              Leave ze RAM disk mounted after a build.
USAGE
}

cleanup_on_exit() {
  local status=$?
  if [[ ${KEEP_TMPFS:-0} != 1 ]]; then
    cleanup_ramdisk || true
  fi
  exit "${status}"
}

run_iso_pipeline() {
  preflight
  prepare_persistent_dirs
  mount_ramdisk
  trap cleanup_on_exit EXIT INT TERM
  stage_profile
  build_iso
  verify_iso
  print_summary
}

main() {
  local command=${1:-help}
  case "${command}" in
    check)
      "${PROJECT_ROOT}/tests/static-checks.sh"
      ;;
    all)
      preflight
      prepare_persistent_dirs
      build_aur_repo
      mount_ramdisk
      trap cleanup_on_exit EXIT INT TERM
      stage_profile
      build_iso
      verify_iso
      print_summary
      ;;
    aur)
      preflight
      prepare_persistent_dirs
      build_aur_repo
      ;;
    iso)
      run_iso_pipeline
      ;;
    clean)
      require_root
      cleanup_ramdisk
      safe_remove_tree "${BUILD_STATE_DIR}" "${PROJECT_ROOT}"
      log "Transient Lumarchy build state removed; output and custom_repo were kept."
      ;;
    help|-h|--help)
      usage
      ;;
    *)
      usage >&2
      die "Unknown command: ${command}"
      ;;
  esac
}

main "$@"
