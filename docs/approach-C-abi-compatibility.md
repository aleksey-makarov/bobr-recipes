# Подход C: Bootstrap без замены хостовой glibc

## Обзор

Всё собирается нативно хостовым тулчейном. Хостовая glibc **не заменяется**. Бинарники «поколения 1» зависят от хостовой glibc, но это не страшно — glibc обратно совместима на уровне ABI. Мы кладём их в `FROM scratch` образ вместе с **нашей** glibc, и они работают. Затем в чистом образе пересобираем всё — после пересборки зависимость от хоста полностью исчезает.

### Почему это работает

Glibc гарантирует обратную совместимость через symbol versioning. Бинарник, собранный с glibc 2.38, запрашивает символы `GLIBC_2.2.5`...`GLIBC_2.38`. Любая glibc ≥ 2.38 эти символы предоставляет. Поэтому бинарник, собранный хостовым gcc с хостовой glibc, будет работать с **нашей** glibc, если наша версия ≥ хостовой.

Если наша glibc **ниже** хостовой — бинарники «поколения 1» могут не запуститься в scratch-образе. В этом случае нужен хост с достаточно старой glibc (подробнее — в разделе «Ограничения»).

---

## Терминология

| Термин | Значение |
|--------|----------|
| **Артефакт** | Результат `make install DESTDIR=...` — срез файловой системы |
| **host-image** | Начальный образ с хостовым тулчейном. **Не модифицируется.** |
| **bootstrap-image** | `FROM scratch` + артефакты «поколения 1» |
| **build-image** | `FROM scratch` + финальный тулчейн + gen1-утилиты |
| **final-image** | `FROM scratch` + все финальные артефакты |

### Механизмы системы сборки

- **Артефакты src**: деревья исходников, монтируются в контейнер перед сборкой. Для одного пакета можно смонтировать несколько деревьев (например, gcc + gmp + mpfr + mpc).
- **Монтирование собранных артефактов**: ранее собранный артефакт можно подмонтировать в контейнер в предопределённое место (например, `/mnt/input/glibc-gen1/`). Файлы артефакта **не** появляются в стандартных путях (`/usr/lib/` и т.д.) — они доступны только по пути монтирования.
- **Образы**: собираются `FROM scratch` путём копирования артефактов. **Перекрытие файлов** между артефактами в одном образе **недопустимо**. Если нужно заменить пакет — образ пересобирается с нуля с новым набором артефактов.

---

## Общая схема

```
host-image (не модифицируется)
    │
    │  Фаза 1: нативная сборка хостовым тулчейном
    │  Минимальные конфигурации, нет зависимостей между артефактами gen1.
    │  Все пакеты можно собирать ПАРАЛЛЕЛЬНО.
    │
    ├── linux-headers        ─┐
    ├── glibc-gen1             │
    ├── binutils-gen1          │  артефакты «поколения 1»
    ├── gcc-gen1               │
    ├── bash-gen1              │  (все собраны хостовым тулчейном,
    ├── coreutils-gen1         │   все зависят от хостовой glibc,
    ├── make-gen1              │   все конфигурации минимальные)
    ├── ...                   ─┘
    │
    ▼
bootstrap-image = FROM scratch + base-filesystem + все gen1
    │
    │  Фаза 2a: пересборка тулчейна
    │  (glibc, binutils, gcc собираются в bootstrap-image)
    │
    ├── glibc-final
    ├── binutils-final
    ├── gcc-final
    │
    ▼
build-image = FROM scratch + base-filesystem
            + glibc-final + binutils-final + gcc-final
            + gen1-утилиты (bash, coreutils, make, ...)
    │
    │  Фаза 2b: сборка остальной системы
    │
    ├── все остальные финальные артефакты
    │
    ▼
final-image = FROM scratch + base-filesystem + все финальные артефакты
```

---

## Фаза 1: Нативная сборка в host-image

### Принципы

