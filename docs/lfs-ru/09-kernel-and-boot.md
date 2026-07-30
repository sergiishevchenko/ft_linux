# 09. Ядро и загрузчик

Соответствует: **LFS Chapter 10 — Making the LFS System Bootable**  
Скрипты: `scripts/06-build-kernel.sh`, `scripts/07-configure-grub.sh`  
Среда: **chroot**

## Требования ft_linux к ядру

| Требование | Как выполнить |
|------------|---------------|
| Версия >= 4.0 | Используй linux из `wget-list` (например 6.16.1) |
| Login в версии | `LOCALVERSION=-<login>` в menuconfig |
| Путь исходников | `/usr/src/kernel-<version>` |
| Имя бинарника | `/boot/vmlinuz-<version>-<login>` |

После загрузки:

```bash
uname -r
# ожидание: 6.16.1-jdoe
```

## Сборка ядра

```bash
bash scripts/06-build-kernel.sh <student_login>
```

Скрипт:

1. Находит `linux-*.tar.xz` в `/sources`
2. Распаковывает в `/usr/src/kernel-<version>`
3. Делает `make mrproper`
4. Запускает `make menuconfig` (**интерактивно**)
5. Собирает и ставит модули
6. Копирует `bzImage` → `/boot/vmlinuz-...`

### Что включить в menuconfig

Обязательный минимум для VM:

1. **General setup → Local version** = `-<твой_login>`
2. **Enable loadable module support**
3. **Maintain a devtmpfs filesystem** (для udev)
4. **File systems**: ext4, ext2/3 по необходимости, proc, sysfs, tmpfs
5. **Networking**: TCP/IP
6. **NIC драйвер**:
   - VirtualBox часто: **Intel PRO/1000 (e1000)**
   - VMware: vmxnet / e1000
   - VirtIO, если используешь KVM/QEMU

Без правильного NIC после boot не будет сети — на защите это провал.

### Артефакты

```text
/boot/vmlinuz-<ver>-<login>
/boot/System.map-<ver>-<login>
/boot/config-<ver>-<login>
/usr/src/kernel-<ver>/
```

## GRUB

```bash
bash scripts/07-configure-grub.sh <student_login> /dev/sda /dev/sda2
```

1. `grub-install /dev/sda` — пишет в MBR  
2. Генерирует `/boot/grub/grub.cfg`

Пример меню:

```text
menuentry "ft_linux 6.16.1-jdoe" {
    set root=(hd0,2)
    linux /boot/vmlinuz-6.16.1-jdoe root=/dev/sda2 ro
}
```

### Нумерация GRUB

| GRUB | Linux |
|------|-------|
| `(hd0,1)` | `/dev/sda1` |
| `(hd0,2)` | `/dev/sda2` |

Если root не на втором разделе — поправь `set root=` и `root=` в cfg.

## Перед reboot

1. Выйди из chroot (`exit`)
2. На хосте размонтируй всё:

```bash
bash scripts/09-umount-and-reboot.sh
```

3. Перезагрузи VM, в Boot Order выбери жёсткий диск с ft_linux

## Если не грузится

| Симптом | Частая причина |
|---------|----------------|
| GRUB rescue | Неверный `root=(hd0,N)` или нет `grub.cfg` |
| Kernel panic: VFS | Неверный `root=/dev/sdXN` или нет драйвера диска/ext4 |
| Зависает без сети | Нет драйвера NIC / не настроен ifconfig |
| `uname -r` без login | Забыли LOCALVERSION |

Вернись в хост, смонтируй `$LFS`, зайди в chroot, исправь, снова umount/reboot.

## Итог главы

Система должна загружаться в login prompt твоего ft_linux.

Далее: [10. Финал и сдача](10-final.md)
