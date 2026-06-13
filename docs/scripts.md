# Build Scripts

The `scripts/` directory contains numbered shell scripts that automate the LFS build process. They are designed to be run in order, though phases 2–3 and the manual system build (LFS chapters 8–9) are the longest steps.

## Script index

| Script | Phase | User | Environment | LFS chapter |
|--------|-------|------|-------------|-------------|
| `00-check-host.sh` | Pre-build | any | Host | 2.2 |
| `01-prepare-disk.sh` | Disk setup | root | Host | 2.3–2.4 |
| `02-toolchain-cross.sh` | Cross-toolchain | lfs | Host | 5 |
| `03-toolchain-temp.sh` | Temporary tools | lfs | Host | 6–7 |
| `04-chroot-setup.sh` | Chroot prep | root | Host | 7 |
| `06-build-kernel.sh` | Kernel | root | Chroot | 10 |
| `07-configure-grub.sh` | Bootloader | root | Chroot | 10 |
| `08-final-checks.sh` | Validation | any | Booted system | — |

> There is no `05-build-system.sh`. Building the 70+ system packages (LFS chapters 8–9) must be done manually following the LFS book.

---

## 00-check-host.sh

### Purpose

Verifies that the host system has all tools required to begin an LFS build.

### When to run

Before anything else, on the host Linux system inside the VM.

### Usage

```bash
bash scripts/00-check-host.sh
```

### What it checks

**Commands (20 tools):**

| Tool | Why needed |
|------|-----------|
| bash | Script execution, LFS build |
| ld (binutils) | Linking |
| bison | Parser generator (GCC dependency) |
| chown (coreutils) | File ownership during build |
| diff, find, gawk, grep, sed | Text processing |
| gcc, g++ | Compilation |
| gzip, tar, xz | Archive handling |
| m4 | Macro processor |
| make | Build orchestration |
| patch | Applying LFS patches |
| perl, python3 | Build scripts in various packages |
| makeinfo (texinfo) | Documentation builds |

**Symlinks:**

- `/usr/bin/yacc` → should point to bison
- `/usr/bin/awk` → should point to gawk

**Libraries (warnings only):**

- libgmp, libmpfr, libmpc — required for building GCC

### Output

Color-coded results: green OK, red FAIL, yellow WARN. Exits with code 1 if any mandatory check fails.

---

## 01-prepare-disk.sh

### Purpose

Partitions the virtual disk, creates filesystems, mounts partitions, and sets up the `$LFS` environment variable.

### When to run

On the host, as root, after host checks pass.

### Usage

```bash
sudo bash scripts/01-prepare-disk.sh [/dev/sdX]
```

Default disk: `/dev/sda`

### Partition layout

```
/dev/sda1   500 MB   ext2    /boot
/dev/sda2   ~28 GB   ext4    /       ($LFS mount point)
/dev/sda3   2 GB     swap
```

### Steps performed

1. **Confirmation prompt** — requires typing `YES` to proceed (destructive operation)
2. **Partition** — `parted` creates MBR (msdos) partition table with 3 partitions
3. **Format** — `mkfs.ext2`, `mkfs.ext4`, `mkswap`
4. **Mount** — root at `$LFS` (default `/mnt/lfs`), boot at `$LFS/boot`
5. **Swap** — `swapon` activates swap
6. **Persist** — appends `export LFS=/mnt/lfs` to `~/.bashrc`

### Environment variable

```bash
export LFS=/mnt/lfs
```

All subsequent scripts use this variable to locate the target system.

### Safety

- Requires root privileges
- Erases all data on the target disk
- Interactive confirmation prevents accidental execution

---

## 02-toolchain-cross.sh

### Purpose

Builds the cross-compilation toolchain: programs on the host that produce binaries for the target `$(uname -m)-lfs-linux-gnu` system.

### When to run

As user `lfs` (not root), with `$LFS` set and sources copied to `$LFS/sources`.

### Usage

```bash
export LFS=/mnt/lfs
bash scripts/02-toolchain-cross.sh
```

### Packages built (in order)

#### 1. Binutils (Pass 1)

- Installed to `$LFS/tools`
- Provides cross-assembler (`as`), cross-linker (`ld`) for target triplet
- Configured with `--with-sysroot=$LFS` so it knows where the future root is

#### 2. GCC (Pass 1)

- Minimal C compiler without standard library headers
- Bundles MPFR, GMP, MPC source trees inside GCC directory
- Disables threads, shared libs, C++ standard library
- Creates `limits.h` workaround after install

#### 3. Linux API Headers

- Extracts kernel headers to `$LFS/usr/include`
- Provides system call definitions, struct definitions for libc

#### 4. Glibc

- The C standard library — most critical component
- Applies LFS FHS patch (`glibc-*-fhs-1.patch`)
- Installed with `DESTDIR=$LFS` (files go into the future root)
- Creates dynamic linker symlinks for x86_64

