#!/bin/bash
set -euo pipefail

# Run INSIDE chroot. Usage: ./06-build-kernel.sh <student_login>

STUDENT_LOGIN="${1:?Usage: $0 <student_login>}"
MAKEFLAGS="-j$(nproc)"

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

log() { echo -e "${GREEN}[$(date +%H:%M:%S)]${NC} $*"; }

KERNEL_TAR=$(ls /sources/linux-*.tar.xz 2>/dev/null | head -1)
if [ -z "$KERNEL_TAR" ]; then
    echo -e "${RED}Kernel source tarball not found in /sources/${NC}"
    exit 1
fi

KERNEL_VERSION=$(basename "$KERNEL_TAR" | sed 's/linux-//;s/.tar.xz//')
KERNEL_SRC="/usr/src/kernel-${KERNEL_VERSION}"
KERNEL_NAME="vmlinuz-${KERNEL_VERSION}-${STUDENT_LOGIN}"

log "Kernel version: $KERNEL_VERSION"
log "Student login:  $STUDENT_LOGIN"
log "Source dir:     $KERNEL_SRC"
log "Kernel name:    $KERNEL_NAME"
echo ""

mkdir -pv "$KERNEL_SRC"
tar -xf "$KERNEL_TAR" -C /usr/src/
mv /usr/src/linux-*/* "$KERNEL_SRC/" 2>/dev/null || true
rm -rf /usr/src/linux-"${KERNEL_VERSION}"
cd "$KERNEL_SRC"

make mrproper

# In menuconfig set: General Setup -> Local version = -<student_login>
# Enable: loadable modules, devtmpfs, ext4, proc, sysfs, tmpfs, TCP/IP, VM NIC driver
log "Starting menuconfig..."
make menuconfig

log "Building kernel..."
make $MAKEFLAGS

log "Installing modules..."
make modules_install

cp -v arch/x86/boot/bzImage "/boot/${KERNEL_NAME}"
cp -v System.map "/boot/System.map-${KERNEL_VERSION}-${STUDENT_LOGIN}"
cp -v .config "/boot/config-${KERNEL_VERSION}-${STUDENT_LOGIN}"

echo ""
log "Kernel build complete!"
log "  Kernel:     /boot/${KERNEL_NAME}"
log "  System.map: /boot/System.map-${KERNEL_VERSION}-${STUDENT_LOGIN}"
log "  Sources:    ${KERNEL_SRC}"
log "  uname -r:   ${KERNEL_VERSION}-${STUDENT_LOGIN}"
