# ft_linux Documentation

Detailed technical documentation for every component of the ft_linux project.

## Contents

| Document | Description |
|----------|-------------|
| [Overview](overview.md) | Project goals, architecture, and technology stack |
| [Sources](sources.md) | Package lists, checksums, and download workflow |
| [Configs](configs.md) | System configuration templates |
| [Scripts](scripts.md) | Build automation scripts |
| [Scripts addendum](scripts-addendum.md) | New helpers, Ch.8–9 builder, network templates |

## Quick reference

```
Host (VM)                    Chroot (inside $LFS)           Booted system
─────────                    ────────────────────           ─────────────
00-check-host.sh
sources/download.sh
01-prepare-disk.sh
setup-lfs-user.sh
02-toolchain-cross.sh
03-toolchain-temp.sh
04-chroot-setup.sh    →    05-build-system.sh
                      →    apply-configs.sh
                      →    06-build-kernel.sh
                      →    07-configure-grub.sh
09-umount-and-reboot.sh                              →   08-final-checks.sh
```

## Related files

- [PLAN.md](../PLAN.md) — build checklist
- [README.md](../README.md) — project quick start