1. **host-image не модифицируется** — все пакеты собираются в одном и том же host-image.
2. **Нет зависимостей между артефактами gen1** — каждый пакет собирается хостовым тулчейном и зависит только от того, что уже есть в host-image.
3. **Минимальные конфигурации** — optional-зависимости отключаются, чтобы не требовать хостовых -devel пакетов и не создавать зависимости между gen1-артефактами. В фазе 2 всё будет пересобрано с полной функциональностью.
4. **Параллельная сборка** — раз нет взаимозависимостей, все ~35 артефактов можно собирать одновременно.

### Требования к host-image

Минимальный образ с компилятором и базовыми утилитами. По сути — то, что LFS требует от хост-системы в главе 2:

```
gcc, g++, make, binutils, glibc (с заголовками), linux-headers,
bash, coreutils, sed, grep, gawk, tar, gzip, bzip2, xz,
diffutils, findutils, patch, perl, python3, texinfo, bison, m4, flex
```

Для Fedora minimal:
```bash
dnf install gcc gcc-c++ make binutils glibc-devel kernel-headers \
    bash coreutils sed grep gawk tar gzip bzip2 xz \
    diffutils findutils patch perl python3 texinfo bison m4 flex
```

Хостовые -devel пакеты (ncurses-devel, readline-devel, zlib-devel и т.д.) **не нужны** — мы собираем всё в минимальных конфигурациях без optional-зависимостей.

Версия glibc в host-image должна быть **≤ версии, которую мы собираем** (≤ 2.42 для LFS 12.4).

### Пакеты фазы 1

#### Тулчейн

##### 1.1. linux-headers

**Зависимости:** host-image, src:linux-6.16.1
```bash
make mrproper
make headers
find usr/include -type f ! -name '*.h' -delete
mkdir -p $DESTDIR/usr
cp -rv usr/include $DESTDIR/usr/
```

**Артефакт:** `/usr/include/linux/`, `/usr/include/asm/`, и т.д. Только заголовочные файлы.

##### 1.2. glibc-gen1

**Зависимости:** host-image, src:glibc-2.42

Хостовой образ содержит хостовые kernel headers — их достаточно для сборки glibc.

```bash
mkdir build && cd build
echo "rootsbindir=/usr/sbin" > configparms

../configure \
    --prefix=/usr \
    --disable-werror \
    --enable-kernel=4.19 \
    --enable-stack-protector=strong \
    --disable-nscd \
    libc_cv_slibdir=/usr/lib

make
make install DESTDIR=$DESTDIR

# Симлинк для стандартного пути dynamic linker
mkdir -p $DESTDIR/lib64
ln -sfv ../usr/lib/ld-linux-x86-64.so.2 $DESTDIR/lib64/ld-linux-x86-64.so.2
```

**Артефакт:** `/usr/lib/libc.so.6`, `/usr/lib/ld-linux-x86-64.so.2`, `/usr/include/*.h`, и т.д.

##### 1.3. binutils-gen1

**Зависимости:** host-image, src:binutils-2.45
```bash
mkdir build && cd build

../configure \
    --prefix=/usr \
    --enable-shared \
    --enable-64-bit-bfd \
    --enable-new-dtags \
    --enable-default-hash-style=gnu \
    --disable-nls \
    --disable-werror \
    --disable-gprofng

make
make install DESTDIR=$DESTDIR
```

##### 1.4. gcc-gen1

**Зависимости:** host-image, src:gcc-15.2.0, src:gmp, src:mpfr, src:mpc

Четыре дерева исходников монтируются в контейнер. Build script копирует gmp/mpfr/mpc внутрь дерева gcc (in-tree build).