#### 5. Libstdc++ (from GCC)

- C++ standard library
- Minimal build needed for some later packages

### Key variables

| Variable | Example | Purpose |
|----------|---------|---------|
| `LFS` | `/mnt/lfs` | Target root filesystem |
| `LFS_TGT` | `x86_64-lfs-linux-gnu` | Cross-compilation triplet |
| `MAKEFLAGS` | `-j4` | Parallel compilation |
| `SOURCES` | `$LFS/sources` | Tarball location |

### Duration

4–8 hours depending on CPU cores and VM performance.

### Error handling

Uses `set -euo pipefail` — exits immediately on any error. Failed builds must be investigated and the script re-run from the failed package.

---

## 03-toolchain-temp.sh

### Purpose

Builds additional tools installed into `$LFS` using the cross-compiler. These utilities are needed to complete the chroot environment.

### When to run

As user `lfs`, after `02-toolchain-cross.sh` completes.

### Usage

```bash
bash scripts/03-toolchain-temp.sh
```

### Packages built (in order)

| # | Package | Notes |
|---|---------|-------|
| 1 | M4 | Macro processor |
| 2 | Ncurses | Terminal library; builds `tic` helper first |
| 3 | Bash | Shell; `/bin/sh` symlinked to bash |
| 4 | Coreutils | Basic file utilities; `chroot` moved to `/usr/sbin` |
| 5 | Diffutils | File comparison |
| 6 | File | File type detection |
| 7 | Findutils | `find`, `locate`, `xargs` |
| 8 | Gawk | AWK interpreter |
| 9 | Grep | Pattern matching |
| 10 | Gzip | Compression |
| 11 | Make | Build tool |
| 12 | Patch | Source patching |
| 13 | Sed | Stream editor |
| 14 | Tar | Archiving |
| 15 | Xz | Compression |
| 16 | Binutils (Pass 2) | Native binutils in `$LFS/usr` |
| 17 | GCC (Pass 2) | Full native compiler; `cc` symlinked to `gcc` |

### Build pattern

Each package follows the same pattern:

```bash
tar -xf <package>*.tar.*
cd <package>-*/
./configure --prefix=/usr --host=$LFS_TGT --build=$(config.guess)
make -j$(nproc)
make DESTDIR=$LFS install
cd $SOURCES && rm -rf <package>-*/
```

`DESTDIR=$LFS` installs files into the future root without affecting the host.

### Duration

4–8 hours.

---

## 04-chroot-setup.sh

### Purpose

Prepares the chroot environment: fixes ownership, creates FHS directory tree, mounts virtual filesystems, creates essential system files.

### When to run

As **root**, after temporary tools are built.

### Usage

```bash
sudo bash scripts/04-chroot-setup.sh
```

### Steps

#### 1. Ownership

Changes `$LFS` tree ownership from `lfs` user back to `root`.

#### 2. FHS directory structure

Creates the full filesystem hierarchy:

```
/bin /boot /dev /etc /home /lib /media /mnt /opt /proc /root /run /sbin /srv /sys /tmp /usr /var
```

Including all standard subdirectories (`/usr/bin`, `/var/log`, `/usr/share/man/man1` through `man8`, etc.).

#### 3. Virtual filesystem mounts

| Mount | Type | Purpose |
|-------|------|---------|
| `$LFS/dev` | bind | Device nodes |
| `$LFS/dev/pts` | devpts | Pseudo-terminals |
| `$LFS/proc` | proc | Process info |
| `$LFS/sys` | sysfs | Kernel objects |
| `$LFS/run` | tmpfs | PID files, sockets |
| `$LFS/dev/shm` | tmpfs | Shared memory |

#### 4. Essential files

- `/etc/passwd` — root and system users
- `/etc/group` — system groups including `wheel`, `utmp`, `dialout`
- `/etc/mtab` → symlink to `/proc/self/mounts`
- `/var/log/btmp`, `lastlog`, `faillog`, `wtmp` — login tracking

### Entering chroot

After this script, enter the chroot environment:

```bash
chroot "$LFS" /usr/bin/env -i \
    HOME=/root \
    TERM="$TERM" \
    PS1='(lfs chroot) \u:\w\$ ' \
    PATH=/usr/bin:/usr/sbin \
    MAKEFLAGS="-j$(nproc)" \
    /bin/bash --login
```

Inside chroot, `$LFS` is no longer relevant — `/` is the root.

---

## 06-build-kernel.sh

### Purpose

Builds the Linux kernel with the student login in `LOCALVERSION`, installs it to `/boot` with the required naming convention.

### When to run

Inside chroot, after all system packages are built (including development tools needed for kernel compilation).

### Usage

```bash
bash scripts/06-build-kernel.sh <student_login>
```

### Steps

