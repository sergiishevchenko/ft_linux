# Project Overview

## Purpose

**ft_linux** is a 42 school project (version 3.6) that requires building a minimal but fully functional Linux distribution from source. The resulting system becomes the base environment for all subsequent kernel-related projects at 42.

This repository does not contain the compiled distribution itself. Instead, it provides:

- Source package manifests aligned with [LFS 12.4 (SysV)](https://www.linuxfromscratch.org/lfs/view/stable/)
- Shell scripts that automate key LFS build phases
- Configuration templates for the target system
- A validation script that checks all mandatory project requirements

## What you are building

A bootable Linux system with:

| Requirement | Implementation |
|-------------|----------------|
| Custom kernel >= 4.0 | Linux 6.16.1 with `LOCALVERSION=-<login>` |
| Kernel sources location | `/usr/src/kernel-<version>` |
| Kernel binary name | `/boot/vmlinuz-<version>-<login>` |
| Hostname | Student 42 login |
| Partitions | `/boot` (ext2), `/` (ext4), swap |
| Bootloader | GRUB 2.12 |
| Init system | SysVinit 3.14 |
| Device manager | Eudev (udev-lfs) |
| Filesystem layout | FHS-compliant |
| Network | Working internet access |
| Packages | 70+ mandatory packages from the subject |

## Architecture

The build follows the standard LFS methodology in three environments:

```
┌─────────────────────────────────────────────────────────────┐
│  HOST SYSTEM (Debian minimal / LFS Live CD inside VM)       │
│                                                             │
│  Uses host GCC, make, etc. to cross-compile tools that      │
│  target the future ft_linux system.                         │
│                                                             │
│  $LFS = /mnt/lfs  (mounted root partition)                  │
│  $LFS/sources     (tarballs)                                │
│  $LFS/tools       (cross-compiled toolchain)                │
└──────────────────────────┬──────────────────────────────────┘
                           │ chroot
┌──────────────────────────▼──────────────────────────────────┐
│  CHROOT ENVIRONMENT ($LFS)                                  │
│                                                             │
│  Uses tools built in previous phases. No dependency on      │
│  host libraries. All remaining packages compiled here.      │
│                                                             │
│  Kernel built, GRUB installed, configs applied.             │
└──────────────────────────┬──────────────────────────────────┘
                           │ reboot
┌──────────────────────────▼──────────────────────────────────┐
│  BOOTED ft_linux SYSTEM                                     │
│                                                             │
│  Independent OS. Validated with 08-final-checks.sh.         │
└─────────────────────────────────────────────────────────────┘
```

## Repository layout

```
ft_linux/
├── PLAN.md          # Step-by-step checklist
├── README.md        # Quick start guide
├── .gitignore       # Excludes tarballs, VM images, build artifacts
├── docs/            # This documentation
├── sources/         # Package URLs, checksums, download script
├── configs/         # Templates for /etc and /boot/grub
└── scripts/         # Numbered build automation scripts
```

## Technology stack

| Layer | Package | Version |
|-------|---------|---------|
| Kernel | linux | 6.16.1 |
| Bootloader | grub | 2.12 |
| Init | sysvinit | 3.14 |
| C library | glibc | 2.42 |
| Compiler | gcc | 15.2.0 |
| Shell | bash | 5.3 |
| Editor | vim | 9.1 |
| Device manager | udev-lfs | 20230818 |
| Logging | sysklogd | 2.7.2 |

## Key concepts

### Cross-compilation

The host system compiles programs that run on a different target (`x86_64-lfs-linux-gnu`). This isolates the future system from the host's libraries and ensures reproducibility.

### Two-pass toolchain

1. **Pass 1** — minimal cross-compiler in `$LFS/tools` (Binutils, GCC without libc)
2. **Temporary tools** — utilities needed inside chroot (Bash, Coreutils, etc.)
3. **Pass 2** — full native compiler installed into `$LFS/usr`

### Chroot

After the temporary toolchain is ready, the build enters `$LFS` via `chroot`. From this point, `$LFS` is treated as the root filesystem (`/`). The host is only used to provide running processes and mounted virtual filesystems.

### FHS

The [Filesystem Hierarchy Standard](https://refspecs.linuxfoundation.org/FHS_3.0/fhs-3.0.html) defines where files live (`/bin`, `/etc`, `/usr`, `/var`, etc.). Script `04-chroot-setup.sh` creates the full directory tree.

## Placeholders

Several files use placeholders that must be replaced before use:

| Placeholder | Where | Example |
|-------------|-------|---------|
| `<STUDENT_LOGIN>` | hostname, hosts, grub.cfg, kernel scripts | `jdoe` |
| `<LINUX_VERSION>` | grub.cfg | `6.16.1` |
| `/dev/sdaX` | fstab, grub.cfg, disk scripts | Adjust to your VM disk layout |

## What is NOT in this repo

- Compiled binaries or the finished VM disk image
- Script `05-build-system.sh` — the main system build (LFS chapters 8–9, 70+ packages) must be done manually following the LFS book
- Network setup scripts — configured during system configuration phase