```bash
# Копировать зависимости в дерево gcc
cp -r $SRC_GMP  gcc-15.2.0/gmp
cp -r $SRC_MPFR gcc-15.2.0/mpfr
cp -r $SRC_MPC  gcc-15.2.0/mpc

case $(uname -m) in
  x86_64) sed -e '/m64=/s/lib64/lib/' -i.orig gcc-15.2.0/gcc/config/i386/t-linux64 ;;
esac

mkdir build && cd build

../gcc-15.2.0/configure \
    --prefix=/usr \
    --enable-languages=c,c++ \
    --enable-default-pie \
    --enable-default-ssp \
    --disable-multilib \
    --disable-nls \
    --with-system-zlib

make
make install DESTDIR=$DESTDIR
ln -sv gcc $DESTDIR/usr/bin/cc
```

**Артефакт:** `/usr/bin/gcc`, `/usr/bin/g++`, `/usr/bin/cc`, `/usr/lib/libgcc_s.so*`, `/usr/lib/libstdc++.so*`, и т.д.

#### Утилиты

Все собираются в **host-image** хостовым тулчейном. Минимальные конфигурации — optional-зависимости отключены.

Общий шаблон:
```bash
./configure --prefix=/usr [пакето-специфичные опции]
make
make install DESTDIR=$DESTDIR
```

| # | Пакет | Минимальная конфигурация |
|---|-------|------------------------|
| 1.5 | M4-1.4.20 | — |
| 1.6 | Ncurses-6.5 | `--with-shared --enable-widec --without-debug --without-normal --without-ada --without-cxx-binding --without-manpages` |
| 1.7 | Bash-5.3 | `--without-bash-malloc --disable-readline` (без readline/ncurses — нет редактирования строки, но shell полностью рабочий для скриптов) |
| 1.8 | Coreutils-9.7 | `--enable-install-program=hostname --enable-no-install-program=kill,uptime` |
| 1.9 | Diffutils-3.12 | — |
| 1.10 | File-5.46 | (собирается без явных optional-зависимостей) |
| 1.11 | Findutils-4.10.0 | — |
| 1.12 | Gawk-5.3.2 | `--without-readline --without-mpfr` |
| 1.13 | Grep-3.12 | — |
| 1.14 | Gzip-1.14 | — |
| 1.15 | Make-4.4.1 | `--without-guile` |
| 1.16 | Patch-2.8 | — |
| 1.17 | Sed-4.9 | — |
| 1.18 | Tar-1.35 | — |
| 1.19 | Xz-5.8.1 | — |
| 1.20 | Bzip2-1.0.8 | — |
| 1.21 | Zlib-1.3.1 | — |
| 1.22 | Zstd-1.5.7 | — |
| 1.23 | Gettext-0.26 | Минимальная сборка: только `msgfmt`, `msgmerge`, `xgettext` из `gettext-tools` |
| 1.24 | Bison-3.8.2 | — |
| 1.25 | Perl-5.42.0 | Минимальная сборка (`-des -Dprefix=/usr`), без optional-модулей |
| 1.26 | Python-3.13.7 | `--without-ensurepip --disable-test-modules` |
| 1.27 | Texinfo-7.2 | — |
| 1.28 | Util-linux-2.41.1 | Только библиотеки: `--disable-all-programs --enable-libuuid --enable-libblkid --enable-libmount --enable-libsmartcols --enable-libfdisk` |
| 1.29 | Flex-2.6.4 | — |
| 1.30 | Bc-7.0.3 | — |
| 1.31 | Pkgconf-2.5.1 | — |
| 1.32 | Expat-2.7.1 | — |
| 1.33 | Libffi-3.5.2 | — |
| 1.34 | Readline-8.3 | `--with-curses=no` (без ncurses; минимальная, но достаточная для gen1) |

### Артефакт base-filesystem

Отдельный артефакт без компиляции:

