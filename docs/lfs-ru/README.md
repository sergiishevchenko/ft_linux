# Linux From Scratch — учебник на русском

Адаптированный русскоязычный учебник по методике **Linux From Scratch (LFS) 12.4 SysV** для проекта **ft_linux** (42).

> Оригинал: [Linux From Scratch](https://www.linuxfromscratch.org/lfs/view/stable/)  
> Лицензия оригинала: [CC BY-NC-SA 2.0](https://www.linuxfromscratch.org/lfs/view/stable/legalnotice.html)  
> Этот текст — учебная адаптация на русском с привязкой к скриптам репозитория `ft_linux`. Для точных флагов `./configure` при ошибках сверяйся с официальной книгой LFS.

## Для кого

- Студенты 42, выполняющие `ft_linux`
- Те, кто хочет понять LFS на русском, шаг за шагом

## Оглавление

| Глава | Тема |
|-------|------|
| [00. Введение](00-introduction.md) | Что такое LFS, цели ft_linux, как устроен учебник |
| [01. Подготовка хоста](01-host-preparation.md) | VM, требования к хост-системе, проверка инструментов |
| [02. Диск и исходники](02-disk-and-sources.md) | Разделы, `$LFS`, скачивание пакетов |
| [03. Пользователь lfs](03-lfs-user.md) | Изоляция сборки, окружение |
| [04. Кросс-тулчейн](04-cross-toolchain.md) | Binutils, GCC, Glibc (глава 5 LFS) |
| [05. Временные инструменты](05-temporary-tools.md) | Временный userspace (главы 6–7 LFS) |
| [06. Chroot](06-chroot.md) | Вход в будущее root-окружение |
| [07. Базовая система](07-basic-system.md) | Сборка пакетов (глава 8 LFS) |
| [08. Конфигурация системы](08-system-config.md) | Сеть, init, локаль, fstab (глава 9 LFS) |
| [09. Ядро и загрузчик](09-kernel-and-boot.md) | Kernel, GRUB, требования 42 |
| [10. Финал и сдача](10-final.md) | Проверки, reboot, shasum |

## Как пользоваться вместе с репозиторием

Каждая глава указывает:

1. **Теорию** — зачем нужен шаг  
2. **Что делает LFS** — логика книги  
3. **Скрипт в этом репо** — чем автоматизировать  
4. **Типичные ошибки**

Рекомендуемый порядок на VM:

```text
00 → 01 → 02 → 03 → 04 → 05 → 06 → 07 → 08 → 09 → 10
```

## Соответствие скриптам

| Глава учебника | Скрипт |
|----------------|--------|
| 01 | `scripts/00-check-host.sh` |
| 02 | `scripts/01-prepare-disk.sh`, `sources/download.sh` |
| 03 | `scripts/setup-lfs-user.sh` |
| 04 | `scripts/02-toolchain-cross.sh` |
| 05 | `scripts/03-toolchain-temp.sh` |
| 06 | `scripts/04-chroot-setup.sh` |
| 07 | `scripts/05-build-system.sh` |
| 08 | `scripts/apply-configs.sh`, `configs/` |
| 09 | `scripts/06-build-kernel.sh`, `07-configure-grub.sh` |
| 10 | `scripts/09-umount-and-reboot.sh`, `08-final-checks.sh` |
