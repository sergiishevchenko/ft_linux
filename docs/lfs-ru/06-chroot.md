# 06. Chroot

Соответствует: **LFS Chapter 7 — Entering the Chroot Environment**  
Скрипт: `scripts/04-chroot-setup.sh`  
Пользователь: **root**

## Что такое chroot

`chroot` меняет корневой каталог процесса. После:

```bash
chroot $LFS /bin/bash
```

путь `/` внутри сессии — это бывший `$LFS`. Хост «снаружи», а ты работаешь так, будто уже внутри новой ОС.

С этого момента:

- пакеты ставятся в `/usr`, `/etc`, … (реально — в дерево будущей системы)
- нельзя полагаться на программы хоста (кроме смонтированных виртуальных FS)

## Что делает `04-chroot-setup.sh`

```bash
sudo bash scripts/04-chroot-setup.sh
```

1. **Ownership → root** (после сборки от `lfs`)
2. **FHS-дерево**: `/bin`, `/etc`, `/usr`, `/var`, …
3. **Виртуальные FS**:
   - `/dev` (bind)
   - `/dev/pts`
   - `/proc`
   - `/sys`
   - `/run`
   - `/dev/shm`
4. **Базовые файлы**: `/etc/passwd`, `/etc/group`, логи в `/var/log`

Без `/proc` и `/sys` многие сборки и udev не работают.

## Как войти в chroot

```bash
chroot "$LFS" /usr/bin/env -i \
    HOME=/root \
    TERM="$TERM" \
    PS1='(lfs chroot) \u:\w\$ ' \
    PATH=/usr/bin:/usr/sbin \
    MAKEFLAGS="-j$(nproc)" \
    /bin/bash --login
```

Флаг `-i` у `env` очищает окружение хоста — это важно.

Приглашение должно показывать `(lfs chroot)`.

## Проверка внутри chroot

```bash
pwd          # /
ls /sources  # тарболы видны?
whoami       # root
cat /etc/passwd
mount | head
```

## Если вышел из chroot / перезагрузил хост

Нужно снова:

1. Смонтировать разделы (`$LFS`, `$LFS/boot`, swap)
2. Смонтировать virtual FS (или снова запустить `04-chroot-setup.sh` — аккуратно с уже существующими файлами)
3. Войти в chroot командой выше

## Типичные ошибки

| Проблема | Решение |
|----------|---------|
| `chroot: failed to run command /bin/bash` | Bash ещё не установлен в `$LFS` — не закончена глава 5 |
| Нет `/dev/null` | Не смонтирован `$LFS/dev` |
| `proc` пустой | `mount -vt proc proc $LFS/proc` |
| Скрипты репо не видны | Скопируй `scripts/` в `$LFS/root/` до входа |

## Итог главы

Ты внутри будущей системы. Пора собирать финальные пакеты.

Далее: [07. Базовая система](07-basic-system.md)