```bash
mkdir -pv $DESTDIR/{etc,var,tmp,run,root,home}
mkdir -pv $DESTDIR/usr/{bin,lib,sbin,share,include,libexec}
mkdir -pv $DESTDIR/var/{log,mail,spool,tmp}

ln -sv usr/bin  $DESTDIR/bin
ln -sv usr/sbin $DESTDIR/sbin
ln -sv usr/lib  $DESTDIR/lib
case $(uname -m) in
  x86_64) ln -sv usr/lib $DESTDIR/lib64 ;;
esac

cat > $DESTDIR/etc/passwd << "EOF"
root:x:0:0:root:/root:/bin/bash
nobody:x:65534:65534:nobody:/nonexistent:/usr/bin/false
EOF

cat > $DESTDIR/etc/group << "EOF"
root:x:0:
bin:x:1:
sys:x:2:
kmem:x:9:
wheel:x:10:
nobody:x:65534:
EOF

cat > $DESTDIR/etc/ld.so.conf << "EOF"
/usr/lib
EOF

ln -sv /proc/self/mounts $DESTDIR/etc/mtab
```

### Создание bootstrap-image

```dockerfile
FROM scratch
COPY base-filesystem /
COPY linux-headers /
COPY glibc-gen1 /
COPY binutils-gen1 /
COPY gcc-gen1 /
COPY m4-gen1 /
COPY ncurses-gen1 /
COPY bash-gen1 /
COPY coreutils-gen1 /
COPY diffutils-gen1 /
COPY file-gen1 /
COPY findutils-gen1 /
COPY gawk-gen1 /
COPY grep-gen1 /
COPY gzip-gen1 /
COPY make-gen1 /
COPY patch-gen1 /
COPY sed-gen1 /
COPY tar-gen1 /
COPY xz-gen1 /
COPY bzip2-gen1 /
COPY zlib-gen1 /
COPY zstd-gen1 /
COPY gettext-gen1 /
COPY bison-gen1 /
COPY perl-gen1 /
COPY python-gen1 /
COPY texinfo-gen1 /
COPY util-linux-gen1 /
COPY flex-gen1 /
COPY bc-gen1 /
COPY pkgconf-gen1 /
COPY expat-gen1 /
COPY libffi-gen1 /
COPY readline-gen1 /
ENV PATH=/usr/bin:/usr/sbin
SHELL ["/bin/bash", "-c"]
```

### Что происходит в bootstrap-image

Бинарники gen1 собраны хостовым gcc и слинкованы с хостовой glibc. В их `PT_INTERP` записано `/lib64/ld-linux-x86-64.so.2`. В scratch-образе по этому пути лежит `ld-linux` из **glibc-gen1**. Glibc-gen1 — версия 2.42, что ≥ хостовой, поэтому все символы присутствуют.

**Потенциальная проблема:** Если хостовой gcc слинковал бинарник с библиотекой, которой нет в bootstrap-image (например, хостовой `libselinux`). На практике маловероятно при минимальном host-image, но стоит проверить:
```bash
for bin in /usr/bin/gcc /usr/bin/bash /usr/bin/make; do
    echo "=== $bin ==="
    ldd $bin | grep "not found"
done
```

---

## Фаза 2a: Пересборка тулчейна

### Среда сборки

Три пакета (glibc, binutils, gcc) собираются в **bootstrap-image** компилятором gcc-gen1.

### 2a.1. glibc-final

**Зависимости:** bootstrap-image, src:glibc-2.42
```bash
mkdir build && cd build
echo "rootsbindir=/usr/sbin" > configparms

../configure \
    --prefix=/usr \
    --disable-werror \
    --enable-kernel=4.19 \
    --enable-stack-protector=strong \
    --disable-nscd \
    libc_cv_slibdir=/usr/lib

make
make install DESTDIR=$DESTDIR

mkdir -p $DESTDIR/lib64
ln -sfv ../usr/lib/ld-linux-x86-64.so.2 $DESTDIR/lib64/ld-linux-x86-64.so.2
```

Плюс конфигурация: `nsswitch.conf`, locales, timezone data — как часть этого артефакта или отдельный артефакт `glibc-config`.

### 2a.2. binutils-final

