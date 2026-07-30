#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

SOURCES="${SOURCES:-/sources}"
STATE_FILE="${STATE_FILE:-/tmp/ft_linux_ch8.state}"
export SOURCES STATE_FILE
export MAKEFLAGS="${MAKEFLAGS:--j$(nproc)}"

require_root
require_dir "$SOURCES"

START_FROM=""
LIST_ONLY=0

while [ $# -gt 0 ]; do
    case "$1" in
        --list) LIST_ONLY=1; shift ;;
        --from) START_FROM="$2"; shift 2 ;;
        --reset) rm -f "$STATE_FILE"; log "State reset."; shift ;;
        *) error "Unknown option: $1" ;;
    esac
done

SKIPPING=0
if [ -n "$START_FROM" ]; then
    SKIPPING=1
fi

pkg_begin() {
    local name="$1"
    if [ "$SKIPPING" -eq 1 ]; then
        if [ "$name" = "$START_FROM" ]; then
            SKIPPING=0
        else
            log "SKIP $name (waiting for --from $START_FROM)"
            return 1
        fi
    fi
    if is_done "$name"; then
        log "SKIP $name (already done)"
        return 1
    fi
    log "========== Building $name =========="
    return 0
}

pkg_end() {
    mark_done "$1"
    log "$1 complete."
}

standard_build() {
    local name="$1"
    shift
    pkg_begin "$name" || return 0
    extract_src "${name}-*"
    enter_src "$name"
    ./configure --prefix=/usr "$@"
    make $MAKEFLAGS
    make install
    clean_src "$name"
    pkg_end "$name"
}


build_man_pages() {
    pkg_begin "man-pages" || return 0
    extract_src "man-pages-*"
    enter_src "man-pages"
    rm -v man3/crypt*
    make -R GIT=false prefix=/usr install
    clean_src "man-pages"
    pkg_end "man-pages"
}

build_iana_etc() {
    pkg_begin "iana-etc" || return 0
    extract_src "iana-etc-*"
    enter_src "iana-etc"
    cp -v services protocols /etc
    clean_src "iana-etc"
    pkg_end "iana-etc"
}

build_glibc() {
    pkg_begin "glibc" || return 0
    extract_src "glibc-*"
    enter_src "glibc"
    patch -Np1 -i ../glibc-*-fhs-1.patch || true
    mkdir -v build && cd build
    echo "rootsbindir=/usr/sbin" > configparms
    ../configure --prefix=/usr \
        --disable-werror \
        --enable-kernel=4.19 \
        --enable-default-stackguard-randomization \
        --with-headers=/usr/include \
        --disable-nscd \
        libc_cv_slibdir=/usr/lib
    make $MAKEFLAGS
    make install
    sed '/RTLDLIST=/s@/usr@@g' -i /usr/bin/ldd
    mkdir -pv /usr/lib/locale
    localedef -i C -f UTF-8 C.UTF-8 || true
    localedef -i en_US -f UTF-8 en_US.UTF-8 || true
    clean_src "glibc"
    pkg_end "glibc"
}

build_zlib() {
    pkg_begin "zlib" || return 0
    extract_src "zlib-*"
    enter_src "zlib"
    ./configure --prefix=/usr
    make $MAKEFLAGS
    make install
    rm -fv /usr/lib/libz.a
    clean_src "zlib"
    pkg_end "zlib"
}

build_bzip2() {
    pkg_begin "bzip2" || return 0
    extract_src "bzip2-*"
    enter_src "bzip2"
    patch -Np1 -i ../bzip2-*-install_docs-1.patch || true
    sed -i 's@\(ln -s -f \)$(PREFIX)/bin/@\1@' Makefile
    sed -i "s@(PREFIX)/man@(PREFIX)/share/man@g" Makefile
    make -f Makefile-libbz2_so
    make clean
    make $MAKEFLAGS
    make PREFIX=/usr install
    cp -av libbz2.so.* /usr/lib
    ln -sv libbz2.so.1.0 /usr/lib/libbz2.so
    cp -v bzip2-shared /usr/bin/bzip2
    for i in /usr/bin/{bzcat,bunzip2}; do ln -sfv bzip2 $i; done
    rm -fv /usr/lib/libbz2.a
    clean_src "bzip2"
    pkg_end "bzip2"
}

