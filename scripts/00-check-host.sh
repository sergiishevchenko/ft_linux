#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

PASS=0
FAIL=0

check_cmd() {
    local name="$1"
    local cmd="$2"
    if eval "$cmd" &>/dev/null; then
        local ver
        ver=$(eval "$cmd" 2>&1 | head -n1)
        echo -e "  ${GREEN}OK${NC}  $name: $ver"
        PASS=$((PASS + 1))
    else
        echo -e "  ${RED}FAIL${NC}  $name: NOT FOUND"
        FAIL=$((FAIL + 1))
    fi
}

echo "============================================"
echo "  LFS Host System Requirements Check"
echo "============================================"
echo ""

check_cmd "Bash"       "bash --version | head -n1"
check_cmd "Binutils"   "ld --version | head -n1"
check_cmd "Bison"      "bison --version | head -n1"
check_cmd "Coreutils"  "chown --version | head -n1"
check_cmd "Diffutils"  "diff --version | head -n1"
check_cmd "Findutils"  "find --version | head -n1"
check_cmd "Gawk"       "gawk --version | head -n1"
check_cmd "GCC"        "gcc --version | head -n1"
check_cmd "G++"        "g++ --version | head -n1"
check_cmd "Grep"       "grep --version | head -n1"
check_cmd "Gzip"       "gzip --version | head -n1"
check_cmd "M4"         "m4 --version | head -n1"
check_cmd "Make"       "make --version | head -n1"
check_cmd "Patch"      "patch --version | head -n1"
check_cmd "Perl"       "perl -V:version 2>/dev/null"
check_cmd "Python"     "python3 --version"
check_cmd "Sed"        "sed --version | head -n1"
check_cmd "Tar"        "tar --version | head -n1"
check_cmd "Texinfo"    "makeinfo --version | head -n1"
check_cmd "Xz"         "xz --version | head -n1"

echo ""
echo "--- Symlinks ---"

if [ -h /usr/bin/yacc ]; then
    echo -e "  ${GREEN}OK${NC}  /usr/bin/yacc -> $(readlink -f /usr/bin/yacc)"
    PASS=$((PASS + 1))
elif [ -x /usr/bin/yacc ]; then
    echo -e "  ${YELLOW}WARN${NC}  /usr/bin/yacc exists but is not a symlink"
    PASS=$((PASS + 1))
else
    echo -e "  ${RED}FAIL${NC}  /usr/bin/yacc not found"
    FAIL=$((FAIL + 1))
fi

if [ -h /usr/bin/awk ]; then
    echo -e "  ${GREEN}OK${NC}  /usr/bin/awk -> $(readlink -f /usr/bin/awk)"
    PASS=$((PASS + 1))
elif [ -x /usr/bin/awk ]; then
    echo -e "  ${YELLOW}WARN${NC}  /usr/bin/awk exists but is not a symlink"
    PASS=$((PASS + 1))
else
    echo -e "  ${RED}FAIL${NC}  /usr/bin/awk not found"
    FAIL=$((FAIL + 1))
fi

echo ""
echo "--- Kernel ---"

if [ -e /proc/version ]; then
    echo -e "  ${GREEN}OK${NC}  Linux kernel: $(cat /proc/version | cut -d' ' -f3)"
    PASS=$((PASS + 1))
else
    echo -e "  ${RED}FAIL${NC}  Cannot detect kernel version"
    FAIL=$((FAIL + 1))
fi

echo ""
echo "--- Libraries ---"

if [ -f /usr/lib/libgmp.la ] || ldconfig -p 2>/dev/null | grep -q libgmp; then
    echo -e "  ${GREEN}OK${NC}  libgmp found"
    PASS=$((PASS + 1))
else
    echo -e "  ${YELLOW}WARN${NC}  libgmp not found"
fi

if [ -f /usr/lib/libmpfr.la ] || ldconfig -p 2>/dev/null | grep -q libmpfr; then
    echo -e "  ${GREEN}OK${NC}  libmpfr found"
    PASS=$((PASS + 1))
else
    echo -e "  ${YELLOW}WARN${NC}  libmpfr not found"
fi

if [ -f /usr/lib/libmpc.la ] || ldconfig -p 2>/dev/null | grep -q libmpc; then
    echo -e "  ${GREEN}OK${NC}  libmpc found"
    PASS=$((PASS + 1))
else
    echo -e "  ${YELLOW}WARN${NC}  libmpc not found"
fi

echo ""
echo "============================================"
echo -e "  Results: ${GREEN}${PASS} passed${NC}, ${RED}${FAIL} failed${NC}"
echo "============================================"

if [ "$FAIL" -gt 0 ]; then
    echo ""
    echo -e "${RED}Some requirements are missing. Install them before proceeding.${NC}"
    exit 1
else
    echo ""
    echo -e "${GREEN}All requirements met!${NC}"
fi
