#!/bin/bash
# Run INSIDE the booted ft_linux system.

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

PASS=0
FAIL=0
WARN=0

check() {
    local desc="$1"
    local result="$2"
    if [ "$result" = "0" ]; then
        echo -e "  ${GREEN}PASS${NC}  $desc"
        PASS=$((PASS + 1))
    else
        echo -e "  ${RED}FAIL${NC}  $desc"
        FAIL=$((FAIL + 1))
    fi
}

check_warn() {
    local desc="$1"
    local result="$2"
    if [ "$result" = "0" ]; then
        echo -e "  ${GREEN}PASS${NC}  $desc"
        PASS=$((PASS + 1))
    else
        echo -e "  ${YELLOW}WARN${NC}  $desc"
        WARN=$((WARN + 1))
    fi
}

STUDENT_LOGIN="${1:-$(hostname)}"

echo "============================================"
echo "  ft_linux Final Validation"
echo "  Student: $STUDENT_LOGIN"
echo "============================================"
echo ""

echo "--- Kernel ---"
KVER=$(uname -r)
check "Kernel version >= 4.0" "$(echo "$KVER" | awk -F. '{print ($1 >= 4) ? 0 : 1}')"
check "Kernel contains student login ($STUDENT_LOGIN)" "$(echo "$KVER" | grep -qc "$STUDENT_LOGIN"; echo $((1 - $?)))"
check "Kernel sources in /usr/src/kernel-*" "$(ls -d /usr/src/kernel-* &>/dev/null; echo $?)"

KFILE=$(ls /boot/vmlinuz-*-"${STUDENT_LOGIN}" 2>/dev/null | head -1)
if [ -n "$KFILE" ]; then
    check "Kernel binary named vmlinuz-<ver>-<login>" "0"
else
    check "Kernel binary named vmlinuz-<ver>-<login>" "1"
fi

echo ""
echo "--- Partitions ---"
check "/boot is a separate partition" "$(mount | grep -qc '/boot '; echo $((1 - $?)))"
check "swap is active" "$(swapon --show 2>/dev/null | grep -qc 'partition\|/dev'; echo $((1 - $?)))"
check "root (/) is mounted" "$(mount | grep -qc 'on / '; echo $((1 - $?)))"

echo ""
echo "--- Hostname ---"
check "Hostname = $STUDENT_LOGIN" "$([ \"$(hostname)\" = \"$STUDENT_LOGIN\" ] && echo 0 || echo 1)"

echo ""
echo "--- Bootloader ---"
check "GRUB installed" "$(command -v grub-install &>/dev/null; echo $?)"
check "/boot/grub/grub.cfg exists" "$([ -f /boot/grub/grub.cfg ] && echo 0 || echo 1)"

echo ""
echo "--- Init System ---"
check_warn "SysVinit running" "$(pidof init &>/dev/null; echo $?)"
check_warn "systemd running" "$(pidof systemd &>/dev/null; echo $?)"

echo ""
echo "--- Device Manager ---"
check "udevd is running" "$(pidof udevd systemd-udevd &>/dev/null; echo $?)"

echo ""
echo "--- Networking ---"
check "Network interface UP" "$(ip link show | grep -qc 'state UP'; echo $((1 - $?)))"
check "Has IP address" "$(ip -4 addr show | grep -qc 'inet '; echo $((1 - $?)))"
check "Internet connectivity" "$(ping -c1 -W3 8.8.8.8 &>/dev/null; echo $?)"
check "DNS resolution" "$(ping -c1 -W3 google.com &>/dev/null; echo $?)"

echo ""
echo "--- Download capability ---"
if command -v wget &>/dev/null; then
    check "wget installed" "0"
elif command -v curl &>/dev/null; then
    check "curl installed" "0"
else
    check "wget or curl installed" "1"
fi

echo ""
echo "--- FHS ---"
for dir in /bin /boot /dev /etc /home /lib /media /mnt /opt /proc /root /run /sbin /srv /sys /tmp /usr /var; do
    check_warn "$dir exists" "$([ -d $dir ] && echo 0 || echo 1)"
done

echo ""
echo "--- Key Packages ---"
for cmd in bash gcc make ld bison flex gawk grep sed tar gzip xz patch less vim perl python3; do
    check_warn "$cmd available" "$(command -v $cmd &>/dev/null; echo $?)"
done

echo ""
echo "============================================"
echo -e "  Results: ${GREEN}${PASS} passed${NC}, ${RED}${FAIL} failed${NC}, ${YELLOW}${WARN} warnings${NC}"
echo "============================================"

if [ "$FAIL" -gt 0 ]; then
    echo -e "${RED}Some mandatory checks FAILED.${NC}"
    exit 1
else
    echo -e "${GREEN}All mandatory checks passed!${NC}"
fi