build_xz() {
    pkg_begin "xz" || return 0
    extract_src "xz-*"
    enter_src "xz"
    ./configure --prefix=/usr --disable-static --docdir=/usr/share/doc/xz
    make $MAKEFLAGS
    make install
    clean_src "xz"
    pkg_end "xz"
}

build_zstd() {
    pkg_begin "zstd" || return 0
    extract_src "zstd-*"
    enter_src "zstd"
    make $MAKEFLAGS prefix=/usr
    make prefix=/usr install
    rm -v /usr/lib/libzstd.a
    clean_src "zstd"
    pkg_end "zstd"
}

build_file() {
    standard_build "file"
}

build_readline() {
    pkg_begin "readline" || return 0
    extract_src "readline-*"
    enter_src "readline"
    sed -i '/MV.*old/d' Makefile.in
    sed -i '/{OLDSUFF}/c:' support/shlib-install
    sed -i 's/-Wl,-rpath,[^ ]*//' support/shobj-conf
    ./configure --prefix=/usr --disable-static --with-curses --docdir=/usr/share/doc/readline
    make $MAKEFLAGS SHLIB_LIBS="-lncursesw"
    make install
    clean_src "readline"
    pkg_end "readline"
}

build_m4() { standard_build "m4"; }

build_bc() {
    pkg_begin "bc" || return 0
    extract_src "bc-*"
    enter_src "bc"
    CC=gcc ./configure --prefix=/usr -G -O3 -r
    make $MAKEFLAGS
    make install
    clean_src "bc"
    pkg_end "bc"
}

build_flex() {
    pkg_begin "flex" || return 0
    extract_src "flex-*"
    enter_src "flex"
    ./configure --prefix=/usr --docdir=/usr/share/doc/flex --disable-static
    make $MAKEFLAGS
    make install
    ln -sv flex /usr/bin/lex
    ln -sv flex.1 /usr/share/man/man1/lex.1
    clean_src "flex"
    pkg_end "flex"
}

build_tcl() {
    pkg_begin "tcl" || return 0
    extract_src "tcl*-src.tar.*"
    cd "$SOURCES"
    tar -xf tcl*-src.tar.*
    cd tcl*/unix
    ./configure --prefix=/usr --mandir=/usr/share/man --disable-rpath
    make $MAKEFLAGS
    make install
    make install-private-headers
    ln -sfv tclsh8.6 /usr/bin/tclsh
    clean_src "tcl"
    pkg_end "tcl"
}

build_expect() {
    pkg_begin "expect" || return 0
    extract_src "expect*"
    cd "$SOURCES"
    tar -xf expect*.tar.*
    cd expect*/
    patch -Np1 -i ../expect-*-gcc15-1.patch || true
    ./configure --prefix=/usr --with-tcl=/usr/lib --enable-shared --mandir=/usr/share/man --with-tclinclude=/usr/include
    make $MAKEFLAGS
    make install
    ln -svf expect*/libexpect*.so /usr/lib
    clean_src "expect"
    pkg_end "expect"
}

build_dejagnu() {
    pkg_begin "dejagnu" || return 0
    extract_src "dejagnu-*"
    enter_src "dejagnu"
    mkdir -v build && cd build
    ../configure --prefix=/usr
    makeinfo --html --no-split -o doc/dejagnu.html ../doc/dejagnu.texi || true
    make install
    clean_src "dejagnu"
    pkg_end "dejagnu"
}

build_pkgconf() {
    pkg_begin "pkgconf" || return 0
    extract_src "pkgconf-*"
    enter_src "pkgconf"
    ./configure --prefix=/usr --disable-static --docdir=/usr/share/doc/pkgconf
    make $MAKEFLAGS
    make install
    ln -sv pkgconf /usr/bin/pkg-config
    ln -sv pkgconf.1 /usr/share/man/man1/pkg-config.1
    clean_src "pkgconf"
    pkg_end "pkgconf"
}

build_binutils() {
    pkg_begin "binutils" || return 0
    extract_src "binutils-*"
    enter_src "binutils"
    mkdir -v build && cd build
    ../configure --prefix=/usr --sysconfdir=/etc --enable-ld=default \
        --enable-plugins --enable-shared --disable-werror \
        --enable-64-bit-bfd --enable-new-dtags --with-system-zlib \
        --enable-default-hash-style=gnu
    make $MAKEFLAGS tooldir=/usr
    make tooldir=/usr install
    rm -fv /usr/lib/lib{bfd,ctf,ctf-nobfd,gprofng,opcodes,sframe}.a
    clean_src "binutils"
    pkg_end "binutils"
}