1. **Find kernel tarball** — locates `linux-*.tar.xz` in `/sources`
2. **Extract** — unpacks to `/usr/src/kernel-<version>` (required by project)
3. **Clean** — `make mrproper` removes any previous build artifacts
4. **Configure** — `make menuconfig` (interactive)
5. **Build** — `make -j$(nproc)`
6. **Install modules** — `make modules_install`
7. **Copy kernel image** — `bzImage` → `/boot/vmlinuz-<version>-<login>`

### menuconfig requirements

Enable these options:

| Category | Option |
|----------|--------|
| General Setup | Local version: `-<student_login>` |
| General Setup | Enable loadable module support |
| Device Drivers → Generic | Maintain a devtmpfs filesystem |
| File systems | ext4, proc, sysfs, tmpfs |
| Networking | TCP/IP networking |
| Device Drivers → Network | Your VM's NIC driver (e1000 for VirtualBox, vmxnet3 for VMware) |

### Output files

| File | Path |
|------|------|
| Kernel image | `/boot/vmlinuz-6.16.1-<login>` |
| Symbol map | `/boot/System.map-6.16.1-<login>` |
| Config | `/boot/config-6.16.1-<login>` |
| Sources | `/usr/src/kernel-6.16.1` |

### Verification

After reboot: `uname -r` should show `6.16.1-<login>`

---

## 07-configure-grub.sh

### Purpose

Installs GRUB bootloader to the disk and generates `/boot/grub/grub.cfg`.

### When to run

Inside chroot, after kernel is built.

### Usage

```bash
bash scripts/07-configure-grub.sh <student_login> [boot_disk] [root_partition]
```

Defaults: boot disk `/dev/sda`, root partition `/dev/sda2`

### Steps

1. **Find kernel** — locates `/boot/vmlinuz-*-<login>`
2. **Install GRUB** — `grub-install /dev/sda` writes boot code to MBR
3. **Generate config** — creates `/boot/grub/grub.cfg` with:
   - Default entry pointing to the custom kernel
   - `root=/dev/sda2 ro` kernel parameter
   - 5-second timeout

### Generated grub.cfg example

```
menuentry "ft_linux 6.16.1-jdoe" {
    set root=(hd0,2)
    linux /boot/vmlinuz-6.16.1-jdoe root=/dev/sda2 ro
}
```

### After this script

Exit chroot, unmount virtual filesystems, unmount partitions, and reboot into ft_linux.

---

## 08-final-checks.sh

### Purpose

Automated validation of all mandatory ft_linux project requirements. Run on the booted system before evaluation.

### When to run

On the fully booted ft_linux system.

### Usage

```bash
bash scripts/08-final-checks.sh [student_login]
```

Defaults to current hostname if login not provided.

### Check categories

#### Kernel (mandatory)

- Version >= 4.0
- Version string contains student login
- Sources exist in `/usr/src/kernel-*`
- Binary named `vmlinuz-<ver>-<login>` in `/boot`

#### Partitions (mandatory)

- `/boot` is a separate mounted partition
- Swap is active
- Root `/` is mounted

#### Hostname (mandatory)

- `hostname` output equals student login

#### Bootloader (mandatory)

- `grub-install` binary exists
- `/boot/grub/grub.cfg` exists

#### Init system (warning)

- SysVinit or systemd process running

#### Device manager (mandatory)

- `udevd` or `systemd-udevd` process running

#### Networking (mandatory)

- Network interface is UP
- Has IPv4 address
- Can ping 8.8.8.8
- Can resolve google.com

#### Download capability (mandatory)

- `wget` or `curl` installed

#### FHS (warning)

- All 18 standard top-level directories exist

#### Key packages (warning)

- 17 essential commands available in PATH

### Result levels

| Level | Meaning |
|-------|---------|
| PASS (green) | Mandatory requirement met |
| FAIL (red) | Mandatory requirement not met — must fix |
| WARN (yellow) | Recommended but not strictly required |

Exits with code 1 if any FAIL results exist.

---

## Common environment setup

Before running build scripts on the host:

```bash
export LFS=/mnt/lfs
export PATH="$LFS/tools/bin:$PATH"
export CONFIG_SITE="$LFS/usr/share/config.site"
export MAKEFLAGS="-j$(nproc)"
```

Create the `lfs` user (LFS chapter 4.1):

```bash
groupadd lfs
useradd -s /bin/bash -g lfs -m -k /dev/null lfs
chown -R lfs:lfs $LFS
```

## Script conventions

| Convention | Used in |
|------------|---------|
| `set -euo pipefail` | All scripts except 00 and 08 |
| Color output (green/red/yellow) | All scripts |
| `log()` helper function | All scripts |
| Sequential numbering | 00–08 (05 intentionally skipped) |
| `DESTDIR=$LFS` installs | 02, 03 |
| Root requirement | 01, 04 |
| Chroot requirement | 06, 07 |
| Booted system requirement | 08 |
