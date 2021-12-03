---
title: "Packaging Friendliness: Compiler Flags to Avoid"
date: 2021-11-23T19:26:33+03:00
draft: true
---

It is tempting to enable some (generally useful) compiler flags
such as `-Werror` and `-march=native` in you build **by default**
(such as to discover more problems and generate more efficient
code), however in practice these flags may lead to packaging problems
instead.

<!--more-->

## TL;DR

Don't add `-Werror` and `-march=native` to default build flags of
your project.

## `-Werror`

This flag makes compiler reject code with warnings, forcing author to
fix all of them and thus write cleaner code, so it does make sense
to enable it for local builds and for continuous integration. However,
even if a code is warning-free for you *right now*, you cannot expect
it to remain so with future compiler versions or on different
compilers/arches/OSes, so with `-Werror` your code is prone to break
in different environments as well as over time, which is best to avoid.

Such fragile code increases burden on maintainers (who are forced
to fix warnings in addition to critical problems when doing bulk
updates), and leads to unexpected build failures for end users (such
as after compiler update). In either case, it will likely be shut
up by patching out the `-Werror` flag instead of fixing the warning,
so using `-Werror` as a way to force consumers to submit warning
fixes upstream is not a good idea.

Enabling individual warnings (e.g. `-Werror=uninitialized`) may be
an option, but it requires you to maintain a list of (still incomplete)
must-have warnings, keep it up to date and compatible with different
compilers.

So instead, consider looking for new warnings in package build logs
(available on [Repology](https://repology.org/) for some distros,
for instance) and try to use as many different environments for you
CI as possible.

Example from FreeBSD Ports Collection of patching `-Werror` out:

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

This flag enables optimizations for the CPU the code is built on.
Generally, enabling it allows compiler to generate more effective
code, however the problem with packages is that they are built on
completely different hardware than they are installed and used on.
Not only the code built for different CPU may have performance
regressions on users hardware, but it may not even run (usually
crashing with `SIGILL`), because of using unsupported CPU features.

The additional danger of this flag is that it usually comes unnoticed
by package maintainers and the problems caused by it are hard to
reproduce.  The code runs fine on maintainers hardware; it runs
fine on package building cluster as well; even packages built on
cluster run fine on maintainers hardware. However some user with
slightly older hardware will experience (an unobvious to investigate)
crash.

Example from FreeBSD Ports Collection of patching `-march=native` out:

```make
post-patch:
	@${REINPLACE_CMD} -e 's/ -march=native//' \
		${WRKSRC}/cmake/FindAVX.cmake \
		${WRKSRC}/cmake/FindFMA.cmake \
		${WRKSRC}/cmake/FindSSE.cmake
```
