# ft_linux

Custom Linux distribution built from scratch following [Linux From Scratch (LFS) 12.4](https://www.linuxfromscratch.org/lfs/view/stable/).

> 42 project · Version 3.6

## What is this

A fully functional Linux system compiled entirely from source code — kernel, toolchain, core utilities, networking, bootloader. No package manager, no pre-built binaries. Everything is built by hand (or by the scripts in this repo).

### Key specs

| Component | Choice |
|-----------|--------|
| Kernel | Linux 6.16.1 |
| Init system | SysVinit 3.14 |
| Bootloader | GRUB 2.12 |
| Compiler | GCC 15.2.0 |
| C library | Glibc 2.42 |
| Shell | Bash 5.3 |
| Device manager | Eudev (udev-lfs) |
| Partitions | `/boot` (ext2) + `/` (ext4) + swap |

### Mandatory packages (70+)

Acl, Attr, Autoconf, Automake, Bash, Bc, Binutils, Bison, Bzip2, Check, Coreutils, DejaGNU, Diffutils, E2fsprogs, Elfutils, Eudev, Expat, Expect, File, Findutils, Flex, Gawk, GCC, GDBM, Gettext, Glibc, GMP, Gperf, Grep, Groff, GRUB, Gzip, Iana-Etc, Inetutils, Intltool, IPRoute2, Kbd, Kmod, Less, Libcap, Libpipeline, Libtool, M4, Make, Man-DB, Man-pages, MPC, MPFR, Ncurses, OpenSSL, Patch, Perl, Pkg-config, Procps, Psmisc, Python, Readline, Sed, Shadow, Sysklogd, Sysvinit, Tar, Tcl, Texinfo, Util-linux, Vim, XML::Parser, Xz, Zlib, Zstd

## Project structure

```
.
├── PLAN.md                     # Build plan with full checklist
├── docs/                       # Technical documentation
├── sources/
│   ├── wget-list.txt           # 90 package URLs
│   ├── md5sums.txt             # Checksums
│   └── download.sh             # Download + verify
├── configs/
│   ├── fstab / grub.cfg        # Mount table + bootloader
│   ├── hostname / hosts        # Network identity
│   ├── ifconfig.eth0[.dhcp]    # Network interface
│   └── ...                     # locale, profile, inittab, etc.
└── scripts/
    ├── lib.sh                  # Shared helpers
    ├── setup-lfs-user.sh       # Create lfs user + env
    ├── apply-configs.sh        # Deploy configs with login
    ├── 00-check-host.sh
    ├── 01-prepare-disk.sh
    ├── 02-toolchain-cross.sh
    ├── 03-toolchain-temp.sh
    ├── 04-chroot-setup.sh
    ├── 05-build-system.sh      # LFS Ch.8–9 packages
    ├── 06-build-kernel.sh
    ├── 07-configure-grub.sh
    ├── 08-final-checks.sh
    └── 09-umount-and-reboot.sh
```

## Quick start

```bash
# 1. Check host system has all required tools
bash scripts/00-check-host.sh

# 2. Download all source packages (~1.5 GB)
bash sources/download.sh

# 3. Prepare disk (as root, inside VM)
bash scripts/01-prepare-disk.sh /dev/sda

# 4. Create lfs user
bash scripts/setup-lfs-user.sh

# 5. Build cross-toolchain (as user 'lfs')
su - lfs
bash scripts/02-toolchain-cross.sh
bash scripts/03-toolchain-temp.sh
exit

# 6. Setup and enter chroot (as root)
bash scripts/04-chroot-setup.sh
chroot "$LFS" /usr/bin/env -i HOME=/root TERM="$TERM" \
  PS1='(lfs) \u:\w\$ ' PATH=/usr/bin:/usr/sbin MAKEFLAGS="-j$(nproc)" \
  /bin/bash --login

# 7. Build all system packages inside chroot
bash scripts/05-build-system.sh

# 8. Apply configs + build kernel + GRUB
bash scripts/apply-configs.sh <student_login> /
bash scripts/06-build-kernel.sh <student_login>
bash scripts/07-configure-grub.sh <student_login>
exit

# 9. Unmount and reboot
bash scripts/09-umount-and-reboot.sh
reboot

# 10. Validate on booted system
bash scripts/08-final-checks.sh <student_login>
```

## Requirements

| Resource | Minimum |
|----------|---------|
| Hypervisor | VirtualBox or VMWare |
| Host OS | Any Linux (Debian minimal or LFS Live CD) |
| Disk | 30 GB |
| RAM | 4 GB |
| CPU cores | 2+ (more = faster compilation) |

## Project requirements checklist

- [x] Kernel version >= 4.0
- [ ] Kernel version string contains student login
- [ ] Kernel sources in `/usr/src/kernel-$(version)`
- [ ] Kernel binary: `/boot/vmlinuz-<version>-<login>`
- [ ] Hostname = student login
- [ ] At least 3 partitions: `/`, `/boot`, swap
- [ ] Bootloader (GRUB) works
- [ ] Device manager (eudev/udev) works
- [ ] Init system (SysVinit or systemd)
- [ ] FHS-compliant filesystem hierarchy
- [ ] Internet connectivity
- [ ] All mandatory packages installed
- [ ] Can download source code (wget/curl)
- [ ] System boots and is stable

## Submission

```bash
shasum < disk.vdi
```

Push the checksum to the git repo. Keep the disk image for peer-evaluation.

## Resources

- [Linux From Scratch](https://www.linuxfromscratch.org/lfs/view/stable/) — the primary guide
- [Beyond Linux From Scratch](https://www.linuxfromscratch.org/blfs/view/stable/) — for bonus (X Server, DE)
- [Filesystem Hierarchy Standard](https://refspecs.linuxfoundation.org/FHS_3.0/fhs-3.0.html)
- [Kernel.org](https://www.kernel.org/)
