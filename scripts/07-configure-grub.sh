#!/bin/bash
set -euo pipefail

# Run INSIDE chroot. Usage: ./07-configure-grub.sh <student_login> [disk] [root_part]

STUDENT_LOGIN="${1:?Usage: $0 <student_login>}"
BOOT_DISK="${2:-/dev/sda}"
ROOT_PART="${3:-/dev/sda2}"

GREEN='\033[0;32m'
NC='\033[0m'

log() { echo -e "${GREEN}[+]${NC} $*"; }

KERNEL=$(ls /boot/vmlinuz-*-"${STUDENT_LOGIN}" 2>/dev/null | head -1)
if [ -z "$KERNEL" ]; then
    echo "No kernel found matching /boot/vmlinuz-*-${STUDENT_LOGIN}"
    exit 1
fi

KERNEL_FILE=$(basename "$KERNEL")
KERNEL_VERSION=$(echo "$KERNEL_FILE" | sed "s/vmlinuz-//;s/-${STUDENT_LOGIN}//")

log "Kernel: $KERNEL_FILE"
log "Disk:   $BOOT_DISK"
log "Root:   $ROOT_PART"
echo ""

log "Installing GRUB to $BOOT_DISK..."
grub-install "$BOOT_DISK"

cat > /boot/grub/grub.cfg << GRUBEOF
set default=0
set timeout=5

insmod ext2

menuentry "ft_linux ${KERNEL_VERSION}-${STUDENT_LOGIN}" {
    set root=(hd0,2)
    linux /boot/${KERNEL_FILE} root=${ROOT_PART} ro
}
GRUBEOF

log "GRUB config:"
cat /boot/grub/grub.cfg

echo ""
log "GRUB installation complete!"
