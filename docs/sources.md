# Sources Directory

The `sources/` directory manages all upstream package tarballs required to build ft_linux.

## Files

| File | Purpose |
|------|---------|
| `wget-list.txt` | One URL per line — 90 packages and patches from LFS 12.4 SysV |
| `md5sums.txt` | MD5 checksums for integrity verification |
| `download.sh` | Automated downloader with resume and checksum validation |

Downloaded tarballs are stored in `sources/` but excluded from git via `.gitignore` (they total ~1.5 GB).

## wget-list.txt

### Origin

The list is taken directly from the official LFS 12.4 SysV variant:

```
https://www.linuxfromscratch.org/lfs/view/stable/wget-list-sysv
```

### Contents

The 90 entries include:

- **Core toolchain**: binutils, gcc, glibc, linux headers, mpfr, gmp, mpc
- **Build tools**: m4, make, autoconf, automake, libtool, bison, flex, patch
- **System utilities**: coreutils, bash, sed, grep, gawk, tar, gzip, xz
- **System libraries**: zlib, ncurses, readline, openssl, expat, attr, acl
- **System services**: sysvinit, sysklogd, eudev (udev-lfs), shadow, kmod
- **Documentation**: man-pages, man-db, texinfo, groff
- **Kernel**: linux-6.16.1
- **Bootloader**: grub-2.12
- **Boot scripts**: lfs-bootscripts
- **Patches**: 7 LFS-specific patches for bzip2, coreutils, expect, glibc, kbd, sysvinit
- **Dependencies**: python, perl, tcl, meson, ninja (needed by some packages)

### Format

Plain text, one HTTPS URL per line. No comments or blank lines. The download script reads URLs sequentially.

## md5sums.txt

### Origin

```
https://www.linuxfromscratch.org/lfs/view/stable/md5sums
```

### Format

```
<md5hash>  <filename>
```

Example:

```
32d45755e4b39d06e9be58f6817445ee  linux-6.16.1.tar.xz
b861b092bf1af683c46a8aa2e689a6fd  gcc-15.2.0.tar.xz
```

### Usage

After downloading, `download.sh` runs `md5sum -c md5sums.txt` inside the `sources/` directory. Any mismatch indicates a corrupted or incomplete download.

## download.sh

### How it works

```
┌──────────────┐     read URLs      ┌─────────────┐
│ wget-list.txt│ ─────────────────► │ download.sh │
└──────────────┘                    └──────┬──────┘
                                           │
                    for each URL:          │
                    ┌──────────────────────▼──────────────────────┐
                    │  file exists?  → SKIP                       │
                    │  else wget --continue --tries=3             │
                    └──────────────────────┬──────────────────────┘
                                           │
                    ┌──────────────────────▼──────────────────────┐
                    │  md5sum -c md5sums.txt                      │
                    └─────────────────────────────────────────────┘
```

### Behavior

1. **Dependency check** — requires `wget` on the system
2. **Resume support** — `wget --continue` skips fully downloaded files and resumes partial ones
3. **Skip existing** — if a tarball already exists, it is not re-downloaded
4. **Retry** — up to 3 attempts per URL with 30-second timeout
5. **Progress output** — shows `[current/total]` for each file with OK/FAIL/SKIP status
6. **Checksum verification** — runs automatically at the end if `md5sums.txt` is present

### Usage

```bash
bash sources/download.sh
```

Re-running the script is safe: it only downloads missing or failed packages.

### On the VM

After downloading on the host, copy tarballs to the build location:

```bash
mkdir -p $LFS/sources
cp -v sources/* $LFS/sources/
```

Or download directly inside the VM if network is available.

## Relationship to the build

| Build phase | Sources used |
|-------------|-------------|
| `02-toolchain-cross.sh` | binutils, gcc, mpfr, gmp, mpc, linux, glibc + glibc patch |
| `03-toolchain-temp.sh` | m4, ncurses, bash, coreutils, diffutils, file, findutils, gawk, grep, gzip, make, patch, sed, tar, xz, binutils, gcc |
| LFS Ch.8–9 (manual) | All remaining packages |
| `06-build-kernel.sh` | linux-6.16.1.tar.xz |