build_gmp() {
    pkg_begin "gmp" || return 0
    extract_src "gmp-*"
    enter_src "gmp"
    ./configure --prefix=/usr --enable-cxx --disable-static --docdir=/usr/share/doc/gmp
    make $MAKEFLAGS
    make install
    clean_src "gmp"
    pkg_end "gmp"
}

build_mpfr() {
    pkg_begin "mpfr" || return 0
    extract_src "mpfr-*"
    enter_src "mpfr"
    ./configure --prefix=/usr --disable-static --enable-thread-safe --docdir=/usr/share/doc/mpfr
    make $MAKEFLAGS
    make install
    clean_src "mpfr"
    pkg_end "mpfr"
}

build_mpc() {
    pkg_begin "mpc" || return 0
    extract_src "mpc-*"
    enter_src "mpc"
    ./configure --prefix=/usr --disable-static --docdir=/usr/share/doc/mpc
    make $MAKEFLAGS
    make install
    clean_src "mpc"
    pkg_end "mpc"
}

build_attr() {
    pkg_begin "attr" || return 0
    extract_src "attr-*"
    enter_src "attr"
    ./configure --prefix=/usr --disable-static --sysconfdir=/etc --docdir=/usr/share/doc/attr
    make $MAKEFLAGS
    make install
    clean_src "attr"
    pkg_end "attr"
}

build_acl() {
    pkg_begin "acl" || return 0
    extract_src "acl-*"
    enter_src "acl"
    ./configure --prefix=/usr --disable-static --docdir=/usr/share/doc/acl
    make $MAKEFLAGS
    make install
    clean_src "acl"
    pkg_end "acl"
}

build_libcap() {
    pkg_begin "libcap" || return 0
    extract_src "libcap-*"
    enter_src "libcap"
    sed -i '/install -m.*STA/d' libcap/Makefile
    make $MAKEFLAGS prefix=/usr lib=lib
    make prefix=/usr lib=lib install
    clean_src "libcap"
    pkg_end "libcap"
}

build_libxcrypt() {
    pkg_begin "libxcrypt" || return 0
    extract_src "libxcrypt-*"
    enter_src "libxcrypt"
    ./configure --prefix=/usr --enable-hashes=strong,glibc --enable-obsolete-api=no --disable-static --disable-failure-tokens
    make $MAKEFLAGS
    make install
    clean_src "libxcrypt"
    pkg_end "libxcrypt"
}

build_shadow() {
    pkg_begin "shadow" || return 0
    extract_src "shadow-*"
    enter_src "shadow"
    sed -i 's/groups$(EXEEXT) //' src/Makefile.in
    find man -name Makefile.in -exec sed -i 's/groups\.1 / /' {} \;
    find man -name Makefile.in -exec sed -i 's/getspnam\.3 / /' {} \;
    find man -name Makefile.in -exec sed -i 's/passwd\.5 / /' {} \;
    sed -e 's:#ENCRYPT_METHOD DES:ENCRYPT_METHOD YESCRYPT:' \
        -e 's:/var/spool/mail:/var/mail:' \
        -e '/PATH=/{s@/sbin:@@;s@/bin:@@}' \
        -i etc/login.defs
    ./configure --sysconfdir=/etc --disable-static --with-{lib,bcrypt,yescrypt}crypt-yes --without-libbsd --with-group-name-max-length=32
    make $MAKEFLAGS
    make exec_prefix=/usr install
    make -C man install-man
    pwconv
    grpconv
    mkdir -p /etc/default
    useradd -D --gid 999 || true
    clean_src "shadow"
    pkg_end "shadow"
}

build_gcc() {
    pkg_begin "gcc" || return 0
    extract_src "gcc-*"
    enter_src "gcc"
    case $(uname -m) in
        x86_64) sed -e '/m64=/s/lib64/lib/' -i.orig gcc/config/i386/t-linux64 ;;
    esac
    mkdir -v build && cd build
    ../configure --prefix=/usr LD=ld \
        --enable-languages=c,c++ --enable-default-pie \
        --enable-default-ssp --enable-host-pie \
        --disable-multilib --disable-bootstrap \
        --disable-fixincludes --with-system-zlib
    make $MAKEFLAGS
    make install
    ln -svr /usr/bin/cpp /usr/lib
    ln -sv gcc.1 /usr/share/man/man1/cc.1
    ln -sfv ../../libexec/gcc/$(gcc -dumpmachine)/$(gcc -dumpversion)/liblto_plugin.so \
        /usr/lib/bfd-plugins/
    clean_src "gcc"
    pkg_end "gcc"
}