**Зависимости:** bootstrap-image, src:binutils-2.45
```bash
mkdir build && cd build

../configure \
    --prefix=/usr \
    --enable-shared \
    --enable-64-bit-bfd \
    --enable-new-dtags \
    --enable-default-hash-style=gnu \
    --disable-nls \
    --disable-werror \
    --disable-gprofng

make
make install DESTDIR=$DESTDIR
```

### 2a.3. gcc-final

**Зависимости:** bootstrap-image, src:gcc-15.2.0, src:gmp, src:mpfr, src:mpc
```bash
cp -r $SRC_GMP  gcc-15.2.0/gmp
cp -r $SRC_MPFR gcc-15.2.0/mpfr
cp -r $SRC_MPC  gcc-15.2.0/mpc

case $(uname -m) in
  x86_64) sed -e '/m64=/s/lib64/lib/' -i.orig gcc-15.2.0/gcc/config/i386/t-linux64 ;;
esac

mkdir build && cd build

../gcc-15.2.0/configure \
    --prefix=/usr \
    --enable-languages=c,c++ \
    --enable-default-pie \
    --enable-default-ssp \
    --disable-multilib \
    --with-system-zlib

make
make install DESTDIR=$DESTDIR
ln -sv gcc $DESTDIR/usr/bin/cc
```

Это **полная** сборка gcc: все runtime-библиотеки (libstdc++, libgomp, libatomic, и т.д.).

### Создание build-image

Единственная пересборка образа во всём процессе. Образ собирается **с нуля**:

```dockerfile
FROM scratch
COPY base-filesystem /

# Финальный тулчейн
COPY linux-headers /
COPY glibc-final /
COPY binutils-final /
COPY gcc-final /

# Gen1-утилиты (ещё не пересобраны, но функционально достаточны)
COPY m4-gen1 /
COPY ncurses-gen1 /
COPY bash-gen1 /
COPY coreutils-gen1 /
COPY diffutils-gen1 /
COPY file-gen1 /
COPY findutils-gen1 /
COPY gawk-gen1 /
COPY grep-gen1 /
COPY gzip-gen1 /
COPY make-gen1 /
COPY patch-gen1 /
COPY sed-gen1 /
COPY tar-gen1 /
COPY xz-gen1 /
COPY bzip2-gen1 /
COPY zlib-gen1 /
COPY zstd-gen1 /
COPY gettext-gen1 /
COPY bison-gen1 /
COPY perl-gen1 /
COPY python-gen1 /
COPY texinfo-gen1 /
COPY util-linux-gen1 /
COPY flex-gen1 /
COPY bc-gen1 /
COPY pkgconf-gen1 /
COPY expat-gen1 /
COPY libffi-gen1 /
COPY readline-gen1 /
ENV PATH=/usr/bin:/usr/sbin
SHELL ["/bin/bash", "-c"]
```

**Что в build-image:** Финальный тулчейн (glibc-final + binutils-final + gcc-final) + gen1-утилиты. Перекрытия нет: gen1-тулчейн не копируется, вместо него — финальные версии. Gen1-утилиты продолжают работать, потому что glibc-final (2.42) ABI-совместима с glibc-gen1 (тоже 2.42, тот же soname).

Все последующие пакеты будут собраны финальным gcc и слинкованы с финальной glibc.

---

## Фаза 2b: Сборка остальной системы

### Среда сборки

Все пакеты собираются в **build-image**. Компилятор — gcc-final. Линкер — binutils-final. Libc — glibc-final. Утилиты (bash, make, sed, ...) — gen1, но это не влияет на результат: они лишь выполняют сборочные команды, а собираемые бинарники линкуются финальным тулчейном.

Пересборка build-image **не требуется** на протяжении всей фазы 2b.

### Общий шаблон

```bash
./configure --prefix=/usr [опции]
make
make install DESTDIR=$DESTDIR
```

### Зависимости между пакетами фазы 2b

