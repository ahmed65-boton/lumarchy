#!/usr/bin/env bash

readonly -a AUR_PACKAGES=(
  google-chrome
  visual-studio-code-bin
  powershell-bin
)

ensure_build_user() {
  if ! id "${BUILD_USER}" >/dev/null 2>&1; then
    useradd --create-home --shell /bin/bash "${BUILD_USER}"
  fi

  install -d -m 0750 -o root -g root /etc/sudoers.d
  printf '%s ALL=(root) NOPASSWD: /usr/bin/pacman\n' "${BUILD_USER}" > /etc/sudoers.d/99-lumarchy-aurbuild
  chmod 0440 /etc/sudoers.d/99-lumarchy-aurbuild
  visudo -cf /etc/sudoers.d/99-lumarchy-aurbuild >/dev/null || die "Invalid temporary sudo policy."
}

remove_build_user_policy() {
  rm -f -- /etc/sudoers.d/99-lumarchy-aurbuild
}

build_one_aur_package() {
  local package=$1
  local package_dir="${AUR_BUILD_ROOT}/${package}"

  log "Fetching AUR package ${package}."
  git clone --depth 1 "https://aur.archlinux.org/${package}.git" "${package_dir}"
  chown -R "${BUILD_USER}:${BUILD_USER}" "${package_dir}"

  [[ -f ${package_dir}/PKGBUILD ]] || die "${package} has no PKGBUILD."
  runuser -u "${BUILD_USER}" -- bash -n "${package_dir}/PKGBUILD"

  log "Building ${package} as unprivileged user ${BUILD_USER}."
  runuser -u "${BUILD_USER}" -- env \
    HOME="$(getent passwd "${BUILD_USER}" | cut -d: -f6)" \
    MAKEFLAGS="-j$(nproc)" \
    bash -c 'cd "$1" && makepkg --syncdeps --noconfirm --needed --cleanbuild --clean' _ "${package_dir}"

  local found=0 package_file
  while IFS= read -r -d '' package_file; do
    install -m 0644 "${package_file}" "${CUSTOM_REPO_DIR}/"
    found=1
  done < <(find "${package_dir}" -maxdepth 1 -type f -name '*.pkg.tar.zst' -print0)
  (( found == 1 )) || die "${package} produced no .pkg.tar.zst package."
}

build_aur_repo() {
  require_root
  ensure_build_user
  trap remove_build_user_policy EXIT

  assert_child_path "${AUR_BUILD_ROOT}" /tmp
  safe_remove_tree "${AUR_BUILD_ROOT}" /tmp
  mkdir -p -- "${AUR_BUILD_ROOT}" "${CUSTOM_REPO_DIR}"
  chown "${BUILD_USER}:${BUILD_USER}" "${AUR_BUILD_ROOT}"

  find "${CUSTOM_REPO_DIR}" -maxdepth 1 -type f \
    \( -name '*.pkg.tar.zst' -o -name 'custom_repo.db*' -o -name 'custom_repo.files*' \) -delete

  local package
  for package in "${AUR_PACKAGES[@]}"; do
    build_one_aur_package "${package}"
  done

  local -a package_files=()
  mapfile -d '' package_files < <(repo_packages)
  (( ${#package_files[@]} > 0 )) || die "No packages were collected for ze local repository."
  repo-add "${CUSTOM_REPO_DIR}/custom_repo.db.tar.gz" "${package_files[@]}"
  [[ -e ${CUSTOM_REPO_DIR}/custom_repo.db ]] || die "repo-add did not create custom_repo.db."

  remove_build_user_policy
  trap - EXIT
  log "Local repository contains ${#package_files[@]} package archive(s)."
}