build_ncurses() {
    pkg_begin "ncurses" || return 0
    extract_src "ncurses-*"
    enter_src "ncurses"
    ./configure --prefix=/usr --mandir=/usr/share/man \
        --with-shared --without-debug --without-normal \
        --with-cxx-shared --enable-pc-files --with-pkg-config-libdir=/usr/lib/pkgconfig \
        --enable-widec --disable-stripping
    make $MAKEFLAGS
    make DESTDIR=$PWD/dest install
    install -vm755 dest/usr/lib/libncursesw.so.6.? /usr/lib
    rm -v dest/usr/lib/libncursesw.so.6.?
    sed -e 's/^#if.*XOPEN.*$/#if 1/' -i dest/usr/include/curses.h
    cp -av dest/* /
    for lib in ncurses form panel menu ; do
        ln -sfv lib${lib}w.so /usr/lib/lib${lib}.so
        ln -sfv ${lib}w.pc /usr/lib/pkgconfig/${lib}.pc
    done
    ln -sfv libncursesw.so /usr/lib/libcurses.so
    clean_src "ncurses"
    pkg_end "ncurses"
}

build_sed() { standard_build "sed"; }

build_psmisc() {
    pkg_begin "psmisc" || return 0
    extract_src "psmisc-*"
    enter_src "psmisc"
    ./configure --prefix=/usr
    make $MAKEFLAGS
    make install
    clean_src "psmisc"
    pkg_end "psmisc"
}

build_gettext() {
    pkg_begin "gettext" || return 0
    extract_src "gettext-*"
    enter_src "gettext"
    ./configure --prefix=/usr --disable-static --docdir=/usr/share/doc/gettext
    make $MAKEFLAGS
    make install
    chmod -v 0755 /usr/lib/preloadable_libintl.so || true
    clean_src "gettext"
    pkg_end "gettext"
}

build_bison() {
    pkg_begin "bison" || return 0
    extract_src "bison-*"
    enter_src "bison"
    ./configure --prefix=/usr --docdir=/usr/share/doc/bison
    make $MAKEFLAGS
    make install
    clean_src "bison"
    pkg_end "bison"
}

build_grep() { standard_build "grep"; }

build_bash() {
    pkg_begin "bash" || return 0
    extract_src "bash-*"
    enter_src "bash"
    ./configure --prefix=/usr --without-bash-malloc --with-installed-readline --docdir=/usr/share/doc/bash
    make $MAKEFLAGS
    make install
    clean_src "bash"
    pkg_end "bash"
}

build_libtool() {
    pkg_begin "libtool" || return 0
    extract_src "libtool-*"
    enter_src "libtool"
    ./configure --prefix=/usr
    make $MAKEFLAGS
    make install
    rm -fv /usr/lib/libltdl.a
    clean_src "libtool"
    pkg_end "libtool"
}

build_gdbm() {
    pkg_begin "gdbm" || return 0
    extract_src "gdbm-*"
    enter_src "gdbm"
    ./configure --prefix=/usr --disable-static --enable-libgdbm-compat
    make $MAKEFLAGS
    make install
    clean_src "gdbm"
    pkg_end "gdbm"
}

build_gperf() {
    pkg_begin "gperf" || return 0
    extract_src "gperf-*"
    enter_src "gperf"
    ./configure --prefix=/usr --docdir=/usr/share/doc/gperf
    make $MAKEFLAGS
    make install
    clean_src "gperf"
    pkg_end "gperf"
}

build_expat() {
    pkg_begin "expat" || return 0
    extract_src "expat-*"
    enter_src "expat"
    ./configure --prefix=/usr --disable-static --docdir=/usr/share/doc/expat
    make $MAKEFLAGS
    make install
    clean_src "expat"
    pkg_end "expat"
}

build_inetutils() {
    pkg_begin "inetutils" || return 0
    extract_src "inetutils-*"
    enter_src "inetutils"
    ./configure --prefix=/usr --localstatedir=/var \
        --disable-logger --disable-whois --disable-rcp \
        --disable-rexec --disable-rlogin --disable-rsh --disable-servers
    make $MAKEFLAGS
    make install
    mv -v /usr/{,s}bin/ifconfig
    clean_src "inetutils"
    pkg_end "inetutils"
}

build_less() {
    pkg_begin "less" || return 0
    extract_src "less-*"
    enter_src "less"
    ./configure --prefix=/usr --sysconfdir=/etc
    make $MAKEFLAGS
    make install
    clean_src "less"
    pkg_end "less"
}

build_perl() {
    pkg_begin "perl" || return 0
    extract_src "perl-*"
    enter_src "perl"
    export BUILD_ZLIB=False BUILD_BZIP2=0
    sh Configure -des \
        -Dprefix=/usr \
        -Dvendorprefix=/usr \
        -Dprivlib=/usr/lib/perl5/5.42/core_perl \
        -Darchlib=/usr/lib/perl5/5.42/core_perl \
        -Dsitelib=/usr/lib/perl5/5.42/site_perl \
        -Dsitearch=/usr/lib/perl5/5.42/site_perl \
        -Dvendorlib=/usr/lib/perl5/5.42/vendor_perl \
        -Dvendorarch=/usr/lib/perl5/5.42/vendor_perl \
        -Dman1dir=/usr/share/man/man1 \
        -Dman3dir=/usr/share/man/man3 \
        -Dpager="/usr/bin/less -isR" \
        -Duseshrplib \
        -Dusethreads
    make $MAKEFLAGS
    make install
    unset BUILD_ZLIB BUILD_BZIP2
    clean_src "perl"
    pkg_end "perl"
}

build_xml_parser() {
    pkg_begin "XML-Parser" || return 0
    extract_src "XML-Parser-*"
    enter_src "XML-Parser"
    perl Makefile.PL
    make $MAKEFLAGS
    make install
    clean_src "XML-Parser"
    pkg_end "XML-Parser"
}

build_intltool() {
    pkg_begin "intltool" || return 0
    extract_src "intltool-*"
    enter_src "intltool"
    sed -i 's:\\\${:\\\$\\{:' intltool-update.in
    ./configure --prefix=/usr
    make $MAKEFLAGS
    make install
    clean_src "intltool"
    pkg_end "intltool"
}

build_autoconf() { standard_build "autoconf"; }

build_automake() {
    pkg_begin "automake" || return 0
    extract_src "automake-*"
    enter_src "automake"
    ./configure --prefix=/usr --docdir=/usr/share/doc/automake
    make $MAKEFLAGS
    make install
    clean_src "automake"
    pkg_end "automake"
}

build_openssl() {
    pkg_begin "openssl" || return 0
    extract_src "openssl-*"
    enter_src "openssl"
    ./config --prefix=/usr --openssldir=/etc/ssl --libdir=lib shared zlib-dynamic
    make $MAKEFLAGS
    make install
    clean_src "openssl"
    pkg_end "openssl"
}

build_kmod() {
    pkg_begin "kmod" || return 0
    extract_src "kmod-*"
    enter_src "kmod"
    ./configure --prefix=/usr --sysconfdir=/etc --with-openssl --with-xz --with-zstd --with-zlib --disable-manpages
    make $MAKEFLAGS
    make install
    for target in depmod insmod modinfo modprobe rmmod; do
        ln -sfv ../bin/kmod /usr/sbin/$target
    done
    ln -sfv kmod /usr/bin/lsmod
    clean_src "kmod"
    pkg_end "kmod"
}

build_libelf() {
    pkg_begin "elfutils" || return 0
    extract_src "elfutils-*"
    enter_src "elfutils"
    ./configure --prefix=/usr --disable-debuginfod --enable-libdebuginfod=dummy
    make $MAKEFLAGS
    make -C libelf install
    install -vm644 config/libelf.pc /usr/lib/pkgconfig
    rm -v /usr/lib/libelf.a
    clean_src "elfutils"
    pkg_end "elfutils"
}

build_libffi() {
    pkg_begin "libffi" || return 0
    extract_src "libffi-*"
    enter_src "libffi"
    ./configure --prefix=/usr --disable-static --with-gcc-arch=native
    make $MAKEFLAGS
    make install
    clean_src "libffi"
    pkg_end "libffi"
}

build_python() {
    pkg_begin "Python" || return 0
    extract_src "Python-*"
    enter_src "Python"
    ./configure --prefix=/usr --enable-shared --with-system-expat --enable-optimizations
    make $MAKEFLAGS
    make install
    clean_src "Python"
    pkg_end "Python"
}

build_flit_core() {
    pkg_begin "flit_core" || return 0
    extract_src "flit_core-*"
    enter_src "flit_core"
    pip3 install --no-deps --no-build-isolation --root-user-action=ignore . || \
        python3 -m pip install --no-deps --no-build-isolation .
    clean_src "flit_core"
    pkg_end "flit_core"
}

build_wheel() {
    pkg_begin "wheel" || return 0
    extract_src "wheel-*"
    enter_src "wheel"
    pip3 install --no-deps --no-build-isolation --root-user-action=ignore . || \
        python3 -m pip install --no-deps --no-build-isolation .
    clean_src "wheel"
    pkg_end "wheel"
}

build_setuptools() {
    pkg_begin "setuptools" || return 0
    extract_src "setuptools-*"
    enter_src "setuptools"
    pip3 install --no-deps --no-build-isolation --root-user-action=ignore . || \
        python3 -m pip install --no-deps --no-build-isolation .
    clean_src "setuptools"
    pkg_end "setuptools"
}

build_ninja() {
    pkg_begin "ninja" || return 0
    extract_src "ninja-*"
    enter_src "ninja"
    python3 configure.py --bootstrap
    install -vm755 ninja /usr/bin/
    install -vDm644 misc/bash-completion /usr/share/bash-completion/completions/ninja
    clean_src "ninja"
    pkg_end "ninja"
}

build_meson() {
    pkg_begin "meson" || return 0
    extract_src "meson-*"
    enter_src "meson"
    pip3 install --no-deps --no-build-isolation --root-user-action=ignore . || \
        python3 -m pip install --no-deps --no-build-isolation .
    clean_src "meson"
    pkg_end "meson"
}

build_coreutils() {
    pkg_begin "coreutils" || return 0
    extract_src "coreutils-*"
    enter_src "coreutils"
    patch -Np1 -i ../coreutils-*-i18n-1.patch || true
    patch -Np1 -i ../coreutils-*-upstream_fix-1.patch || true
    autoreconf -fiv || true
    FORCE_UNSAFE_CONFIGURE=1 ./configure --prefix=/usr --enable-no-install-program=kill,uptime
    make $MAKEFLAGS
    make install
    mv -v /usr/bin/chroot /usr/sbin
    mv -v /usr/share/man/man1/chroot.1 /usr/share/man/man8/chroot.8
    sed -i 's/"1"/"8"/' /usr/share/man/man8/chroot.8
    clean_src "coreutils"
    pkg_end "coreutils"
}

build_check() {
    pkg_begin "check" || return 0
    extract_src "check-*" || { warn "check tarball missing, skip"; return 0; }
    enter_src "check"
    ./configure --prefix=/usr --disable-static
    make $MAKEFLAGS
    make install
    clean_src "check"
    pkg_end "check"
}

build_diffutils() { standard_build "diffutils"; }
build_gawk() {
    pkg_begin "gawk" || return 0
    extract_src "gawk-*"
    enter_src "gawk"
    sed -i 's/extras//' Makefile.in
    ./configure --prefix=/usr
    make $MAKEFLAGS
    make install
    clean_src "gawk"
    pkg_end "gawk"
}
build_findutils() {
    pkg_begin "findutils" || return 0
    extract_src "findutils-*"
    enter_src "findutils"
    ./configure --prefix=/usr --localstatedir=/var/lib/locate
    make $MAKEFLAGS
    make install
    clean_src "findutils"
    pkg_end "findutils"
}
build_groff() {
    pkg_begin "groff" || return 0
    extract_src "groff-*"
    enter_src "groff"
    PAGE=A4 ./configure --prefix=/usr
    make $MAKEFLAGS
    make install
    clean_src "groff"
    pkg_end "groff"
}

build_grub() {
    pkg_begin "grub" || return 0
    extract_src "grub-*"
    enter_src "grub"
    echo "depends bli part_gpt" > grub-core/extra_deps.lst
    ./configure --prefix=/usr --sysconfdir=/etc --disable-efiemu --disable-werror
    make $MAKEFLAGS
    make install
    mv -v /etc/bash_completion.d/grub /usr/share/bash-completion/completions || true
    clean_src "grub"
    pkg_end "grub"
}

build_gzip() { standard_build "gzip"; }

build_iproute2() {
    pkg_begin "iproute2" || return 0
    extract_src "iproute2-*"
    enter_src "iproute2"
    sed -i /ARPD/d Makefile
    rm -fv man/man8/arpd.8
    make NETNS_RUN_DIR=/run/netns $MAKEFLAGS
    make SBINDIR=/usr/sbin install
    clean_src "iproute2"
    pkg_end "iproute2"
}

build_kbd() {
    pkg_begin "kbd" || return 0
    extract_src "kbd-*"
    enter_src "kbd"
    patch -Np1 -i ../kbd-*-backspace-1.patch || true
    sed -i '/RESIZECONS_PROGS=/s/yes/no/' configure
    sed -i 's/resizecons.8 //' docs/man/man8/Makefile.in
    ./configure --prefix=/usr --disable-vlock
    make $MAKEFLAGS
    make install
    clean_src "kbd"
    pkg_end "kbd"
}

build_libpipeline() {
    pkg_begin "libpipeline" || return 0
    extract_src "libpipeline-*"
    enter_src "libpipeline"
    ./configure --prefix=/usr
    make $MAKEFLAGS
    make install
    clean_src "libpipeline"
    pkg_end "libpipeline"
}

build_make() { standard_build "make"; }
build_patch() { standard_build "patch"; }

build_tar() {
    pkg_begin "tar" || return 0
    extract_src "tar-*"
    enter_src "tar"
    FORCE_UNSAFE_CONFIGURE=1 ./configure --prefix=/usr
    make $MAKEFLAGS
    make install
    clean_src "tar"
    pkg_end "tar"
}

build_texinfo() { standard_build "texinfo"; }

build_vim() {
    pkg_begin "vim" || return 0
    extract_src "vim-*"
    enter_src "vim"
    echo '#define SYS_VIMRC_FILE "/etc/vimrc"' >> src/feature.h
    ./configure --prefix=/usr
    make $MAKEFLAGS
    make install
    ln -sv vim /usr/bin/vi
    for L in /usr/share/man/{,*/}man1/vim.1; do
        ln -sv vim.1 $(dirname $L)/vi.1
    done
    ln -sv ../vim/vim*/doc /usr/share/doc/vim || true
    clean_src "vim"
    pkg_end "vim"
}

