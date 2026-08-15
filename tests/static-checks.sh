#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
failures=0

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  failures=$((failures + 1))
}

while IFS= read -r -d '' script; do
  bash -n "${script}" || fail "Bash syntax: ${script#"${PROJECT_ROOT}/"}"
done < <(find "${PROJECT_ROOT}" -type f -name '*.sh' -print0)

if command -v shellcheck >/dev/null 2>&1; then
  shellcheck -x -P "${PROJECT_ROOT}" \
    "${PROJECT_ROOT}/lumarchy-build.sh" \
    "${PROJECT_ROOT}/.devcontainer/post-create.sh" \
    "${PROJECT_ROOT}/profile/lumarchy-customize.sh" \
    "${PROJECT_ROOT}/tests/static-checks.sh" \
    || fail "ShellCheck"
else
  printf 'SKIP: shellcheck is installed automatically inside ze dev container.\n'
fi

required_packages=(
  google-chrome
  visual-studio-code-bin
  powershell-bin
  hyprland
  quickshell
  alacritty
)
for package in "${required_packages[@]}"; do
  grep -qx "${package}" "${PROJECT_ROOT}/profile/packages.x86_64" \
    || fail "Missing required package ${package}"
done

for package in neovim vim chromium lazygit; do
  if grep -Eq "^[[:space:]]*${package}([[:space:]]|$)" "${PROJECT_ROOT}/profile/packages.x86_64"; then
    fail "Blacklisted package appears in manifest: ${package}"
  fi
done

grep -q 'User=liveuser' "${PROJECT_ROOT}/profile/airootfs/etc/sddm.conf.d/autologin.conf" \
  || fail "SDDM autologin user"
grep -q 'bind = \$mainMod, E, exec, code' "${PROJECT_ROOT}/profile/airootfs/etc/skel/.config/hypr/hyprland.conf" \
  || fail "VS Code Hyprland binding"

if (( failures > 0 )); then
  printf '%s static check(s) failed.\n' "${failures}" >&2
  exit 1
fi

printf 'All Lumarchy static checks passed.\n'
