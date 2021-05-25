---
title: "Fixing packages with Repology"
date: 2021-05-19T14:39:48+03:00
---

A little example of how to use [Repology](https://repology.org/)
to find solutions to packaging problems (which might've been already
solved by someone).

<!--more-->

There is a game engine called [LÖVE](https://love2d.org/). A
sad thing about it is that its major releases are not backwards
compatible, resulting in that games written for older versions of
LÖVE (such as 7.x or 8.x) will not run with other versions including
the current one. So in order to preserve these games, we have to
keep and maintain unsupported older LÖVE versions in our package
repositories.

The two nice games I would not like to lose, and which require older
LÖVE are [GunFu Deadlands](http://gunfudeadlands.sourceforge.net/)
(Far West themed 2D shooter featuring bullet time), and
[Mari0](https://stabyourself.net/mari0/) (Super Mario Bros clone with
portals).

{{< gallery >}}
	{{< img src="gunfudeadlands.png" size="x200" caption="GunFu Deadlands screenshot" >}}
	{{< img src="mari0.png" size="x200" caption="Mari0 screenshot" >}}
{{< /gallery >}}

[love07](https://cgit.freebsd.org/ports/tree/devel/love07) and
[love08](https://cgit.freebsd.org/ports/tree/devel/love08) ports
required by these games have been broken
([1](https://cgit.freebsd.org/ports/commit/devel/love07/Makefile?id=c4a1290e515b0e404e6f519267b1bedf79f8c9af),
[2](https://cgit.freebsd.org/ports/commit/devel/love08/Makefile?id=5e69b7a9d2ad375fee51976e3f4c347763ec4ced))
for quite some time. My bad for missing this breakage (tooling
required for reliable monitoring of such cases is what I plan
to write someday), but better late than never these ports must be
fixed.

> The right long-term solution would be to fix the games instead.
> It would require much more effort as in learning LÖVE, understanding
> the game code, porting it to the newer engine version and in some
> cases, even taking maintainership of it, because, it's unfortunately
> not uncommon for original upstream to abandon the project.
>
> Maybe next time, but if you're looking for contribution possibilities,
> here's a definite candidate.

> It also turned out that Mari0 has new version which works with
> LÖVE 11, neat.

Errors from the build logs

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

suggest OpenGL related problems - declarations of some functions are
no longer visible to the compiler. I could've started digging and
recalling in which headers these methods are declared, how their
visibility is controlled and what change has caused a breakage, and
it would take some time and effort. It could be saved though if
someone has already fixed the same problem, and we could find that
solution.

Earlier this year I've made [Repology](https://repology.org/) aware of where recipes (e.g.
Makefiles, PKGBUILDs, ebuilds, .specs, etc) are located for most
repositories and made it aggregate these links into a single list
([one for love07](https://repology.org/project/love07/information#All_package_recipes)).
With that it's possible to quickly skim through all the recipes in
other repositories and discover which options and flags other
maintainers use in their packages, which changes they make, which
patches they apply and how they fix problems.

So we click through the recipe list looking for something GL related.
A few extra clicks are needed to check out stuff not included in the
recipe itself (e.g. patch files), but it bears fruit:
[AUR](https://aur.archlinux.org/cgit/aur.git/tree/love07.patch?h=love07),
[Nix](https://github.com/NixOS/nixpkgs/blob/master/pkgs/development/interpreters/love/0.7-gl-prototypes.patch), and
[Gentoo](https://gitweb.gentoo.org/repo/gentoo.git/tree/games-engines/love/files/love-0.7.2-opengl_glext_prototypes.patch)
have patches which look relevant:

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

and suggest that `GL_GLEXT_PROTOTYPES` define should be present.
And voila, with similar changes applied FreeBSD ports are fixed.

I plan to improve this feature of Repology, allowing it to 
[fetch](https://github.com/repology/repology-linkchecker/issues/30)
recipes and show them all on a single page without need to follow
a lot of links along with additional improvements such as duplicate
removal and full text search support.

Repology can already handle patches the same way it handles recipes,
but unfortunately [not many](https://repology.org/repositories/fields)
(see Patches column) repositories provide required information yet.
If you are related to development of package repository with not too
many check marks on that page, you can likely help by publishing more
package metadata.