build_util_linux() {
    pkg_begin "util-linux" || return 0
    extract_src "util-linux-*"
    enter_src "util-linux"
    ./configure ADJTIME_PATH=/var/lib/hwclock/adjtime \
        --bindir=/usr/bin --libdir=/usr/lib --runstatedir=/run \
        --sbindir=/usr/sbin --disable-chfn-chsh --disable-login \
        --disable-nologin --disable-su --disable-setpriv \
        --disable-runuser --disable-pylibmount --disable-liblastlog2 \
        --disable-static --without-python
    make $MAKEFLAGS
    make install
    clean_src "util-linux"
    pkg_end "util-linux"
}

build_e2fsprogs() {
    pkg_begin "e2fsprogs" || return 0
    extract_src "e2fsprogs-*"
    enter_src "e2fsprogs"
    mkdir -v build && cd build
    ../configure --prefix=/usr --sysconfdir=/etc --enable-elf-shlibs --disable-libblkid --disable-libuuid --disable-uuidd --disable-fsck
    make $MAKEFLAGS
    make install
    rm -fv /usr/lib/{libcom_err,libe2p,libext2fs,libss}.a
    clean_src "e2fsprogs"
    pkg_end "e2fsprogs"
}

build_sysklogd() {
    pkg_begin "sysklogd" || return 0
    extract_src "sysklogd-*"
    enter_src "sysklogd"
    ./configure --prefix=/usr --sysconfdir=/etc --runstatedir=/run --without-logger
    make $MAKEFLAGS
    make install
    clean_src "sysklogd"
    pkg_end "sysklogd"
}

