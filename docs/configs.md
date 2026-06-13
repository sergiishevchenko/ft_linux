# Configuration Templates

The `configs/` directory contains templates for system files that will be copied or adapted into the ft_linux installation at `$LFS/etc/` and `$LFS/boot/grub/`.

These are **templates**, not live configs. They must be customized (replace placeholders, adjust device names) before deployment.

## Deployment

```bash
# Inside chroot, after system packages are built:
cp configs/fstab       /etc/fstab
cp configs/hostname    /etc/hostname
cp configs/hosts       /etc/hosts
cp configs/resolv.conf /etc/resolv.conf
cp configs/locale.conf /etc/locale.conf
cp configs/profile     /etc/profile
cp configs/inputrc     /etc/inputrc
cp configs/shells      /etc/shells
cp configs/inittab     /etc/inittab
```

Or copy from the repo before entering chroot:

```bash
cp -v configs/* $LFS/etc/
```

---

## fstab

**Target path:** `/etc/fstab`

Defines which filesystems are mounted at boot.

| Device | Mount point | Type | Purpose |
|--------|-------------|------|---------|
| `/dev/sda2` | `/` | ext4 | Root filesystem |
| `/dev/sda1` | `/boot` | ext2 | Kernel and GRUB files |
| `/dev/sda3` | — | swap | Virtual memory |
| `proc` | `/proc` | proc | Process information |
| `sysfs` | `/sys` | sysfs | Kernel device tree |
| `devpts` | `/dev/pts` | devpts | Pseudo-terminals |
| `tmpfs` | `/run` | tmpfs | Runtime data |
| `devtmpfs` | `/dev` | devtmpfs | Device nodes (udev) |
| `tmpfs` | `/dev/shm` | tmpfs | Shared memory |

The last six entries are virtual filesystems required by the kernel and udev. They are not stored on disk.

**Customize:** Replace `/dev/sda1`, `/dev/sda2`, `/dev/sda3` with your actual partition layout. Use `blkid` to find UUIDs for a more robust setup:

```
UUID=abc123...  /       ext4  defaults  1  1
```

---

## grub.cfg

**Target path:** `/boot/grub/grub.cfg`

GRUB bootloader menu configuration.

| Setting | Value | Meaning |
|---------|-------|---------|
| `set default=0` | First menu entry | Boot the ft_linux entry by default |
| `set timeout=5` | 5 seconds | GRUB menu display time |
| `insmod ext2` | Load ext2 module | Needed to read `/boot` partition |
| `set root=(hd0,2)` | Second partition | GRUB's view of root partition |
| `linux /boot/vmlinuz-...` | Kernel path | Relative to GRUB root |
| `root=/dev/sda2 ro` | Kernel parameter | Mount root read-only at boot |

**Placeholders to replace:**

- `<STUDENT_LOGIN>` — your 42 login
- `<LINUX_VERSION>` — kernel version (e.g. `6.16.1`)

**GRUB device mapping:**

| GRUB | Linux device |
|------|-------------|
| `(hd0,1)` | `/dev/sda1` |
| `(hd0,2)` | `/dev/sda2` |
| `(hd0,3)` | `/dev/sda3` |

Note: `07-configure-grub.sh` generates this file automatically with correct values.

---

## hostname

**Target path:** `/etc/hostname`

Single line containing the system hostname. Must equal the student 42 login per project requirements.

```
<STUDENT_LOGIN>
```

Read by `hostname` command and network services at boot.

---

## hosts

**Target path:** `/etc/hosts`

Static hostname-to-IP mapping.

| IP | Hostname | Purpose |
|----|----------|---------|
| `127.0.0.1` | `localhost` | Loopback |
| `127.0.1.1` | `<STUDENT_LOGIN>` | Local hostname resolution |
| `::1` | `localhost ip6-localhost ip6-loopback` | IPv6 loopback |
| `ff02::1` | `ip6-allnodes` | IPv6 multicast |
| `ff02::2` | `ip6-allrouters` | IPv6 multicast |

The `127.0.1.1` entry prevents sudo warnings about unresolvable hostname.

---

## resolv.conf

**Target path:** `/etc/resolv.conf`

DNS resolver configuration. Uses Google Public DNS by default.

```
nameserver 8.8.8.8
nameserver 8.8.4.4
```

Required for internet connectivity and DNS resolution during evaluation. Replace with your preferred DNS servers if needed.

---

## locale.conf

**Target path:** `/etc/locale.conf`

System-wide locale settings.

```
LANG=en_US.UTF-8
LC_ALL=en_US.UTF-8
```

Defines the default language and character encoding. Must match locales generated during the LFS build (`localedef` step in LFS chapter 9).

---

## profile

**Target path:** `/etc/profile`

System-wide environment for all login shells.

| Setting | Value | Purpose |
|---------|-------|---------|
| `LANG` | `en_US.UTF-8` | Locale |
| `PATH` | `/usr/local/sbin:...:/bin` | Standard FHS path |
| `HISTSIZE` | `1000` | Command history length |
| `HISTFILESIZE` | `2000` | History file size |
| `umask` | `022` | Default file permissions (755 dirs, 644 files) |

Also sources any scripts in `/etc/profile.d/*.sh` if that directory exists.

---

## inputrc

**Target path:** `/etc/inputrc`

Readline library configuration — affects Bash and other programs using readline.

Configures:

- Meta key behavior for terminal emulators
- Key bindings for Home, End, Delete, arrow keys in both default and VT100 modes
- Disabled terminal bell

This ensures consistent line editing across different terminal types (physical console, SSH, serial).

---

## shells

**Target path:** `/etc/shells`

List of valid login shells. Only shells listed here can be set as a user's login shell via `chsh`.

```
/bin/sh
/bin/bash
```

`/bin/sh` is a symlink to Bash (created during LFS temporary tools build).

---

## inittab

**Target path:** `/etc/inittab`

SysVinit configuration — controls boot runlevels and getty terminals.

### Structure

Each line: `id:runlevels:action:process`

| Line | Meaning |
|------|---------|
| `id:3:initdefault:` | Default runlevel 3 (multi-user, no GUI) |
| `si::sysinit:...` | Run boot scripts on startup |
| `l0`–`l6` | Transition scripts for each runlevel |
| `ca:12345:ctrlaltdel:...` | Reboot on Ctrl+Alt+Del |
| `su:S06:once:...` | Single-user recovery on boot failure |
| `1`–`6:2345:respawn:...` | Login prompts on tty1–tty6 |

### Runlevels

| Level | Mode |
|-------|------|
| 0 | Halt |
| 1 | Single-user |
| 2 | Multi-user (no NFS) |
| 3 | Multi-user (default) |
| 4 | Unused |
| 5 | Multi-user (same as 3 without GUI) |
| 6 | Reboot |

Requires `lfs-bootscripts` package installed during LFS chapter 9 for `/etc/rc.d/init.d/rc` to work.
