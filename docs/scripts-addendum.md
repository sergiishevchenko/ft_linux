# Scripts Addendum

New automation added offline (before VM work).

## New scripts

| Script | Role |
|--------|------|
| `lib.sh` | Shared helpers: log, extract, build_autotools, state tracking |
| `setup-lfs-user.sh` | Create `lfs` user, `.bashrc`, ownership of `$LFS` |
| `05-build-system.sh` | LFS Ch.8–9 package builds inside chroot (resumable) |
| `apply-configs.sh` | Copy templates and replace `<STUDENT_LOGIN>` / `<LINUX_VERSION>` |
| `09-umount-and-reboot.sh` | Unmount virtual FS and partitions on host before reboot |

## Network templates

| File | Purpose |
|------|---------|
| `configs/ifconfig.eth0` | Static IP for VirtualBox NAT (`10.0.2.15`) |
| `configs/ifconfig.eth0.dhcp` | DHCP alternative for eth0 |

## 05-build-system.sh

- Must run **inside chroot**
- Tracks progress in `/tmp/ft_linux_ch8.state`
- Resume: `bash 05-build-system.sh --from <package>`
- List packages: `bash 05-build-system.sh --list`
- Reset state: `bash 05-build-system.sh --reset`
- Some packages (especially full udev/eudev) may still need manual LFS book steps if configure flags differ
