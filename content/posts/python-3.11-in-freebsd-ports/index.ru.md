---
title: "Python 3.11 в портах FreeBSD"
date: 2021-12-06T15:40:49+03:00
---

Месяц назад я [добавил](https://cgit.freebsd.org/ports/commit/?id=d6f568cf8a0c57c1280efb31b1b2ab850a87267f)
в порты FreeBSD Python 3.11 (alpha2). Это продолжение моей работы
над поддержкой (пререлиза) Python 3.10, и, как и с предыдущей
версией, целью является дать возможность заинтересованным поиграть
с новой версией языка, мантейнерам проверить совместимость своих
портов, а разработчикам - своего кода. Хочу рассказать про статус
поддержки и про то как был портирован Python 3.10.

<!-- more -->

## Статус Python 3.10

Поддержка [Python 3.10](https://docs.python.org/3/whatsnew/3.10.html)
пока далека от полноценной, так как эту версию языка пока не
поддерживают многие критичные пакеты (в основном по причине устаревших
версий в портах, но есть и случаи отсутствия поддержки в upstream).
Самый критичный - [math/py-numpy](https://www.freshports.org/math/py-numpy/)
([обновление](https://bugs.freebsd.org/bugzilla/show_bug.cgi?id=259637)
висит с 4 ноября). От него зависит большое количество других портов,
и все они, соответственно, пока не доступны под Python 3.10.

Ещё несколько важных зависимостей:
- [devel/py-pytest](https://www.freshports.org/devel/py-pytest/) (нужен для запуска `make test` других питоновских портов) - [обновление](https://bugs.freebsd.org/bugzilla/show_bug.cgi?id=256624) висит с июня.
- [math/py-gmpy2](https://www.freshports.org/math/py-gmpy2/)
- [devel/shiboken2](https://www.freshports.org/devel/shiboken2/)
- [devel/py-qt5-qscintilla2](https://www.freshports.org/devel/py-qt5-qscintilla2/)

Помимо зависимостей, наберётся несколько десятков обычных портов
пока не работающих с Python 3.10.

Это, однако, не значит что языком нельзя пользоваться. Так, всё что
нужно для разработки моих Python проектов включая
[Repology](https://github.com/repology/) работает и production уже
переведён на 3.10:

```make
DEFAULT_VERSIONS+=python=3.10 python3=3.10
```


## Статус Python 3.11

Все перечисленные проблемы с 3.10 справедливы и для 3.11 (хорошая
новость в том что исправятся они скорее всего сразу везде), ну и
вполне ожидаемо какое-то количество новых поломок. Пока язык в alpha
статусе, целенаправленно исправлять их не имеет смысла, поскольку
какие-то API могут ещё раз поменяться и всё снова сломается, однако
просмотреть список новых относительно 4.10 проблем имеет смысл, там
могут быть и ситуации не связанные с конкретной версией.

Хотя от альфы нет смысла чего-то вообще ждать, после нескольких
исправлений весь мой набор модулей также успешно заработал. Осталось
[обновить](https://bugs.freebsd.org/bugzilla/show_bug.cgi?id=260028)
единственный порт [www/uwsgi](https://www.freshports.org/www/uwsgi) -
это можно будет закоммитить по таймауту на этой неделе.


## Дальнейшая работа

### Продолжить исправление сломанных портов

Продолжаем запускать poudriere с `DEFAULT_VERSIONS=python3.10
python3=3.10`, смотреть ошибки и исправлять их. Исправления в
большинстве своём тривиальные (поэтому мы можете присоединиться к
процессу), вот например:

- Нужно заставить порт перегенерировать файлы cython (примеры: [asyncpg](https://cgit.freebsd.org/ports/commit/?id=a97113cd3943a879380fbbcf5dfddcd6004bdccb), [aiohttp](https://cgit.freebsd.org/ports/commit/?id=c121bf425f0236689bcd09d4215854e343d31231)).
- Некоторые импорты переместились между модулями, это нужно учесть (пример: [spidermonkey](https://cgit.freebsd.org/ports/commit/?id=d8107994a2970045df453f6e702925ffdf59c7cb)).
- Исправить сборочные скрипты, которые вместо использования конкретной, определённой системой портов, версии Python перебирают (не) все версии подряд. Пример из лога [multimedia/gstreamer1-editing-services](https://www.freshports.org/multimedia/gstreamer1-editing-services/):
  ```
  checking for python... no
  checking for python2... no
  checking for python3... no
  checking for python3.9... no
  checking for python3.8... no
  checking for python3.7... no
  checking for python3.6... no
  checking for python3.5... no
  ```
- Заставить сборку использовать версионированные исполняемые файлы питоновских программ. Из [исправления](https://cgit.freebsd.org/ports/commit/?id=39f2c705c61fb27085aeaa49bdef553222b9d425) для [math/py-gmpy2-devel](https://www.freshports.org/math/py-gmpy2-devel/):
  ```diff
  -   (cd ${WRKSRC}/docs && ${GMAKE} html)
  +   (cd ${WRKSRC}/docs && ${GMAKE} SPHINXBUILD=sphinx-build-${PYTHON_VER} html)
  ```
  Похожее [исправление](https://cgit.freebsd.org/ports/commit/?id=913219385dfdf72232e6beefe287377cfebdfb04) для [devel/cmake](https://www.freshports.org/devel/cmake/).
- Исправить кривую работу с версией питона в коде, например конструкция `platform.python_version()[:3]` вернёт `3.1` для Python 3.10 (примеры: [libSEDML](https://github.com/fbergmann/libSEDML/pull/156/files), [abseil](https://cgit.freebsd.org/ports/commit/?id=2f218ad4d3d6be04278777412af0f18a5ad8e17b)).
- Ну и в крайнем случае, просто пометить порт как не поддерживающий новые версии языка:
  ```diff
  -USES=python:3.6+
  +USES=python:3.6-3.9
  ```

### Протащить обновления pytest и numpy

Обновления для важных портов висят в багзилле месяцами, это совсем
не дело. Причина почему висят, в общем, понятна - обновления тяжёлые,
затрагивают много портов и требуют их тестирования, а где-то и
адаптации. Если соберусь, нужно зайти с другого конца - начать с
сохранения легаси версии порта (например `py-pytest` → `py-pytest4`)
и переключения всех потребителей на неё. Это косметическое изменения
и поломок тут быть не должно. Затем спокойно обновить основной порт
и начать переводить потребителей на новую версию по одному.


## Квест про добавление поддержки Python 3.10

Наконец, хочу поделиться историей про добавление поддержки 3.10,
которое потребовало значительных не связанных напрямую изменений.

Кроме обычного набора несовместимостей у Python 3.10 было одно
особое отличие, которым не обладал ни один из предыдущих релизов:
двузначный minor компонент версии.

В портах FreeBSD есть некая логика сравнения версий питона, а так
как порты FreeBSD - это `make` в котором нет подходящих для этого
инструментов типа кортежей, версию приходится приводить к обычному
числу. Поэтому, например, `3.9.1` становится `3901`, что уже можно
сравнивать арифметически. Заметили проблему? `10` в один знак не
влезает. Поэтому число пришлось расширить.

Забавно, но это уже было сделано один раз для patch версии,
из [CHANGES](https://cgit.freebsd.org/ports/tree/CHANGES):

```
20150526:
AUTHOR: antoine@FreeBSD.org

  PYTHON_REL has been switched from a 3 digits number to a 4 digits number to
  handle python 2.7.10.  Ports checking for python 2.7.9 should compare
  PYTHON_REL against 2709 and ports checking for python 2.7.10 should compare
  PYTHON_REL against 2710.
```

но только урок не был извлечён, и аналогичное [исправление](https://cgit.freebsd.org/ports/commit/?id=0729af4255a63ee299e0c63a18b6a86520a19e02) пришлось сделать для другого компонента версии.

Понадобилось ещё одно [исправление](https://cgit.freebsd.org/ports/commit/?id=40d7b487381cc91eb3156103e6ffe8c02d5e8a70) в другом куске make кода, не готового в двузначным minor версиям.

**Хозяйке на заметку**: не скупитесь на разряды когда упаковываете
версию или что-то похожее в число.

Далее, пришлось изменить работу с версиями в самих портах Python
чтобы поддержать там пререлизные версии. Порт может определить одну
из переменных `PORTVERSION` (версия порта/пакета используемая во
FreeBSD) или `DISTVERSION` (версия upstream). `lang/python*` порты
использовали первое, что приводило к некорректному сравнению
пререлизных версий:

```
% pkg version -t 3.11.0a2 3.11.0
>
```

Пришлось [переделать](https://cgit.freebsd.org/ports/commit/?id=5f69415313f894338dca54e21b5c3981e5e5f58f)
порты на использования `DISTVERSION` - указанная посредством этой
переменной версия проходит нормализацию (например, из
`DISTVERSION=3.11.0a2` генерируется `PORTVERSION=3.11.0.a2`), и
получается корректно сравнимое значение:

```
% pkg version -t 3.11.0.a2 3.11.0
<
```

Далее понадобилось [обновить](https://cgit.freebsd.org/ports/commit/?id=7a4ce8f831c4911061f4f465b4bf1e830267d4dc)
порт модуля [setuptools](https://www.freshports.org/devel/py-setuptools/). Версия `44.1.1` что была в портах на тот
момент поддерживала Python 2 (который до сих пор чему-то в портах
нужен), но не Python 3.10. Свежая на тот момент версия `57.0.0`
поддерживала Python 3.10, но не Python 2. Поэтому пришлось скопировать
старую версию в порт [devel/py-setuptools44](https://www.freshports.org/devel/py-setuptools44/)
и добавить машинерию для переключения на неё для портов использующих python2.

Параллельно с этими инфраструктурными изменениями множество портов
было исправлено под свежий питон или обновлено.

Наконец, через почти два месяца после первого коммита, Python 3.10.0beta4
[попал](https://cgit.freebsd.org/ports/commit/?id=930c93129234e5ed3f67be1b8795a5a20e2745db) в порты.

К слову, добавлением Python 3.11 было гораздо более гладким - почва
была уже подготовлена. Кроме собственно
[питона](https://cgit.freebsd.org/ports/commit/?id=d6f568cf8a0c57c1280efb31b1b2ab850a87267f)
понадобилось всего лишь
[добавить](https://cgit.freebsd.org/ports/commit/?id=ab67421b6e9f96ffc0975cc8f28e57fc71612127)
снапшот версию cython
[lang/cython-devel](https://www.freshports.org/lang/cython-devel/)
(стабильный cython пока не поддерживает Python 3.11)
и
[починить](https://cgit.freebsd.org/ports/commit/?id=27f3f4018fbe293d3a12dd2fd8212a93c4619b9a)
[databases/py-sqlite3](https://www.freshports.org/databases/py-sqlite3/).
Надеюсь что проведённая работа позволит добавлять следующие версии
ещё проще.
