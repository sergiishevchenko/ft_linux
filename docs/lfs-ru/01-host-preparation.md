# 01. Подготовка хоста

Соответствует: **LFS Chapter 2 — Preparing the Host System**  
Скрипт: `scripts/00-check-host.sh`

## Зачем нужен хост

Хост — это Linux, **на котором** ты собираешь LFS. Сам ft_linux ещё не существует. Хост даёт:

- компилятор, make, tar, wget
- доступ к диску будущей системы
- сеть для скачивания исходников

Для 42 нужен гипервизор: VirtualBox или VMware.

## Рекомендуемые параметры VM

| Ресурс | Минимум | Лучше |
|--------|---------|-------|
| RAM | 4 GB | 8 GB |
| Диск | 30 GB | 40–50 GB |
| CPU | 2 ядра | все доступные ядра |
| Сеть | NAT | NAT + (опционально) Host-only |

Больше ядер = быстрее компиляция GCC/Glibc/ядра.

## Какой Linux ставить на хост

Подойдёт:

- Debian minimal / Ubuntu Server
- LFS Live CD (если используешь)

Не обязательно «чистый» LFS Live — достаточно обычного Linux с полным набором инструментов разработчика.

### Пакеты для Debian/Ubuntu (пример)

```bash
sudo apt update
sudo apt install -y build-essential bison gawk texinfo \
  python3 wget curl xz-utils
```

Точный список зависит от дистрибутива. Проверка важнее установки «на глаз».

## Что проверяет LFS

Глава 2.2 LFS требует наличие:

- Bash, Binutils (`ld`), Bison, Coreutils
- Diffutils, Findutils, Gawk, GCC, G++
- Grep, Gzip, M4, Make, Patch
- Perl, Python3, Sed, Tar, Texinfo (`makeinfo`), Xz

Также желательны symlink’и:

- `/usr/bin/yacc` → bison
- `/usr/bin/awk` → gawk

И библиотеки для сборки GCC: **gmp, mpfr, mpc**.

## Как проверить в этом проекте

```bash
bash scripts/00-check-host.sh
```

Скрипт печатает OK / FAIL / WARN. Пока есть FAIL — дальше идти нельзя.

## Типичные ошибки

| Симптом | Причина | Решение |
|---------|---------|---------|
| `g++: not found` | Нет C++ компилятора | `apt install g++` |
| `makeinfo: not found` | Нет texinfo | `apt install texinfo` |
| `yacc` отсутствует | Нет symlink | `ln -sv bison /usr/bin/yacc` |
| Мало места на диске | Маленький VDI | Расширь диск VM |

## Итог главы

Хост готов, если:

1. VM создана и Linux установлен  
2. `00-check-host.sh` проходит без FAIL  
3. Есть интернет (`ping 8.8.8.8`)

Далее: [02. Диск и исходники](02-disk-and-sources.md)