Некоторые пакеты зависят друг от друга: bash нужна ncurses + readline, python нужна libffi + expat, systemd нужна jinja2 + kmod + libcap + ... Эти зависимости удовлетворяются gen1-артефактами, которые уже установлены в build-image в стандартных путях (`/usr/lib/`, `/usr/include/`). Configure находит их автоматически.

Финальные пакеты слинкуются с gen1-библиотеками из build-image при сборке, но в final-image финальные версии тех же библиотек займут те же пути. Поскольку gen1 и final — одинаковые версии пакетов с одинаковым soname, бинарники работают корректно.

### Пакеты

Порядок следует LFS глава 8.

#### Данные (без компиляции)

| # | Пакет | Содержимое |
|---|-------|-----------|
| 1 | Man-pages-6.15 | `/usr/share/man/` |
| 2 | Iana-Etc-20250807 | `/etc/services`, `/etc/protocols` |

#### Библиотеки сжатия

| # | Пакет |
|---|-------|
| 3 | Zlib-1.3.1 |
| 4 | Bzip2-1.0.8 |
| 5 | Xz-5.8.1 |
| 6 | Lz4-1.10.0 |
| 7 | Zstd-1.5.7 |

#### Утилиты и библиотеки

| # | Пакет |
|---|-------|
| 8 | File-5.46 |
| 9 | Readline-8.3 |
| 10 | M4-1.4.20 |
| 11 | Bc-7.0.3 |
| 12 | Flex-2.6.4 |

#### Тестовая инфраструктура (опциональна)

| # | Пакет |
|---|-------|
| 13 | Tcl-8.6.16 |
| 14 | Expect-5.45.4 |
| 15 | DejaGNU-1.6.3 |

#### Тулчейн-зависимости и системные библиотеки

| # | Пакет |
|---|-------|
| 16 | Pkgconf-2.5.1 |
| 17 | GMP-6.3.0 |
| 18 | MPFR-4.2.2 |
| 19 | MPC-1.3.1 |
| 20 | Attr-2.5.2 |
| 21 | Acl-2.3.2 |
| 22 | Libcap-2.76 |
| 23 | Libxcrypt-4.4.38 |
| 24 | Shadow-4.18.0 |

**Примечание:** Binutils-final и GCC-final уже собраны в фазе 2a.

#### Все остальные пакеты

| # | Пакет | # | Пакет |
|---|-------|---|-------|
| 25 | Ncurses-6.5 | 51 | Ninja-1.13.1 |
| 26 | Sed-4.9 | 52 | Meson-1.8.3 |
| 27 | Psmisc-23.7 | 53 | Kmod-34.2 |
| 28 | Gettext-0.26 | 54 | Coreutils-9.7 |
| 29 | Bison-3.8.2 | 55 | Diffutils-3.12 |
| 30 | Grep-3.12 | 56 | Gawk-5.3.2 |
| 31 | Bash-5.3 | 57 | Findutils-4.10.0 |
| 32 | Libtool-2.5.4 | 58 | Groff-1.23.0 |
| 33 | GDBM-1.26 | 59 | GRUB-2.12 |
| 34 | Gperf-3.3 | 60 | Gzip-1.14 |
| 35 | Expat-2.7.1 | 61 | IPRoute2-6.16.0 |
| 36 | Inetutils-2.6 | 62 | Kbd-2.8.0 |
| 37 | Less-679 | 63 | Libpipeline-1.5.8 |
| 38 | Perl-5.42.0 | 64 | Make-4.4.1 |
| 39 | XML::Parser-2.47 | 65 | Patch-2.8 |
| 40 | Intltool-0.51.0 | 66 | Tar-1.35 |
| 41 | Autoconf-2.72 | 67 | Texinfo-7.2 |
| 42 | Automake-1.18.1 | 68 | Vim-9.1 |
| 43 | OpenSSL-3.5.2 | 69 | MarkupSafe-3.0.2 |
| 44 | Libelf-0.193 | 70 | Jinja2-3.1.6 |
| 45 | Libffi-3.5.2 | 71 | Systemd-257.8 |
| 46 | Python-3.13.7 | 72 | D-Bus-1.16.2 |
| 47 | Flit-Core-3.12.0 | 73 | Man-DB-2.13.1 |
| 48 | Packaging-25.0 | 74 | Procps-ng-4.0.5 |
| 49 | Wheel-0.46.1 | 75 | Util-linux-2.41.1 |
| 50 | Setuptools-80.9.0 | 76 | E2fsprogs-1.47.3 |

