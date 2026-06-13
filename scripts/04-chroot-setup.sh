#!/bin/bash
set -euo pipefail

# Chroot setup (LFS Ch.7). Run as ROOT.

LFS="${LFS:-/mnt/lfs}"

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

log() { echo -e "${GREEN}[+]${NC} $*"; }

if [ "$(id -u)" -ne 0 ]; then
    echo -e "${RED}This script must be run as root.${NC}"
    exit 1
fi

log "Changing ownership of \$LFS to root..."
chown -R root:root "$LFS/{usr,lib,var,etc,bin,sbin,tools}" 2>/dev/null || true
case $(uname -m) in
    x86_64) chown -R root:root "$LFS/lib64" 2>/dev/null || true ;;
esac

log "Creating FHS directory structure..."
mkdir -pv "$LFS"/{dev,proc,sys,run}
mkdir -pv "$LFS"/{boot,home,mnt,opt,srv,tmp}
mkdir -pv "$LFS"/etc/{opt,sysconfig}
mkdir -pv "$LFS"/lib/firmware
mkdir -pv "$LFS"/media/{floppy,cdrom}
mkdir -pv "$LFS"/usr/{,local/}{include,src}
mkdir -pv "$LFS"/usr/{,local/}{bin,lib,sbin}
mkdir -pv "$LFS"/usr/{,local/}share/{color,dict,doc,info,locale,man}
mkdir -pv "$LFS"/usr/{,local/}share/{misc,terminfo,zoneinfo}
mkdir -pv "$LFS"/usr/{,local/}share/man/man{1..8}
mkdir -pv "$LFS"/var/{cache,local,log,mail,opt,spool}
mkdir -pv "$LFS"/var/lib/{color,misc,locate}

ln -sfv /run "$LFS/var/run"
ln -sfv /run/lock "$LFS/var/lock"

install -dv -m 0750 "$LFS/root"
install -dv -m 1777 "$LFS/tmp" "$LFS/var/tmp"

log "Mounting virtual kernel filesystems..."
mount -v --bind /dev "$LFS/dev"
mount -vt devpts devpts -o gid=5,mode=0620 "$LFS/dev/pts"
mount -vt proc proc "$LFS/proc"
mount -vt sysfs sysfs "$LFS/sys"
mount -vt tmpfs tmpfs "$LFS/run"

if [ -h "$LFS/dev/shm" ]; then
    install -v -d -m 1777 "$LFS$(realpath /dev/shm)"
else
    mount -vt tmpfs -o nosuid,nodev tmpfs "$LFS/dev/shm"
fi

log "Creating essential files..."

ln -sv /proc/self/mounts "$LFS/etc/mtab" 2>/dev/null || true

cat > "$LFS/etc/passwd" << "EOF"
root:x:0:0:root:/root:/bin/bash
bin:x:1:1:bin:/dev/null:/usr/bin/false
daemon:x:6:6:Daemon User:/dev/null:/usr/bin/false
messagebus:x:18:18:D-Bus Message Daemon User:/run/dbus:/usr/bin/false
uuidd:x:80:80:UUID Generation Daemon User:/dev/null:/usr/bin/false
nobody:x:65534:65534:Unprivileged User:/dev/null:/usr/bin/false
EOF

cat > "$LFS/etc/group" << "EOF"
root:x:0:
bin:x:1:daemon
sys:x:2:
kmem:x:3:
tape:x:4:
tty:x:5:
daemon:x:6:
floppy:x:7:
disk:x:8:
lp:x:9:
dialout:x:10:
audio:x:11:
video:x:12:
utmp:x:13:
cdrom:x:15:
adm:x:16:
messagebus:x:18:
input:x:24:
mail:x:34:
kvm:x:61:
uuidd:x:80:
wheel:x:97:
users:x:999:
nogroup:x:65534:
EOF

touch "$LFS/var/log"/{btmp,lastlog,faillog,wtmp}
chgrp -v utmp "$LFS/var/log/lastlog"
chmod -v 664  "$LFS/var/log/lastlog"
chmod -v 600  "$LFS/var/log/btmp"

echo ""
log "Chroot ready! Enter with:"
log ""
log "  chroot \"\$LFS\" /usr/bin/env -i   \\"
log "      HOME=/root                    \\"
log "      TERM=\"\$TERM\"                  \\"
log "      PS1='(lfs chroot) \\u:\\w\\\$ '  \\"
log "      PATH=/usr/bin:/usr/sbin       \\"
log "      MAKEFLAGS=\"-j\$(nproc)\"        \\"
log "      /bin/bash --login"
