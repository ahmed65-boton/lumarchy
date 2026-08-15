#!/usr/bin/env bash

verify_iso() {
  local -a iso_files=()
  mapfile -d '' iso_files < <(find "${OUTPUT_DIR}" -maxdepth 1 -type f -name 'lumarchy-*.iso' -print0)
  (( ${#iso_files[@]} == 1 )) || die "Expected exactly one Lumarchy ISO, found ${#iso_files[@]}."

  LAST_ISO=${iso_files[0]}
  [[ -s ${LAST_ISO} ]] || die "Generated ISO is empty."
  (( $(stat -c %s "${LAST_ISO}") > 500 * 1024 * 1024 )) || die "Generated ISO is suspiciously smaller than 500 MiB."

  local iso_name boot_report
  iso_name=$(basename -- "${LAST_ISO}")
  (cd -- "${OUTPUT_DIR}" && sha256sum "${iso_name}") > "${LAST_ISO}.sha256"
  (cd -- "${OUTPUT_DIR}" && sha256sum --check "${iso_name}.sha256")

  boot_report=$(xorriso -indev "${LAST_ISO}" -report_el_torito plain 2>&1) \
    || die "xorriso could not inspect ze ISO boot metadata."
  grep -q 'El Torito boot img' <<< "${boot_report}" \
    || die "Generated ISO has no El Torito boot image."

  if [[ -n ${SUDO_UID:-} && -n ${SUDO_GID:-} ]]; then
    chown "${SUDO_UID}:${SUDO_GID}" "${LAST_ISO}" "${LAST_ISO}.sha256" "${OUTPUT_DIR}/lumarchy-build.log"
  fi
  log "ISO checksum and boot metadata verified."
}
