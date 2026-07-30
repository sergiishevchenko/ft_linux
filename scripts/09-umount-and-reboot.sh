#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

LFS="${LFS:-/mnt/lfs}"

require_root
require_dir "$LFS"

log "Unmounting virtual filesystems under $LFS..."

umount_safe() {
    local target="$1"
    if mountpoint -q "$target" 2>/dev/null || mount | grep -q " $target "; then
        umount -v "$target" || warn "Failed to unmount $target"
    else
        log "Not mounted: $target"
    fi
}

umount_safe "$LFS/dev/pts"
umount_safe "$LFS/dev/shm"
umount_safe "$LFS/dev"
umount_safe "$LFS/run"
umount_safe "$LFS/proc"
umount_safe "$LFS/sys"
umount_safe "$LFS/boot"
umount_safe "$LFS"

if command -v swapoff >/dev/null; then
    swapoff -a 2>/dev/null || true
fi

log "All mounts cleared."
log "You can now reboot into ft_linux:"
log "  reboot"
