# 10. Финал и сдача

Соответствует: финальные проверки LFS + требования peer-evaluation ft_linux  
Скрипты: `scripts/08-final-checks.sh`, сдача через `shasum`

## Первый вход

Войди как `root` (пароль, который задал в chroot).

Проверь базово:

```bash
uname -r
hostname
df -h
swapon --show
ip link
ping -c3 8.8.8.8
ping -c3 google.com
```

## Автопроверка требований 42

```bash
bash scripts/08-final-checks.sh <student_login>
```

Скрипт проверяет:

- ядро >= 4.0 и login в `uname -r`
- исходники в `/usr/src/kernel-*`
- имя `vmlinuz-*-<login>`
- отдельные `/boot` и swap
- hostname
- GRUB
- udevd
- сеть / DNS
- wget|curl
- наличие FHS-каталогов и ключевых команд

Любой **FAIL** нужно исправить до evaluation. **WARN** — желательно закрыть.

## Чеклист перед защитой

- [ ] `uname -r` содержит login  
- [ ] `/usr/src/kernel-<ver>` существует  
- [ ] `/boot/vmlinuz-<ver>-<login>` существует  
- [ ] `hostname` = login  
- [ ] 3 раздела работают  
- [ ] GRUB грузит систему стабильно  
- [ ] udev работает (`udevadm` / процесс udevd)  
- [ ] SysVinit (или systemd) запущен  
- [ ] Интернет есть  
- [ ] Можно скачать файл (`wget`/`curl`)  
- [ ] Обязательные пакеты на месте (`gcc`, `make`, `vim`, …)  

## Сдача проекта

В репозиторий **не** кладут весь `.vdi`. Нужен checksum:

```bash
shasum < disk.vdi
# или
shasum disk.vdi
```

Сохрани вывод в git (например файл `disk.sha` или в README).  
Сам образ диска держи у себя для peer-evaluation.

## Бонус (только если mandatory идеален)

По BLFS можно поставить:

- Xorg
- оконный менеджер (i3, dwm, LXDE, …)
- любой «свой» софт

Бонус не оценивают, если mandatory сломан.

## Что читать дальше

- Официальный LFS: https://www.linuxfromscratch.org/lfs/view/stable/
- BLFS (бонус): https://www.linuxfromscratch.org/blfs/view/stable/
- План проекта: [PLAN.md](../../PLAN.md)
- Техдок репозитория: [docs/](../README.md)

## Заключение

Ты прошёл путь LFS:

```text
хост → диск → toolchain → temp tools → chroot → пакеты → конфиг → ядро → GRUB → boot
```

Это и есть суть Linux From Scratch и проекта ft_linux.
