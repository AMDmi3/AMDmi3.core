---
title: "Recent Ubuntu for GitHub Actions"
date: 2021-12-24T19:58:10+03:00
draft: true
---

In summer 2020 when I've migrated CI of my projects to GitHub Actions
I cherished hope that GitHub (unlike, for instance, Travis CI) will
provide up to date CI environments and that hope was fueled by the
fact that fresh Ubuntu 20.04 was already available. Well unfortunately
that hope did not come true, in the end of 2021 Ubuntu 20.04 is still
the latest CI environment available, and it's already too old to be
suitable for CI. A short explanation and the solution follows.

<!--more-->

## Why fresh(est) CI environment is important

The CI process is supposed to test a lot of properties of the
software, allows to reveal problems early and prevent them from
hitting users. Let's focus on one aspect of these, which is
compatibility with system and dependencies from different age.

You want to be compatible with older environments - after all
these are stable/LTS distributions which many (most?) people run.

You also want to be compatible with newer environments because you
want to catch the compatibility breakages and deprecations in newer
versions of dependencies and prevent your code from breaking because
of these. A lot of people run rolling distributions too.

But here's a paradox: you may target stable/LTS distributions, but
your code will never get into them just because these only include
critical updates and bugfixes, not the new software. So in fact the
code you're developing right now may only get to the *next* LTS
release. That you should target and that you should prepare to, so
it's the most important to test in the newest environments. Needless
to say, it ensures compatibility with rolling distributions as well.

That is why Travis and GitHub policies of not providing anything
newer than the latest LTS are impractical. In general, in 2022 one
(*optionally*) needs some of the *previous* LTS releases (such as
18.04 which is supported until 2028) if backwards compativility is
deemed important, and *obligatory!* needs a latest/next release
(e.g. 21.10 or 22.04) to ensure compatibility with current software
and run latest versions of static analysis, fuzzing, linting, and
sanitizer tools.

## Real world cases

I've ran into problems with outdatedness of CI environments a lot
of times:

- I've had to
  [use PPAs](https://github.com/libSDL2pp/libSDL2pp/blob/a50a6943f445054a7f7fff2f959b734e0aae08d8/.travis.yml#L6-L7)
  to get decent compiler and dependency versions
- I've had to
  [patch](https://github.com/libSDL2pp/libSDL2pp/blob/4fe70e1980e8ece742118739b37a8e8f4f50797e/.travis.yml#L13)
  broken headers from outdated gcc
  ([another case](https://github.com/libSDL2pp/libSDL2pp/blob/86cdcdf5886ff8813c2a4eae065b13f341482d17/.travis.yml#L13))
- I've had to
  [disable](https://github.com/libSDL2pp/libSDL2pp/blob/86cdcdf5886ff8813c2a4eae065b13f341482d17/.travis.yml#L17)
  some linter checks because outdated version produced false positives
- And recently I've had to
  [backport](https://github.com/AMDmi3/qnetwalk/blob/master/.github/workflows/ci.yml#L27-L31)
  CMake support bits for SDL2

This is definitely not what I expect from a decent CI. I want a
recent environment which is capable of compiling moderately modern
code out of box.

## Solution

I want to thank [@rridley@fosstodon.org](https://fosstodon.org/@rridley)
for suggesting this solution. I avoid containers for being unportable
and overcomplicated, so I would not look this way myself, but after some
hints it turned out to be pretty easy and straightforward.

It's mentioned in GH action
[docs](https://docs.github.com/en/actions/learn-github-actions/workflow-syntax-for-github-actions#jobsjob_idcontainer)
in fact, but here's a complete recipe:

### Add `container` directive

Add `container` directive with latest Ubuntu image to your workflow
config:

```patch
 jobs:
   build:
     runs-on: ubuntu-latest   # this is no longer important
+    container:
+      image: ubuntu:rolling   # this does themagic
     steps:
    ...
```
You can look up the available containers on
[docker hub](https://hub.docker.com/_/ubuntu) - `ubuntu:rolling`
is the latest non-LTS release, and `ubuntu:devel` is the upcoming
release. Other distributions are also available.

### Remove `sudo` from you scripts

The container is run from the user, and sudo is not available.

```patch
     steps:
      - name: Install dependencies
        run: |
-         sudo apt-get update -qq
-         sudo apt-get install qtbase5-dev
+         apt-get update -qq
+         apt-get install qtbase5-dev
      ...
      - name: Install the project
-       run: sudo make install
+       run: make install
```

### Add missing dependencies

The main shortcoming of using a container is that you'll get a naked
system (as opposed to an image stuffed with build utilities) so
you'll have to explicitly specify compilers, build systems, languages
and utilities you depend on (`build-essential`, `clang`, `cmake`
etc.). The good news is that your CI script becomes more of a
documentation by mentioning actual list of dependencies.

  I suggest to also add `--no-install-recommends` option to avoid
  installing unneeded packages.

  ```patch
        - name: Install dependencies
        run: |
          export DEBIAN_FRONTEND=noninteractive
          apt-get update -qq
  -       apt-get install qtbase5-dev
  +       apt-get install -y --no-install-recommends build-essential clang cmake qtbase5-dev
  ```

### One more thing

Add `DEBIAN_FRONTEND=noninteractive` to your environment variables.

This would prevent `apt-get` from handing on interactive prompt, such
as for setting a timezone.

```patch
      - name: Install dependencies
      run: |
+       export DEBIAN_FRONTEND=noninteractive
        apt-get update -qq
        apt-get install -y --no-install-recommends build-essential clang cmake qtbase5-dev
```

### Doubts

You're may be wondering whether this would slow down your builds.
Well, it looks like it would not. Although it does need to install
several hundreds more packages compared to stock image, `apt-get`
step took just 10 seconds longer for my QNetWalk project.

Also you may be wondering whether this is officially allowed by
GitHub, and it looks like it as well is. From official
[README](https://github.com/actions/virtual-environments/) for
GitHub Actions Virtual Environments:

> Looking for other Linux distributions? We do not plan to offer
other Linux distributions. **We recommend using Docker if you'd like
to build using other distributions** with the hosted virtual environments.
Alternatively, you can leverage self-hosted runners and fully
customize your environment to your needs.

### Conclusion 

These simple steps
([complete commit](https://github.com/AMDmi3/qnetwalk/commit/ac20b304e21d851e9cc2f14fd1245087d008487e))
allowed me to build my application on a newest Ubuntu and remove
hacks needed to fix it on the LTS, and I plan to use this in all
my projects.
