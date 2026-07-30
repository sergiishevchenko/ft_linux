# 05. Временные инструменты

Соответствует: **LFS Chapters 6–7 — Cross Temporary Tools / Temporary Tools**  
Скрипт: `scripts/03-toolchain-temp.sh`  
Пользователь: **lfs**

## Зачем эта фаза

У тебя уже есть кросс-компилятор, но для работы внутри chroot нужны базовые программы:

- shell (`bash`)
- `make`, `sed`, `grep`, `tar`, …
- второй проход Binutils/GCC уже «ближе к финальной системе»

Эти пакеты ставятся в `$LFS/usr` через `DESTDIR=$LFS`, но **собираются кросс-компилятором** (`--host=$LFS_TGT`).

## Пакеты (типичный набор)

```text
M4, Ncurses, Bash, Coreutils, Diffutils, File, Findutils,
Gawk, Grep, Gzip, Make, Patch, Sed, Tar, Xz,
Binutils (pass 2), GCC (pass 2)
```

После Bash:

```text
$LFS/bin/sh → bash
```

После GCC pass 2:

```text
$LFS/usr/bin/cc → gcc
```

## Как запускать

```bash
su - lfs
bash scripts/03-toolchain-temp.sh
```

Время: ещё **4–8 часов**.

## Паттерн сборки одного пакета

Почти все пакеты здесь выглядят так:

```bash
tar -xf package-*.tar.xz
cd package-*/
./configure --prefix=/usr --host=$LFS_TGT --build=$(config.guess)
make -j$(nproc)
make DESTDIR=$LFS install
cd .. && rm -rf package-*/
```

`--host` говорит: «бинарник будет работать на целевой системе».  
`DESTDIR` говорит: «положи файлы под `$LFS`, не в корень хоста».

## Особые случаи

### Ncurses

Сначала собирается вспомогательный `tic` на хосте, потом основная библиотека для цели. Нужна wide-char версия (`--enable-widec`).

### Coreutils

Отдельно обрабатывается `chroot` (перенос в `sbin` и man8).

### GCC pass 2

Это уже более полный компилятор, установленный в `$LFS/usr`. После него можно переходить к chroot.

## Проверка

```bash
ls $LFS/usr/bin/bash
ls $LFS/usr/bin/make
ls $LFS/usr/bin/gcc
$LFS/usr/bin/bash --version
```

## Типичные ошибки

| Проблема | Решение |
|----------|---------|
| `configure` не находит кросс-gcc | `$LFS/tools/bin` должен быть первым в PATH |
| Ncurses падает | Проверь, что `tic` собрался во вложенном `build/` |
| Случайно ставишь без `DESTDIR` | Файлы улетят на хост — плохо; чини и повторяй |

## Итог главы

Временный userspace готов. Дальше — root ownership и `chroot`.

Далее: [06. Chroot](06-chroot.md)
