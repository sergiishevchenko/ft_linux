#!/bin/bash
set -euo pipefail

# Cross-Toolchain (LFS Ch.5). Run as user 'lfs' with $LFS set.

LFS="${LFS:-/mnt/lfs}"
LFS_TGT="$(uname -m)-lfs-linux-gnu"
MAKEFLAGS="-j$(nproc)"
SOURCES="$LFS/sources"

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

log()   { echo -e "${GREEN}[$(date +%H:%M:%S)]${NC} $*"; }
error() { echo -e "${RED}[$(date +%H:%M:%S)] ERROR:${NC} $*"; exit 1; }

if [ ! -d "$LFS" ]; then
    error "\$LFS ($LFS) does not exist. Run 01-prepare-disk.sh first."
fi

mkdir -pv "$LFS/tools"
mkdir -pv "$SOURCES"

if [ ! -w "$SOURCES" ]; then
    error "Cannot write to $SOURCES. Check permissions."
fi

log "LFS=$LFS  LFS_TGT=$LFS_TGT  MAKEFLAGS=$MAKEFLAGS"
echo ""

log "========== Binutils (Pass 1) =========="
cd "$SOURCES"
tar -xf binutils-*.tar.xz
cd binutils-*/
mkdir -v build && cd build
../configure \
    --prefix="$LFS/tools" \
    --with-sysroot="$LFS" \
    --target="$LFS_TGT" \
    --disable-nls \
    --enable-gprofng=no \
    --disable-werror \
    --enable-new-dtags \
    --enable-default-hash-style=gnu
make $MAKEFLAGS
make install
cd "$SOURCES" && rm -rf binutils-*/

log "========== GCC (Pass 1) =========="
cd "$SOURCES"
tar -xf gcc-*.tar.xz
cd gcc-*/

tar -xf ../mpfr-*.tar.xz && mv -v mpfr-* mpfr
tar -xf ../gmp-*.tar.xz  && mv -v gmp-*  gmp
tar -xf ../mpc-*.tar.gz  && mv -v mpc-*  mpc

case $(uname -m) in
    x86_64) sed -e '/m64=/s/lib64/lib/' -i.orig gcc/config/i386/t-linux64 ;;
esac

mkdir -v build && cd build
../configure \
    --target="$LFS_TGT" \
    --prefix="$LFS/tools" \
    --with-glibc-version=2.42 \
    --with-sysroot="$LFS" \
    --with-newlib \
    --without-headers \
    --enable-default-pie \
    --enable-default-ssp \
    --disable-nls \
    --disable-shared \
    --disable-multilib \
    --disable-threads \
    --disable-libatomic \
    --disable-libgomp \
    --disable-libquadmath \
    --disable-libssp \
    --disable-libvtv \
    --disable-libstdcxx \
    --enable-languages=c,c++
make $MAKEFLAGS
make install

cd ..
cat gcc/limitx.h gcc/glimits.h gcc/limity.h > \
    "$(dirname "$("$LFS_TGT"-gcc -print-libgcc-file-name)")/include/limits.h"

cd "$SOURCES" && rm -rf gcc-*/

log "========== Linux API Headers =========="
cd "$SOURCES"
tar -xf linux-*.tar.xz
cd linux-*/
make mrproper
make headers
find usr/include -type f ! -name '*.h' -delete
cp -rv usr/include "$LFS/usr/"
cd "$SOURCES" && rm -rf linux-*/

log "========== Glibc =========="
cd "$SOURCES"
tar -xf glibc-*.tar.xz
cd glibc-*/

case $(uname -m) in
    i?86)  ln -sfv ld-linux.so.2 "$LFS/lib/ld-lsb.so.3" ;;
    x86_64) ln -sfv ../lib/ld-linux-x86-64.so.2 "$LFS/lib64"
            ln -sfv ../lib/ld-linux-x86-64.so.2 "$LFS/lib64/ld-lsb-x86-64.so.3" ;;
esac

patch -Np1 -i ../glibc-*-fhs-1.patch

mkdir -v build && cd build
echo "rootsbindir=/usr/sbin" > configparms
../configure \
    --prefix=/usr \
    --host="$LFS_TGT" \
    --build="$(../scripts/config.guess)" \
    --enable-kernel=4.19 \
    --with-headers="$LFS/usr/include" \
    --disable-nscd \
    libc_cv_slibdir=/usr/lib
make $MAKEFLAGS
make DESTDIR="$LFS" install

sed '/RTLDLIST=/s@/usr@@g' -i "$LFS/usr/bin/ldd"
cd "$SOURCES" && rm -rf glibc-*/

log "========== Libstdc++ =========="
cd "$SOURCES"
tar -xf gcc-*.tar.xz
cd gcc-*/
mkdir -v build && cd build
../libstdc++-v3/configure \
    --host="$LFS_TGT" \
    --build="$(../config.guess)" \
    --prefix=/usr \
    --disable-multilib \
    --disable-nls \
    --disable-libstdcxx-pch \
    --with-gxx-include-dir="/tools/$LFS_TGT/include/c++/$(cat ../gcc/BASE-VER)"
make $MAKEFLAGS
make DESTDIR="$LFS" install
rm -v "$LFS/usr/lib/lib"{stdc++{,exp,fs},supc++}.la
cd "$SOURCES" && rm -rf gcc-*/

echo ""
log "Cross-Toolchain complete! Next: 03-toolchain-temp.sh"
