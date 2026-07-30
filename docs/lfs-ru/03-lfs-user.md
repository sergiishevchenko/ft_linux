# 03. Пользователь lfs

Соответствует: **LFS Chapter 4 — Final Preparations**  
Скрипт: `scripts/setup-lfs-user.sh`

## Зачем отдельный пользователь

Сборку toolchain (главы 5–6) **нельзя** делать под root без необходимости. Ошибка в `make install` от root может повредить **хост**.

Пользователь `lfs`:

- владеет `$LFS`
- имеет «чистое» окружение (минимум переменных)
- пишет только в `$LFS`, а не в системные каталоги хоста

## Что делает скрипт

```bash
sudo bash scripts/setup-lfs-user.sh
```

1. Создаёт группу и пользователя `lfs`
2. Делает `chown` на дерево `$LFS`
3. Пишет `/home/lfs/.bash_profile` и `.bashrc`

### Важные переменные в `.bashrc` пользователя lfs

```bash
set +h
umask 022
LFS=/mnt/lfs
LC_ALL=POSIX
LFS_TGT=$(uname -m)-lfs-linux-gnu
PATH=$LFS/tools/bin:/usr/bin
CONFIG_SITE=$LFS/usr/share/config.site
MAKEFLAGS=-j$(nproc)
```

Пояснения:

| Переменная | Смысл |
|------------|--------|
| `set +h` | Bash не кэширует пути к командам (важно при смене toolchain) |
| `LC_ALL=POSIX` | Предсказуемая локаль при сборке |
| `LFS_TGT` | Цель кросс-компиляции, напр. `x86_64-lfs-linux-gnu` |
| `PATH` с `$LFS/tools/bin` **впереди** | Сначала берутся свежие кросс-инструменты |

## Вход

```bash
su - lfs
echo $LFS
echo $LFS_TGT
echo $PATH
```

Проверь, что `$LFS` не пустой и `$LFS/sources` виден.

## Права

После создания пользователя:

- каталоги `$LFS` принадлежат `lfs`
- дальше (перед chroot) ownership вернётся root’у — это сделает `04-chroot-setup.sh`

## Типичные ошибки

| Проблема | Решение |
|----------|---------|
| `Permission denied` в `$LFS/sources` | `chown -R lfs:lfs $LFS` |
| В PATH нет `$LFS/tools/bin` | Перелогинься: `su - lfs` (с минусом!) |
| Собираешь под своим user’ом хоста | Нельзя — только `lfs` для глав 5–6 |

## Итог главы

Ты готов собирать кросс-тулчейн от имени `lfs`.

Далее: [04. Кросс-тулчейн](04-cross-toolchain.md)
