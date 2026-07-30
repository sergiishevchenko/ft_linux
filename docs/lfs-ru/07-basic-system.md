# 07. Базовая система (глава 8 LFS)

Соответствует: **LFS Chapter 8 — Installing Basic System Software**  
Скрипт: `scripts/05-build-system.sh`  
Среда: **chroot, root**

## Что происходит в этой главе

Самая длинная часть LFS. Здесь собираются «настоящие» пакеты конечной системы:

- Glibc (финальная)
- GCC (финальный)
- Coreutils, Bash, Perl, Python, …
- Shadow, Util-linux, E2fsprogs
- SysVinit, udev/eudev, GRUB package, Vim, …

После главы 8 у тебя должен быть работоспособный userspace (ещё без своего ядра на `/boot`).

## Порядок пакетов важен

Нельзя ставить GCC до GMP/MPFR/MPC.  
Нельзя нормально собрать много пакетов до финального Glibc.  
Поэтому LFS задаёт жёсткий порядок.

Скрипт `05-build-system.sh` следует упрощённому порядку LFS 12.4 и умеет:

```bash
# внутри chroot
bash /root/scripts/05-build-system.sh           # всё подряд
bash /root/scripts/05-build-system.sh --list    # список пакетов
bash /root/scripts/05-build-system.sh --from zlib
bash /root/scripts/05-build-system.sh --reset   # сбросить state
```

Прогресс пишется в `/tmp/ft_linux_ch8.state`. При ошибке исправь пакет и продолжи с `--from`.

## Группы пакетов (по смыслу)

### Ядро userspace

| Пакет | Роль |
|-------|------|
| man-pages, iana-etc | документация и сетевые имена сервисов |
| glibc | стандартная C-библиотека |
| zlib, bzip2, xz, zstd | сжатие |
| readline, ncurses | терминал / line editing |

### Toolchain финальный

| Пакет | Роль |
|-------|------|
| binutils, gmp, mpfr, mpc, gcc | компилятор и линкер «навсегда» |
| m4, bison, flex, pkgconf | генераторы и pkg-config |
| make, automake, autoconf, libtool | система сборки |

### Безопасность и пользователи

| Пакет | Роль |
|-------|------|
| attr, acl, libcap, libxcrypt | права и capabilities |
| shadow | `passwd`, пользователи/группы |

### Утилиты и языки

| Пакет | Роль |
|-------|------|
| coreutils, findutils, grep, sed, gawk, tar | база UNIX |
| bash, less, vim | shell и редактор |
| perl, python, expat, openssl | скрипты и TLS |

### Система

| Пакет | Роль |
|-------|------|
| kmod, util-linux, e2fsprogs, procps | модули, диски, процессы |
| iproute2, inetutils | сеть |
| sysvinit, sysklogd, udev/eudev | init, логи, устройства |
| grub | пакет загрузчика |
| lfs-bootscripts | скрипты запуска SysV |
| tzdata | часовые пояса |

## Обязательные пакеты ft_linux

Сверься со subject: Acl, Attr, Autoconf, Automake, Bash, Bc, Binutils, Bison, Bzip2, Coreutils, Diffutils, E2fsprogs, Eudev, Expat, File, Findutils, Flex, Gawk, GCC, GDBM, Gettext, Glibc, GMP, Gperf, Grep, Groff, GRUB, Gzip, Iana-Etc, Inetutils, Intltool, IPRoute2, Kbd, Kmod, Less, Libcap, Libpipeline, Libtool, M4, Make, Man-DB, Man-pages, MPC, MPFR, Ncurses, Patch, Perl, Pkg-config, Procps, Psmisc, Readline, Sed, Shadow, Sysklogd, Sysvinit, Tar, Texinfo, Util-linux, Vim, XML::Parser, Xz, Zlib, …

Если скрипт пропустил пакет из subject — дособери вручную по [LFS Ch.8](https://www.linuxfromscratch.org/lfs/view/stable/chapter08/chapter08.html).

## Важные замечания

1. **Автоматизация ≠ магия.** Флаги LFS иногда меняются между минорными версиями. При ошибке `configure` открой официальную страницу пакета.
2. **udev.** В SysV-варианте LFS udev часто берётся из systemd sources + `udev-lfs`. Скрипт помечает это место предупреждением — доведи по книге.
3. **Тесты.** LFS иногда предлагает `make check`. Для ft_linux это желательно, но не всегда обязательно на защите; экономит время, если пропускать осознанно.
4. **После главы 8** ещё нужна конфигурация (глава 9) и ядро (глава 10).

## Время

**10–20 часов** компиляции — нормально.

## Итог главы

Основные пакеты установлены. Система почти «жива», но не настроена и не загружается своим ядром.

Далее: [08. Конфигурация системы](08-system-config.md)