Все собираются с `--prefix=/usr` нативно.

#### Ядро

##### Linux-6.16.1

**Зависимости:** build-image, src:linux-6.16.1, src:kernel-config
```bash
make mrproper
cp $SRC_KERNEL_CONFIG .config
make
make modules_install DESTDIR=$DESTDIR
cp arch/x86/boot/bzImage $DESTDIR/boot/vmlinuz-6.16.1-lfs
cp System.map $DESTDIR/boot/System.map-6.16.1
```

---

## Создание final-image

```dockerfile
FROM scratch
COPY base-filesystem /
COPY linux-headers /
COPY man-pages-final /
COPY iana-etc-final /
COPY glibc-final /
COPY binutils-final /
COPY gcc-final /
COPY zlib-final /
COPY bzip2-final /
COPY xz-final /
COPY lz4-final /
COPY zstd-final /
# ... все остальные финальные артефакты ...
COPY e2fsprogs-final /
COPY linux-kernel /
```

---

## Ограничения

### Версия glibc хоста

Host-image должен содержать glibc **≤ 2.42** (версия, которую мы собираем).

| Образ | glibc | Подходит? |
|-------|-------|-----------|
| Debian 12 (Bookworm) | 2.36 | Да |
| Ubuntu 24.04 | 2.39 | Да |
| Fedora 40 | 2.39 | Да |
| Fedora 41 | 2.40 | Да |
| Arch Linux (rolling) | может быть > 2.42 | Проверить! |

### Неожиданные .so зависимости

Если хостовой gcc слинковал бинарник gen1 с библиотекой, которой нет в bootstrap-image (например, `libselinux`), бинарник не запустится. Решение: использовать минимальный host-image.

---

## Граф зависимостей

```
host-image (не модифицируется)
    │
    │  Все пакеты gen1 собираются параллельно
    │
    ├──► linux-headers ──┐
    ├──► glibc-gen1 ─────┤
    ├──► binutils-gen1 ──┤
    ├──► gcc-gen1 ───────┤
    ├──► bash-gen1 ──────┤  все gen1 артефакты
    ├──► make-gen1 ──────┤
    ├──► ... ────────────┤
    │                    │
    │  bootstrap-image = FROM scratch + все gen1
    │       │
    │       ├──► glibc-final ───┐
    │       ├──► binutils-final ┤  фаза 2a
    │       ├──► gcc-final ─────┘
    │       │
    │  build-image = FROM scratch
    │              + glibc-final + binutils-final + gcc-final
    │              + gen1-утилиты
    │       │
    │       ├──► zlib-final, ncurses-final, bash-final, ...
    │       ├──► python-final, systemd, ...  фаза 2b
    │       ├──► linux-kernel
    │       │
    │  final-image = FROM scratch + все финальные артефакты
```

---

## Итого: образы и артефакты

| Тип | Количество |
|-----|-----------|
| **Образы** | **4** (host, bootstrap, build, final) |
| Артефакты фаза 1 (gen1) | ~36 |
| Артефакты фаза 2a (тулчейн) | 3 |
| Артефакты фаза 2b (система) | ~77 |
| Служебные (base-filesystem) | 1 |
| **Итого артефактов** | **~117** |
| **Пересборок образа** | **1** (bootstrap → build) |
