---
title: "Пакетопригодность: нежелательные флаги компилятора"
date: 2021-11-23T19:26:33+03:00
draft: true
---

Иногда возникает желание добавить в сборку по умолчанию несколько
полезных флагов компиляции типа `-Werror` (чтобы гарантировано
исправлять предупреждения компилятора) и `-march=native` (чтобы
собирать более эффективные бинарники). На деле это сулит проблемы
при создании пакетов.

<!--more-->

## TL;DR

Не добавляйте во флаги компилятора по умолчанию `-Werror` и
`-march=native`.

## `-Werror`

Этот флаг запрещает компилятору успешно собирать код с предупреждениями,
а следовательно заставляет автора все эти предупреждения исправлять
что, по идее, улучшает качество кода. По этой причине флаг, безусловно,
имеет смысл включать для локальной сборки или continuous integration
вашего кода. Однако даже если в данный момент на вашей машине код
собирается без warning'во, нет никакой гарантии что warning'и не
появятся с новыми версиями компилятора, на других компиляторах,
системах и архитектурах. По этой причине код с `-Werror` имеет
высокую вероятность не собраться в новом окружении или просто
сломаться со временем.

Такого поведения, очевидно, следует избегать - такой код добавляет
работы мантейнерам пакетов (вдобавок к исправлению критичных проблем
при, например, подготовке к обновлению системного компилятора, им
приходится исправлять и необязательные warning'и), а в каких-то
случаях приводить к совершенно неожиданной поломке сборки у конечного
пользователя (после обновления компилятора, опять же). В любом
случае, проблема скорее всего будет решена удалением флага, а не
исправлением предупреждения, поэтому попытка посредством флага
заставить мантейнеров и пользователей присылать вам исправления
новых warning'ов - плохая идея.

Есть возможность включать фатальный характер предупреждений на
уровне отдельных их категорий (например, `-Werror=uninitialized`),
что может быть компромиссным решением. Однако, автору придётся
поддерживать список таких флагов при том что он скорее всего будет
неполон, а вдобавок будет меняться со временем и отличаться для
разных компиляторов.

В итоге, кажется что наилучшей атьтернативой `-Werror` по умолчанию
будет просто периодически просматривать логи сборки пакетов от
различных дистрибутивов (часть есть в [Repology](https://repology.org/)),
а также использовать как можно более разнообразный набор сборочных
окружений для CI.

Пример из коллекции портов FreeBSD, где вырезается `-Werror`:

```patch
--- mpy-cross/Makefile.orig	2021-09-01 14:07:13 UTC
+++ mpy-cross/Makefile
@@ -17,7 +17,7 @@ INC += -I$(BUILD)
 INC += -I$(TOP)
 
 # compiler settings
-CWARN = -Wall -Werror
+CWARN = -Wall
 CWARN += -Wextra -Wno-unused-parameter -Wpointer-arith
 CFLAGS = $(INC) $(CWARN) -std=gnu99 $(CFLAGS_MOD) $(COPT) $(CFLAGS_EXTRA)
 CFLAGS += -fdata-sections -ffunction-sections -fno-asynchronous-unwind-tables
```

## `-march=native`

Этот флаг включает оптимизацию производимого компилятором машинного
кода под текущий процессор. Более эффективный код это замечательно,
но когда речь идёт о пакетах, оказывается что собираются они на
совершенно ином железе (т.е. на мощных выделенных машинах для сборки
пакетов) чем то на котором они потом используются (т.е. у пользователей).
Оптимизация под другое железо может привести, к, наоборот, падению
производительности, а в худшем случае - к невозможности запустить
код на другом железе вовсе из-за использования не поддерживаемых
команд процессора. Обычно в этом случае приложения будут падать по
`SIGILL`.

Этот флаг особенно коварен, поскольку при создании пакета его легко
пропустить - он не сломает сборку у мантейнера, не сломает он и
сборку пакета на кластере, и даже собранный пакет может успешно
работать у мантейнера. Однако у какого-то пользователя с чуть более
старым железом приложение будет падать по не очевидной причине.

Пример из коллекции портов FreeBSD, где вырезается `-march=native`:

```make
post-patch:
	@${REINPLACE_CMD} -e 's/ -march=native//' \
		${WRKSRC}/cmake/FindAVX.cmake \
		${WRKSRC}/cmake/FindFMA.cmake \
		${WRKSRC}/cmake/FindSSE.cmake
```