#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

source "$SCRIPT_DIR/lib.sh"

LFS="${LFS:-/mnt/lfs}"

require_root
require_dir "$LFS"

log "Creating group and user 'lfs'..."
if ! getent group lfs >/dev/null; then
    groupadd lfs
fi
if ! id lfs >/dev/null 2>&1; then
    useradd -s /bin/bash -g lfs -m -k /dev/null lfs
fi

log "Setting ownership of \$LFS to lfs..."
chown -v lfs:lfs "$LFS"
chown -R lfs:lfs "$LFS"/{usr,lib,var,etc,bin,sbin,tools,sources} 2>/dev/null || true
case $(uname -m) in
    x86_64) chown -R lfs:lfs "$LFS/lib64" 2>/dev/null || true ;;
esac

log "Writing /home/lfs/.bash_profile..."
cat > /home/lfs/.bash_profile << "EOF"
exec env -i HOME="$HOME" TERM="$TERM" PS1='\u:\w\$ ' /bin/bash
EOF

log "Writing /home/lfs/.bashrc..."
cat > /home/lfs/.bashrc << EOF
set +h
umask 022
LFS=$LFS
LC_ALL=POSIX
LFS_TGT=\$(uname -m)-lfs-linux-gnu
PATH=/usr/bin
if [ ! -L /bin ]; then
    PATH=/bin:\$PATH
fi
PATH=\$LFS/tools/bin:\$PATH
CONFIG_SITE=\$LFS/usr/share/config.site
export LFS LC_ALL LFS_TGT PATH CONFIG_SITE
export MAKEFLAGS=-j\$(nproc)
EOF

chown lfs:lfs /home/lfs/.bash_profile /home/lfs/.bashrc

log "Done. Switch to lfs user with:"
log "  su - lfs"
log "Then run:"
log "  bash scripts/02-toolchain-cross.sh"
