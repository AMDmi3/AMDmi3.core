---
title: "Python 3.11 in FreeBSD Ports"
date: 2021-12-06T15:40:49+03:00
---

A month ago I've [landed](https://cgit.freebsd.org/ports/commit/?id=d6f568cf8a0c57c1280efb31b1b2ab850a87267f)
Python 3.11 (alpha2) in FreeBSD Ports tree. This is a continuation
of my past work on Python 3.10 support, and likewise, it allows
curious ones to play with the upcoming release, maintainers to
prepare their ports and developers to make sure their code is
compatible with the language changes. I'd like to share some details
on latest Python support in FreeBSD and the story of porting Python
3.10.

<!-- more -->

## Python 3.10 status

[Python 3.10](https://docs.python.org/3/whatsnew/3.10.html) support
is not production ready yet, as some critical ports do not support
it. The most important is [math/py-numpy](https://www.freshports.org/math/py-numpy/)
(update [PR](https://bugs.freebsd.org/bugzilla/show_bug.cgi?id=259637)
since Nov 04, no reaction from python@ for a month). A lot of ports
which depend in it are not available in Python 3.10 flavor.

Some other important dependencies lacking 3.10 support:
- [devel/py-pytest](https://www.freshports.org/devel/py-pytest/) (mostly useful for `make test` of other python ports) - update [PR](https://bugs.freebsd.org/bugzilla/show_bug.cgi?id=256624) since Jun 15, no reaction from python@ for a month.
- [math/py-gmpy2](https://www.freshports.org/math/py-gmpy2/)
- [devel/shiboken2](https://www.freshports.org/devel/shiboken2/)
- [devel/py-qt5-qscintilla2](https://www.freshports.org/devel/py-qt5-qscintilla2/)

Expectedly, there's a few dozen of leaf port failures as well.

Still, it may work for you depending on which modules you need.
For instance, everything I need for my Python projects including
[Repology](https://github.com/repology/) work fine and I've already
switched my production to Python 3.10.

```make
DEFAULT_VERSIONS+=python=3.10 python3=3.10
```


## Python 3.11 status

All the issues with 3.10 apply here too (but the good part is that
they will likely be fixed for both versions), and a bunch of new
problems is expected. Since this is still an alpha, thus a moving
target, there's not much sense in polishing 3.11 support explicitly,
but all new failures may reveal generally problematic ports which
need attention.

Not much is expected to work here, but still I've already managed
to fix most of ports I use (the only remaining is [www/uwsgi](https://www.freshports.org/www/uwsgi),
which will be fixed by an [update](https://bugs.freebsd.org/bugzilla/show_bug.cgi?id=260028) this
week). A poudriere build which will reveal 3.11 specific failures
is currently running.


## Further work

### Fix more individual failures

The workflow: run a poudriere build with `DEFAULT_VERSIONS=python3.10
python3=3.10`, identify failures, fix. Most fixes are trivial (so you
can help too), for instance:

- Need to force cython files to be regenerated (examples: [asyncpg](https://cgit.freebsd.org/ports/commit/?id=a97113cd3943a879380fbbcf5dfddcd6004bdccb), [aiohttp](https://cgit.freebsd.org/ports/commit/?id=c121bf425f0236689bcd09d4215854e343d31231)). Notably, these changes prevent breakages with future python versions (as soon as cython keeps up with Python C API changes).
- Fix some imports after some modules were moved around (example: [spidermonkey](https://cgit.freebsd.org/ports/commit/?id=d8107994a2970045df453f6e702925ffdf59c7cb)).
- Fix build scripts to use fixed version of Python instead of iterating through (not) all versions. From [multimedia/gstreamer1-editing-services](https://www.freshports.org/multimedia/gstreamer1-editing-services/) failure log:
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
- Force build to use versioned Python scripts. From [fix](https://cgit.freebsd.org/ports/commit/?id=39f2c705c61fb27085aeaa49bdef553222b9d425) for [math/py-gmpy2-devel](https://www.freshports.org/math/py-gmpy2-devel/):
  ```diff
  -   (cd ${WRKSRC}/docs && ${GMAKE} html)
  +   (cd ${WRKSRC}/docs && ${GMAKE} SPHINXBUILD=sphinx-build-${PYTHON_VER} html)
  ```
  Similar [fix](https://cgit.freebsd.org/ports/commit/?id=913219385dfdf72232e6beefe287377cfebdfb04) for [devel/cmake](https://www.freshports.org/devel/cmake/).
- Fix incorrect version handling in Python code, such as `platform.python_version()[:3]` construct which returns `3.1` for Python `3.10` (example: [libSEDML](https://github.com/fbergmann/libSEDML/pull/156/files), [abseil](https://cgit.freebsd.org/ports/commit/?id=2f218ad4d3d6be04278777412af0f18a5ad8e17b)).
- As a last resort, mark a port not compatible with newer python versions:
  ```diff
  -USES=python:3.6+
  +USES=python:3.6-3.9
  ```

### Force pytest and numpy updates

Updates for important ports handing in the bugzilla for months is
not acceptable. In most cases they are blocked by testing or fixing
the affected ports, which may last forever. So instead it could be
solved by preserving an older version of the port (e.g. copy
`py-pytest` → `py-pytest4`) and switching all the consumers to it
(this is merely a cosmetic change not expected to cause any breakages),
then update actual version of the port and gradually switch consumers
onto it. Given enough time, I'd have to take responsibility and perform
these updates since python@ team is not generally active.


## The quest of adding Python 3.10

Finally I'd like to share a story of porting Python 3.10, which
required a bunch of not directly related changes.

Apart from Python 3.10 included a usual set of incompatible changes,
there was one special thing about this release: it's minor version
contained two digits.

FreeBSD ports framework has internal machinery for comparing Python
versions, and since it's `make` based (and `make` lacks useful tools
for that purpose like tuples), versions have to be converted to
plain numbers, where e.g. `3.9.1` would be represented as `3901`.
You can notice that there's no place for `10` minor version here,
that is exactly why it's had to be extended.

Funnily enough, it had already been extended in the past for patch
version. From [CHANGES](https://cgit.freebsd.org/ports/tree/CHANGES)
file:

```
20150526:
AUTHOR: antoine@FreeBSD.org

  PYTHON_REL has been switched from a 3 digits number to a 4 digits number to
  handle python 2.7.10.  Ports checking for python 2.7.9 should compare
  PYTHON_REL against 2709 and ports checking for python 2.7.10 should compare
  PYTHON_REL against 2710.
```

just to repeat the same mistake which needed another [fix](https://cgit.freebsd.org/ports/commit/?id=0729af4255a63ee299e0c63a18b6a86520a19e02).

There was another part of the framework which did not expect two-digit
minor version and had to be [fixed](https://cgit.freebsd.org/ports/commit/?id=40d7b487381cc91eb3156103e6ffe8c02d5e8a70)
as well.

**Lesson learned**: do not spare digits for numeric representation of
a version or another thing you try to pack into it.

Then I've had to fix the way a version is handled for Python
ports to allow pre-release versions. FreeBSD port may define either
`PORTVERSION` (version as used by FreeBSD) or `DISTVERSION` (version
as defined by upstream), and Python ports used the former. This led
to incorrect comparison for pre-release versions:

```
% pkg version -t 3.11.0a2 3.11.0
>
```

So I've had to [switch](https://cgit.freebsd.org/ports/commit/?id=5f69415313f894338dca54e21b5c3981e5e5f58f)
everything to `DISTVERSION`, which implies normalization of upstream
version into something compatible with FreeBSD. That is, for
`DISTVERSION=3.11.0a2` the framework generates `PORTVERSION=3.11.0.a2`
which compares correctly:

```
% pkg version -t 3.11.0.a2 3.11.0
<
```

Then I've had to [update](https://cgit.freebsd.org/ports/commit/?id=7a4ce8f831c4911061f4f465b4bf1e830267d4dc)
[setuptools](https://www.freshports.org/devel/py-setuptools/) module.
The port was at `44.1.1` which supported Python 2 (which we still
need for some consumers), but not Python 3.10. The updated version
`57.0.0` supported Python 3.10, but not Python 2. So I've had to
preserve the older version as
[devel/py-setuptools44](https://www.freshports.org/devel/py-setuptools44/)
and add some machinery which switches to it for python2 ports.

A lot of Python ports were also fixed and updated in the meantime.

Finally, in almost two months after the first commit, Python 3.10.0beta4
has [landed](https://cgit.freebsd.org/ports/commit/?id=930c93129234e5ed3f67be1b8795a5a20e2745db).

Python 3.11 update went much smoother, as most prerequisites were
already in place.
Apart from landing
[Python](https://cgit.freebsd.org/ports/commit/?id=d6f568cf8a0c57c1280efb31b1b2ab850a87267f)
itself, I've just had to
[add](https://cgit.freebsd.org/ports/commit/?id=ab67421b6e9f96ffc0975cc8f28e57fc71612127)
[lang/cython-devel](https://www.freshports.org/lang/cython-devel/)
port (as stable cython had no support for python 3.11 yet) and apply
a minor
[fix](https://cgit.freebsd.org/ports/commit/?id=27f3f4018fbe293d3a12dd2fd8212a93c4619b9a)
to
[databases/py-sqlite3](https://www.freshports.org/databases/py-sqlite3/).
Hopefully, my work will make future updates easier too.
