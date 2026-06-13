#!/bin/bash
set -euo pipefail

# Temporary Tools (LFS Ch.6-7). Run as user 'lfs' with $LFS set.

LFS="${LFS:-/mnt/lfs}"
LFS_TGT="$(uname -m)-lfs-linux-gnu"
MAKEFLAGS="-j$(nproc)"
SOURCES="$LFS/sources"

GREEN='\033[0;32m'
NC='\033[0m'

log() { echo -e "${GREEN}[$(date +%H:%M:%S)]${NC} $*"; }

log "========== M4 =========="
cd "$SOURCES" && tar -xf m4-*.tar.xz && cd m4-*/
./configure --prefix=/usr --host="$LFS_TGT" --build="$(build-aux/config.guess)"
make $MAKEFLAGS && make DESTDIR="$LFS" install
cd "$SOURCES" && rm -rf m4-*/

log "========== Ncurses =========="
cd "$SOURCES" && tar -xf ncurses-*.tgz && cd ncurses-*/
sed -i s/mawk// configure
mkdir build && pushd build
  ../configure
  make -C include
  make -C progs tic
popd
./configure \
    --prefix=/usr --host="$LFS_TGT" --build="$(./config.guess)" \
    --mandir=/usr/share/man --with-manpage-format=normal \
    --with-shared --without-normal --with-cxx-shared \
    --without-debug --without-ada --disable-stripping \
    --enable-widec
make $MAKEFLAGS
make DESTDIR="$LFS" TIC_PATH="$(pwd)/build/progs/tic" install
ln -sv libncursesw.so "$LFS/usr/lib/libncurses.so"
sed -e 's/^#if.*XOPEN.*$/#if 1/' -i "$LFS/usr/include/curses.h"
cd "$SOURCES" && rm -rf ncurses-*/

log "========== Bash =========="
cd "$SOURCES" && tar -xf bash-*.tar.gz && cd bash-*/
./configure --prefix=/usr --build="$(sh support/config.guess)" \
    --host="$LFS_TGT" --without-bash-malloc bash_cv_strtold_broken=no
make $MAKEFLAGS && make DESTDIR="$LFS" install
ln -sv bash "$LFS/bin/sh"
cd "$SOURCES" && rm -rf bash-*/

log "========== Coreutils =========="
cd "$SOURCES" && tar -xf coreutils-*.tar.xz && cd coreutils-*/
./configure --prefix=/usr --host="$LFS_TGT" --build="$(build-aux/config.guess)" \
    --enable-install-program=hostname \
    --enable-no-install-program=kill,uptime \
    gl_cv_macro_MB_CUR_MAX_good=y
make $MAKEFLAGS && make DESTDIR="$LFS" install
mv -v "$LFS/usr/bin/chroot" "$LFS/usr/sbin"
mkdir -pv "$LFS/usr/share/man/man8"
mv -v "$LFS/usr/share/man/man1/chroot.1" "$LFS/usr/share/man/man8/chroot.8"
sed -i 's/"1"/"8"/' "$LFS/usr/share/man/man8/chroot.8"
cd "$SOURCES" && rm -rf coreutils-*/

log "========== Diffutils =========="
cd "$SOURCES" && tar -xf diffutils-*.tar.xz && cd diffutils-*/
./configure --prefix=/usr --host="$LFS_TGT" --build="$(./build-aux/config.guess)"
make $MAKEFLAGS && make DESTDIR="$LFS" install
cd "$SOURCES" && rm -rf diffutils-*/

log "========== File =========="
cd "$SOURCES" && tar -xf file-*.tar.gz && cd file-*/
mkdir build && pushd build
  ../configure --disable-bzlib --disable-libseccomp \
      --disable-xzlib --disable-zlib
  make
popd
./configure --prefix=/usr --host="$LFS_TGT" --build="$(./config.guess)"
make FILE_COMPILE="$(pwd)/build/src/file" $MAKEFLAGS
make DESTDIR="$LFS" install
rm -v "$LFS/usr/lib/libmagic.la"
cd "$SOURCES" && rm -rf file-*/

log "========== Findutils =========="
cd "$SOURCES" && tar -xf findutils-*.tar.xz && cd findutils-*/
./configure --prefix=/usr --localstatedir=/var/lib/locate \
    --host="$LFS_TGT" --build="$(build-aux/config.guess)"
make $MAKEFLAGS && make DESTDIR="$LFS" install
cd "$SOURCES" && rm -rf findutils-*/

log "========== Gawk =========="
cd "$SOURCES" && tar -xf gawk-*.tar.xz && cd gawk-*/
sed -i 's/extras//' Makefile.in
./configure --prefix=/usr --host="$LFS_TGT" --build="$(build-aux/config.guess)"
make $MAKEFLAGS && make DESTDIR="$LFS" install
cd "$SOURCES" && rm -rf gawk-*/

