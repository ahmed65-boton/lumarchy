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
  cat <<'EOF'
Usage: sudo ./lumarchy-build.sh COMMAND

Commands:
  check   Run non-destructive project checks
  aur     Build Chrome, VS Code, PowerShell, and Lumarchy's config package
  iso     Build ze ISO from an existing custom_repo
  all     Build packages and then ze ISO
  clean   Remove temporary build state (keeps custom_repo and output)
EOF
}

run_iso_pipeline() {
  preflight
  prepare_persistent_dirs
  mount_ramdisk
  trap cleanup_ramdisk EXIT
  stage_profile
  build_iso
  cleanup_ramdisk
  trap - EXIT
  verify_iso
  print_summary
}

clean_build_state() {
  require_root
  cleanup_ramdisk || true
  safe_remove_tree "${BUILD_STATE_DIR}" "${PROJECT_ROOT}"
  log "Removed temporary build state. custom_repo and output were kept."
}

main() {
  case "${1:-}" in
    check)
      "${PROJECT_ROOT}/tests/static-checks.sh"
      ;;
    aur)
      preflight
      prepare_persistent_dirs
      build_aur_repo
      ;;
    iso)
      run_iso_pipeline
      ;;
    all)
      preflight
      prepare_persistent_dirs
      build_aur_repo
      run_iso_pipeline
      ;;
    clean)
      clean_build_state
      ;;
    -h | --help | help)
      usage
      ;;
    *)
      usage >&2
      exit 2
      ;;
  esac
}

main "$@"