build_sysvinit() {
    pkg_begin "sysvinit" || return 0
    extract_src "sysvinit-*"
    enter_src "sysvinit"
    patch -Np1 -i ../sysvinit-*-consolidated-1.patch || true
    make $MAKEFLAGS
    make install
    clean_src "sysvinit"
    pkg_end "sysvinit"
}

build_procps() {
    pkg_begin "procps-ng" || return 0
    extract_src "procps-ng-*"
    enter_src "procps-ng"
    ./configure --prefix=/usr --docdir=/usr/share/doc/procps-ng --disable-static --disable-kill --with-systemd=no
    make $MAKEFLAGS
    make install
    clean_src "procps-ng"
    pkg_end "procps-ng"
}

build_eudev() {
    pkg_begin "eudev" || return 0
    if ls "$SOURCES"/udev-lfs-*.tar.xz >/dev/null 2>&1; then
        extract_src "udev-lfs-*"
        enter_src "udev-lfs"
        make install || true
        clean_src "udev-lfs"
    fi
    warn "Complete eudev/udev install per LFS Ch.8 (systemd udev + udev-lfs)."
    warn "See: https://www.linuxfromscratch.org/lfs/view/stable/chapter08/udev.html"
    pkg_end "eudev"
}

build_bootscripts() {
    pkg_begin "lfs-bootscripts" || return 0
    extract_src "lfs-bootscripts-*"
    enter_src "lfs-bootscripts"
    make install
    clean_src "lfs-bootscripts"
    pkg_end "lfs-bootscripts"
}