log "========== Grep =========="
cd "$SOURCES" && tar -xf grep-*.tar.xz && cd grep-*/
./configure --prefix=/usr --host="$LFS_TGT" --build="$(./build-aux/config.guess)"
make $MAKEFLAGS && make DESTDIR="$LFS" install
cd "$SOURCES" && rm -rf grep-*/

log "========== Gzip =========="
cd "$SOURCES" && tar -xf gzip-*.tar.xz && cd gzip-*/
./configure --prefix=/usr --host="$LFS_TGT"
make $MAKEFLAGS && make DESTDIR="$LFS" install
cd "$SOURCES" && rm -rf gzip-*/

log "========== Make =========="
cd "$SOURCES" && tar -xf make-*.tar.gz && cd make-*/
./configure --prefix=/usr --without-guile \
    --host="$LFS_TGT" --build="$(build-aux/config.guess)"
make $MAKEFLAGS && make DESTDIR="$LFS" install
cd "$SOURCES" && rm -rf make-*/

log "========== Patch =========="
cd "$SOURCES" && tar -xf patch-*.tar.xz && cd patch-*/
./configure --prefix=/usr --host="$LFS_TGT" --build="$(build-aux/config.guess)"
make $MAKEFLAGS && make DESTDIR="$LFS" install
cd "$SOURCES" && rm -rf patch-*/

log "========== Sed =========="
cd "$SOURCES" && tar -xf sed-*.tar.xz && cd sed-*/
./configure --prefix=/usr --host="$LFS_TGT" --build="$(./build-aux/config.guess)"
make $MAKEFLAGS && make DESTDIR="$LFS" install
cd "$SOURCES" && rm -rf sed-*/

log "========== Tar =========="
cd "$SOURCES" && tar -xf tar-*.tar.xz && cd tar-*/
./configure --prefix=/usr --host="$LFS_TGT" --build="$(build-aux/config.guess)"
make $MAKEFLAGS && make DESTDIR="$LFS" install
cd "$SOURCES" && rm -rf tar-*/

log "========== Xz =========="
cd "$SOURCES" && tar -xf xz-*.tar.xz && cd xz-*/
./configure --prefix=/usr --host="$LFS_TGT" --build="$(build-aux/config.guess)" \
    --disable-static --docdir=/usr/share/doc/xz
make $MAKEFLAGS && make DESTDIR="$LFS" install
rm -v "$LFS/usr/lib/liblzma.la"
cd "$SOURCES" && rm -rf xz-*/

log "========== Binutils (Pass 2) =========="
cd "$SOURCES" && tar -xf binutils-*.tar.xz && cd binutils-*/
sed '6009s/$add_dir//' -i ltmain.sh
mkdir -v build && cd build
../configure \
    --prefix=/usr --build="$(../config.guess)" \
    --host="$LFS_TGT" --disable-nls \
    --enable-shared --enable-gprofng=no \
    --disable-werror --enable-64-bit-bfd \
    --enable-new-dtags --enable-default-hash-style=gnu
make $MAKEFLAGS
make DESTDIR="$LFS" install
rm -v "$LFS/usr/lib/lib"{bfd,ctf,ctf-nobfd,opcodes,sframe}.{a,la}
cd "$SOURCES" && rm -rf binutils-*/

log "========== GCC (Pass 2) =========="
cd "$SOURCES" && tar -xf gcc-*.tar.xz && cd gcc-*/
tar -xf ../mpfr-*.tar.xz && mv -v mpfr-* mpfr
tar -xf ../gmp-*.tar.xz  && mv -v gmp-*  gmp
tar -xf ../mpc-*.tar.gz  && mv -v mpc-*  mpc

case $(uname -m) in
    x86_64) sed -e '/m64=/s/lib64/lib/' -i.orig gcc/config/i386/t-linux64 ;;
esac

sed '/thread_header =/s/@.*@/gthr-posix.h/' \
    -i libgcc/Makefile.in libstdc++-v3/include/Makefile.in

mkdir -v build && cd build
../configure \
    --build="$(../config.guess)" \
    --host="$LFS_TGT" \
    --target="$LFS_TGT" \
    LDFLAGS_FOR_TARGET=-L"$PWD/$LFS_TGT/libgcc" \
    --prefix=/usr \
    --with-build-sysroot="$LFS" \
    --enable-default-pie \
    --enable-default-ssp \
    --disable-nls \
    --disable-multilib \
    --disable-libatomic \
    --disable-libgomp \
    --disable-libquadmath \
    --disable-libsanitizer \
    --disable-libssp \
    --disable-libvtv \
    --enable-languages=c,c++
make $MAKEFLAGS
make DESTDIR="$LFS" install
ln -sv gcc "$LFS/usr/bin/cc"
cd "$SOURCES" && rm -rf gcc-*/

echo ""
log "Temporary toolchain complete! Next: 04-chroot-setup.sh (as ROOT)"
