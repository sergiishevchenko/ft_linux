# 08. Конфигурация системы

Соответствует: **LFS Chapter 9 — System Configuration**  
Скрипты/файлы: `scripts/apply-configs.sh`, `configs/*`

## Зачем конфигурация

Пакеты установлены, но система не знает:

- как монтировать диски
- как себя зовут
- какой DNS
- какой runlevel
- как поднять сеть

Без этого после reboot будет kernel panic / emergency shell / отсутствие сети.

## Быстрое применение шаблонов

Из chroot (или с хоста в `$LFS`):

```bash
bash scripts/apply-configs.sh <student_login> /
# или с хоста:
bash scripts/apply-configs.sh <student_login> $LFS
```

Скрипт подставляет `<STUDENT_LOGIN>` и `<LINUX_VERSION>` и копирует файлы в `/etc` и `/boot/grub`.

## Ключевые файлы

### `/etc/fstab`

Таблица монтирования. Должна совпадать с реальной разметкой:

```text
/dev/sda2  /      ext4  defaults  1 1
/dev/sda1  /boot  ext2  defaults  1 2
/dev/sda3  swap   swap  pri=1     0 0
```

Плюс virtual FS: `proc`, `sysfs`, `devpts`, `tmpfs`, `devtmpfs`.

Лучше позже заменить `/dev/sdaX` на `UUID=...` (`blkid`).

### `/etc/hostname` и `/etc/hosts`

Для ft_linux hostname = **твой login**.

```text
# hostname
jdoe

# hosts
127.0.0.1  localhost
127.0.1.1  jdoe
```

### `/etc/resolv.conf`

DNS, иначе не резолвятся имена:

```text
nameserver 8.8.8.8
nameserver 8.8.4.4
```

### Сеть: `/etc/sysconfig/ifconfig.eth0`

В репо два шаблона:

- `configs/ifconfig.eth0` — static (типичный VirtualBox NAT: `10.0.2.15`)
- `configs/ifconfig.eth0.dhcp` — DHCP

Имя интерфейса может быть `eth0`, `enp0s3` и т.д. Уточни через `ip link` после первой загрузки (или по драйверу в ядре).

Нужны **lfs-bootscripts** и сетевой сервис SysV, иначе файл сам по себе не поднимет интерфейс.

### `/etc/inittab`

Конфиг SysVinit: default runlevel 3, getty на tty1–tty6, обработка Ctrl+Alt+Del.

### Локаль и профиль

- `/etc/locale.conf` — `LANG=en_US.UTF-8`
- `/etc/profile` — `PATH`, `umask`
- локали должны быть сгенерированы (`localedef`) на этапе glibc/главы 9

### Часовой пояс

```bash
ln -sfv /usr/share/zoneinfo/Europe/Zurich /etc/localtime
```

(или другой регион)

## Пароль root

```bash
passwd root
```

Без этого не войдёшь после boot.

## wget / curl

Для оценки нужно уметь качать исходники. Убедись, что есть `wget` или `curl` (и openssl/сертификаты при необходимости).

## Bootscripts

Пакет `lfs-bootscripts` создаёт `/etc/rc.d/...`. Настрой:

- сеть
- udev
- sysklogd
- mounting

По книге LFS глава 9 — обязательное чтение.

## Итог главы

Система сконфигурирована. Осталось своё ядро и GRUB.

Далее: [09. Ядро и загрузчик](09-kernel-and-boot.md)