build_tzdata() {
    pkg_begin "tzdata" || return 0
    cd "$SOURCES"
    mkdir -pv tzdata-build && cd tzdata-build
    tar -xf ../tzdata*.tar.gz
    ZONEINFO=/usr/share/zoneinfo
    mkdir -pv $ZONEINFO/{posix,right}
    for tz in etcetera southamerica northamerica europe africa antarctica asia australasia backward; do
        zic -L /dev/null   -d $ZONEINFO       ${tz} || true
        zic -L /dev/null   -d $ZONEINFO/posix ${tz} || true
        zic -L leapseconds -d $ZONEINFO/right ${tz} || true
    done
    cp -v zone.tab zone1970.tab iso3166.tab $ZONEINFO
    zic -d $ZONEINFO -p Europe/Zurich || zic -d $ZONEINFO -p Etc/UTC
    ln -sfv /usr/share/zoneinfo/Europe/Zurich /etc/localtime || \
        ln -sfv /usr/share/zoneinfo/Etc/UTC /etc/localtime
    cd "$SOURCES" && rm -rf tzdata-build
    pkg_end "tzdata"
}

PACKAGES=(
    man-pages iana-etc glibc zlib bzip2 xz zstd file readline m4 bc flex
    tcl expect dejagnu pkgconf binutils gmp mpfr mpc attr acl libcap libxcrypt
    shadow gcc ncurses sed psmisc gettext bison grep bash libtool gdbm gperf
    expat inetutils less perl XML-Parser intltool autoconf automake openssl
    kmod elfutils libffi Python flit_core wheel setuptools ninja meson
    coreutils check diffutils gawk findutils groff grub gzip iproute2 kbd
    libpipeline make patch tar texinfo vim util-linux e2fsprogs sysklogd
    sysvinit procps-ng eudev lfs-bootscripts tzdata
)

