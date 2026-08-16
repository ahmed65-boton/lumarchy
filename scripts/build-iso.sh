#!/usr/bin/env bash

build_iso() {
  require_root
  [[ -x ${STAGED_PROFILE}/profiledef.sh ]] || die "Staged profile is incomplete."

  safe_remove_tree "${ARCHISO_WORK_DIR}" "${BUILD_STATE_DIR}"
  mkdir -p -- "${ARCHISO_WORK_DIR}" "${OUTPUT_DIR}"
  find "${OUTPUT_DIR}" -maxdepth 1 -type f \
    \( -name 'lumarchy-*.iso' -o -name 'lumarchy-*.iso.sha256' \) -delete

  log "Starting mkarchiso. This is ze long boss-battle step."
  mkarchiso -v \
    -w "${ARCHISO_WORK_DIR}" \
    -o "${OUTPUT_DIR}" \
    "${STAGED_PROFILE}" \
    2>&1 | tee "${OUTPUT_DIR}/lumarchy-build.log"
}
