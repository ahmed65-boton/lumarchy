#!/usr/bin/env bash

stage_profile() {
  require_root
  mountpoint -q -- "${TMPFS_MOUNT}" || die "Mount ze Lumarchy tmpfs before staging ze profile."
  [[ -e ${CUSTOM_REPO_DIR}/custom_repo.db ]] || die "Missing custom_repo database. Run ze 'aur' command first."

  safe_remove_tree "${STAGED_PROFILE}" "${TMPFS_MOUNT}"
  mkdir -p -- "${STAGED_PROFILE}"
  cp -a -- "${ARCHISO_BASE_PROFILE}/." "${STAGED_PROFILE}/"

  # Merge Lumarchy packages with releng, then enforce ze requested blacklist.
  awk 'NF && $1 !~ /^#/' \
    "${STAGED_PROFILE}/packages.x86_64" \
    "${PROJECT_ROOT}/profile/packages.x86_64" \
    | sort -u \
    | grep -Ev '^(neovim|vim|chromium|lazygit)$' \
    > "${STAGED_PROFILE}/packages.x86_64.new"
  mv -- "${STAGED_PROFILE}/packages.x86_64.new" "${STAGED_PROFILE}/packages.x86_64"

  cp -a -- "${PROJECT_ROOT}/profile/airootfs/." "${STAGED_PROFILE}/airootfs/"
  install -m 0755 "${PROJECT_ROOT}/profile/lumarchy-customize.sh" \
    "${STAGED_PROFILE}/airootfs/root/lumarchy-customize.sh"

  local customizer="${STAGED_PROFILE}/airootfs/root/customize_airootfs.sh"
  if [[ ! -f ${customizer} ]]; then
    printf '#!/usr/bin/env bash\nset -Eeuo pipefail\n' > "${customizer}"
  fi
  if ! grep -q 'lumarchy-customize.sh' "${customizer}"; then
    printf '\nbash /root/lumarchy-customize.sh\nrm -f /root/lumarchy-customize.sh\n' >> "${customizer}"
  fi
  chmod 0755 "${customizer}"

  local repo_uri="file://${CUSTOM_REPO_DIR}"
  sed "s|__CUSTOM_REPO_URI__|${repo_uri}|g" \
    "${PROJECT_ROOT}/profile/pacman.conf.append.in" >> "${STAGED_PROFILE}/pacman.conf"

  local build_date iso_label
  build_date=$(date -u +%Y.%m.%d)
  iso_label="LUMARCHY_$(date -u +%Y%m)"
  sed -i \
    -e "s/^iso_name=.*/iso_name=\"lumarchy\"/" \
    -e "s/^iso_label=.*/iso_label=\"${iso_label}\"/" \
    -e "s/^iso_publisher=.*/iso_publisher=\"Lumarchy Project <https:\/\/github.com\/YOUR-USERNAME\/lumarchy>\"/" \
    -e "s/^iso_application=.*/iso_application=\"Lumarchy Live ${build_date}\"/" \
    "${STAGED_PROFILE}/profiledef.sh"

  chmod 0755 "${STAGED_PROFILE}/profiledef.sh"
  log "Staged Lumarchy profile at ${STAGED_PROFILE}."
}