if [ "$LIST_ONLY" -eq 1 ]; then
    printf '%s\n' "${PACKAGES[@]}"
    exit 0
fi

log "Starting LFS Ch.8–9 package build"
log "SOURCES=$SOURCES  MAKEFLAGS=$MAKEFLAGS"
log "State file: $STATE_FILE"
echo ""

for pkg in "${PACKAGES[@]}"; do
    fn="build_${pkg//-/_}"
    fn="${fn//./_}"
    case "$pkg" in
        XML-Parser) fn="build_xml_parser" ;;
        Python)     fn="build_python" ;;
        flit_core)  fn="build_flit_core" ;;
        procps-ng)  fn="build_procps" ;;
        elfutils)   fn="build_libelf" ;;
        lfs-bootscripts) fn="build_bootscripts" ;;
        man-pages)  fn="build_man_pages" ;;
        iana-etc)   fn="build_iana_etc" ;;
        libxcrypt)  fn="build_libxcrypt" ;;
        libpipeline) fn="build_libpipeline" ;;
        util-linux) fn="build_util_linux" ;;
        e2fsprogs)  fn="build_e2fsprogs" ;;
        iproute2)   fn="build_iproute2" ;;
    esac
    if declare -f "$fn" >/dev/null; then
        "$fn"
    else
        warn "No build function for $pkg — build manually from LFS book"
    fi
done

echo ""
log "System package build finished (or skipped completed packages)."
log "Next: apply configs, then 06-build-kernel.sh"
log "  bash scripts/apply-configs.sh <student_login> /"
log "  bash scripts/06-build-kernel.sh <student_login>"
