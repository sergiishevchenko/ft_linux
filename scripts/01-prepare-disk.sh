#!/bin/bash
set -euo pipefail

# Run as root. Will ask for confirmation before writing.

DISK="${1:-/dev/sda}"
LFS="${LFS:-/mnt/lfs}"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log()  { echo -e "${GREEN}[+]${NC} $*"; }
warn() { echo -e "${YELLOW}[!]${NC} $*"; }

if [ "$(id -u)" -ne 0 ]; then
    echo -e "${RED}This script must be run as root.${NC}"
    exit 1
fi

echo "============================================"
echo "  ft_linux Disk Preparation"
echo "  Target disk: $DISK"
echo "============================================"
echo ""
warn "This will ERASE ALL DATA on $DISK!"
echo ""
read -p "Continue? (type YES to confirm): " CONFIRM
if [ "$CONFIRM" != "YES" ]; then
    echo "Aborted."
    exit 0
fi

log "Creating partitions on $DISK..."
parted -s "$DISK" mklabel msdos
parted -s "$DISK" mkpart primary ext2 1MiB 501MiB
parted -s "$DISK" set 1 boot on
parted -s "$DISK" mkpart primary ext4 501MiB -2GiB
parted -s "$DISK" mkpart primary linux-swap -2GiB 100%

log "Formatting partitions..."
mkfs.ext2  "${DISK}1"
mkfs.ext4  "${DISK}2"
mkswap     "${DISK}3"

log "Mounting..."
mkdir -pv "$LFS"
mount -v "${DISK}2" "$LFS"
mkdir -pv "$LFS/boot"
mount -v "${DISK}1" "$LFS/boot"
swapon "${DISK}3"

export LFS
echo "export LFS=$LFS" >> ~/.bashrc

log "Done!"
echo ""
echo "  /boot  -> ${DISK}1 (ext2, 500MB)"
echo "  /      -> ${DISK}2 (ext4)"
echo "  swap   -> ${DISK}3 (2GB)"
echo "  LFS=$LFS"
