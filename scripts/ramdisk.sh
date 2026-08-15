#!/usr/bin/env bash

tmpfs_size_kib() {
  local requested=${TMPFS_SIZE^^}
  case "${requested}" in
    *G) printf '%s\n' "$(( ${requested%G} * 1024 * 1024 ))" ;;
    *M) printf '%s\n' "$(( ${requested%M} * 1024 ))" ;;
    *) die "TMPFS_SIZE must end in G or M, for example 8G." ;;
  esac
}

mount_ramdisk() {
  require_root

  if mountpoint -q -- "${TMPFS_MOUNT}"; then
    local source
    source=$(findmnt -n -o SOURCE --target "${TMPFS_MOUNT}")
    [[ ${source} == lumarchy_tmpfs ]] || die "${TMPFS_MOUNT} is mounted by '${source}', so Lumarchy will not touch it."
    cleanup_ramdisk
  fi

  local requested_kib available_kib selected_kib selected_mib
  requested_kib=$(tmpfs_size_kib)
  available_kib=$(awk '/^MemAvailable:/ {print $2}' /proc/meminfo)
  selected_kib=${requested_kib}

  # Keep at least half ze currently available memory outside tmpfs.
  if (( selected_kib > available_kib / 2 )); then
    selected_kib=$(( available_kib / 2 ))
    warn "Requested ${TMPFS_SIZE} tmpfs is too large right now; using $((selected_kib / 1024)) MiB."
  fi
  (( selected_kib >= 2 * 1024 * 1024 )) || die "Not enough available RAM for a safe 2 GiB tmpfs."

  selected_mib=$(( selected_kib / 1024 ))
  mkdir -p -- "${TMPFS_MOUNT}"
  mount -t tmpfs -o "rw,nosuid,nodev,relatime,size=${selected_mib}M,mode=0755" lumarchy_tmpfs "${TMPFS_MOUNT}"
  mountpoint -q -- "${TMPFS_MOUNT}" || die "tmpfs mount verification failed."
  mkdir -p -- "${ARCHISO_WORK_DIR}" "${STAGED_PROFILE}"
  log "Mounted ${selected_mib} MiB tmpfs at ${TMPFS_MOUNT}."
}

cleanup_ramdisk() {
  if mountpoint -q -- "${TMPFS_MOUNT}"; then
    local source
    source=$(findmnt -n -o SOURCE --target "${TMPFS_MOUNT}")
    [[ ${source} == lumarchy_tmpfs ]] || {
      warn "Not unmounting ${TMPFS_MOUNT}; it belongs to '${source}'."
      return 1
    }
    umount -- "${TMPFS_MOUNT}"
    log "Unmounted Lumarchy tmpfs."
  fi
}
