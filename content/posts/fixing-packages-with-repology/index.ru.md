---
title: "Чиним пакеты с Repology"
date: 2021-05-19T14:39:48+03:00
---

Небольшой пример как можно использовать [Repology](https://repology.org/)
для поиска решений проблем со сборкой пакетов (которые скорее всего
уже кто-то решил).

<!--more-->

Есть такой простенький игровой движок [LÖVE](https://love2d.org/).
Печаль связанная с ним заключается в том, что разработчики не
сохраняют обратную совместимость между релизами, в итоге игры
написанные под старые версии движка (например 7.x или 8.x) не
заработают с актуальной версией. Ради этих игр приходится поддерживать
пакеты старых версий движка, уже не поддерживаемые его авторами.

Есть две приятных игры которые мне не хотелось бы потерять, и
которые как раз требуют древней LÖVE - 
[GunFu Deadlands](http://gunfudeadlands.sourceforge.net/)
(аркадная стрелялка на Диком Западе с возможностью замедления
времени) и [Mari0](https://stabyourself.net/mari0/) (всем известный
Марио с механикой портальной пушки).

{{< gallery >}}
	{{< img src="gunfudeadlands.png" size="x200" caption="Скриншот GunFu Deadlands" >}}
	{{< img src="mari0.png" size="x200" caption="Скриншот Mari0" >}}
{{< /gallery >}}

Порты [love07](https://cgit.freebsd.org/ports/tree/devel/love07) и
[love08](https://cgit.freebsd.org/ports/tree/devel/love08), которые
требуются для данных игр, полгода назад сломались
([1](https://cgit.freebsd.org/ports/commit/devel/love07/Makefile?id=c4a1290e515b0e404e6f519267b1bedf79f8c9af),
[2](https://cgit.freebsd.org/ports/commit/devel/love08/Makefile?id=5e69b7a9d2ad375fee51976e3f4c347763ec4ced)).
К своему стыду я это пропустил (поэтому хочу когда-нибудь написать
инструмент мониторинга, который пропустить такое не позволит), но
лучше поздно чем никогда починить их.

> На самом деле, правильным решением в долгосрочной перспективе
> было бы портировать игры на новую версию движка. Это потребовало
> бы больше усилий - нужно изучить движок, код игр, портировать
> на новую версию, а в некоторых случаях ещё и взять на себя
> поддержку, посколько, как это часто случается, авторам игра
> уже не интересна.
>
> Возможно, в следующий раз, но если вы ищете куда поконтрибутить,
> вот хороший кандидат.

> В процессе выяснилось что у Mari0 есть новая версия совместимая
> с LÖVE 11. Отлично, одной проблемой меньше.

Ошибки из логов

```
modules/graphics/opengl/SpriteBatch.cpp:77:3: error: use of undeclared identifier 'glGenBuffers'
                glGenBuffers(2, vbo);
                ^
modules/graphics/opengl/SpriteBatch.cpp:79:3: error: use of undeclared identifier 'glBindBuffer'
                glBindBuffer(GL_ARRAY_BUFFER, vbo[0]);
                ^
modules/graphics/opengl/SpriteBatch.cpp:80:3: error: use of undeclared identifier 'glBufferData'
                glBufferData(GL_ARRAY_BUFFER, sizeof(vertex)*size*4, vertices, gl_usage);
                ^
modules/graphics/opengl/SpriteBatch.cpp:81:3: error: use of undeclared identifier 'glBindBuffer'
                glBindBuffer(GL_ARRAY_BUFFER, 0);
                ^
```

намекают на проблемы с OpenGL - компилятор перестал видеть объявления
некоторых функций. Можно было бы начать вспоминать в каких заголовочных
файлах они объявлены, как контролируется их видимость, попытаться
понять в какой момент и из-за чего сборка сломалась, но можно
сэкономить время и проверить не решил ли кто-то уже эту проблему
до меня.

В начале года я добавил в [Repology](https://repology.org/)
возможность строить ссылки на рецепты (т.е. мейкфайлы, ебилды,
PKGBUILDы, спеки и т.д.) сборки для большинства репозиториев, и
показывать их одним списком ([для love07](https://repology.org/project/love07/information#All_package_recipes),
например). Через него можно одним махом просмотреть как опакечивается
тот или иной проект во всех известных репозиториях, какие опции и
флаги используются, какие изменения и патчи накладываются и как
решаются те или иные проблемы.

В нашем примере достаточно прокликать этот список и поискать что-нибудь
связанное с GL. На самом деле нужно ещё по несколько дополнительных
кликов на каждый рецепт, потому что нужная информация может не быть
в него включена непосредственно, а лежать рядом - например, в виде
файлов с патчами. Однако, поиск приносит плоды: в
[AUR](https://aur.archlinux.org/cgit/aur.git/tree/love07.patch?h=love07),
[Nix](https://github.com/NixOS/nixpkgs/blob/master/pkgs/development/interpreters/love/0.7-gl-prototypes.patch) и
[Gentoo](https://gitweb.gentoo.org/repo/gentoo.git/tree/games-engines/love/files/love-0.7.2-opengl_glext_prototypes.patch)
есть патчи похожие на то что нужно:

```diff
diff --unified --recursive --text love-HEAD.orig/src/modules/graphics/opengl/Framebuffer.cpp love-HEAD.new/src/modules/graphics/opengl/Framebuffer.cpp
--- love-HEAD.orig/src/modules/graphics/opengl/Framebuffer.cpp	2019-03-14 12:46:55.032982224 -0400
+++ love-HEAD.new/src/modules/graphics/opengl/Framebuffer.cpp	2019-03-14 12:47:22.356175299 -0400
@@ -1,3 +1,5 @@
+#define GL_GLEXT_PROTOTYPES
+
 #include "Framebuffer.h"
 #include <common/Matrix.h>
```

Значит, достаточно просто объявить дефайн `GL_GLEXT_PROTOTYPES`.
Да, это исправило порты.

Есть планы по улучшению продемонстированной функциональности в
Repology - например, [можно скачивать](https://github.com/repology/repology-linkchecker/issues/30)
рецепты и показывать их без лишних кликов непосредственно на сайте,
ещё и с удалением дубликатов и полнотекстовым поиском.

Repology уже умеет таким же образом строить сразу список всех
известных патчей, но к сожалению [лишь малая доля](https://repology.org/repositories/fields)
(колонка Patches) репозиториев публикует необходимую информацию.
Если вы участвуете в разработке пакетного репозитория не отмеченного
большим числом галочек в этом списке, скорее всего вы можете помочь,
опубликовав больше данных о пакетах.
