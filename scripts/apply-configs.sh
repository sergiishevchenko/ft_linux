#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

source "$SCRIPT_DIR/lib.sh"

DEFAULT_LOGIN="sshevche"
if [ -f "$REPO_ROOT/LOGIN" ]; then
    DEFAULT_LOGIN="$(tr -d '[:space:]' < "$REPO_ROOT/LOGIN")"
fi

STUDENT_LOGIN="${1:-$DEFAULT_LOGIN}"
TARGET_ROOT="${2:-${LFS:-/mnt/lfs}}"
CONFIGS="$REPO_ROOT/configs"
LINUX_VERSION="${LINUX_VERSION:-6.16.1}"

require_root
require_dir "$CONFIGS"
require_dir "$TARGET_ROOT"

log "Applying configs to $TARGET_ROOT"
log "Student login: $STUDENT_LOGIN"
log "Linux version: $LINUX_VERSION"

mkdir -pv "$TARGET_ROOT/etc"
mkdir -pv "$TARGET_ROOT/boot/grub"
mkdir -pv "$TARGET_ROOT/etc/sysconfig"

apply_file() {
    local src="$1"
    local dst="$2"
    cp -v "$src" "$dst"
    replace_placeholder "$dst" "<STUDENT_LOGIN>" "$STUDENT_LOGIN"
    replace_placeholder "$dst" "<LINUX_VERSION>" "$LINUX_VERSION"
}

apply_file "$CONFIGS/fstab"       "$TARGET_ROOT/etc/fstab"
apply_file "$CONFIGS/hostname"    "$TARGET_ROOT/etc/hostname"
apply_file "$CONFIGS/hosts"       "$TARGET_ROOT/etc/hosts"
apply_file "$CONFIGS/resolv.conf" "$TARGET_ROOT/etc/resolv.conf"
apply_file "$CONFIGS/locale.conf" "$TARGET_ROOT/etc/locale.conf"
apply_file "$CONFIGS/profile"     "$TARGET_ROOT/etc/profile"
apply_file "$CONFIGS/inputrc"     "$TARGET_ROOT/etc/inputrc"
apply_file "$CONFIGS/shells"      "$TARGET_ROOT/etc/shells"
apply_file "$CONFIGS/inittab"     "$TARGET_ROOT/etc/inittab"
apply_file "$CONFIGS/grub.cfg"    "$TARGET_ROOT/boot/grub/grub.cfg"

if [ -f "$CONFIGS/ifconfig.eth0" ]; then
    apply_file "$CONFIGS/ifconfig.eth0" "$TARGET_ROOT/etc/sysconfig/ifconfig.eth0"
fi

log "Configs applied. Review device names in /etc/fstab if needed."
