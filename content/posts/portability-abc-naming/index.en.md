---
title: "Portability ABC: project naming"
date: 2021-06-07T14:44:37+03:00
---

Surprisingly, portability issues for a project may be introduced
long before the first line of code is even written, merly by a bad
choice of projects name.

So make sure the name of your project is clear, unambiguous, unique
and compatible with packaging, otherwise there's chance that the
package or files installed by it would be named differently that
you intended (because of the need to resolve name conflicts, comply
with packaging policies, or just because of misunderstanging your
message of how things should be named) and inconsistently among
different systems and distributions, which, in turn, would cause
users to have trouble locating and running your software, scripts
to break, automated tools to fail, and general confusion.

<!--more-->

## TL;DR

- Pick a clever unique name, check that it's not already used by
  other projects, pick one which is not prone to conflicts in
  future (not too short, not a commonly used word).
- Pick a name compatible with packaging - `[a-z0-9-]+` (lower case!)
  not too long, `lib*` for libraries.
- Spell the name consistently all over your project (repository name,
  distribution file names, build system, documentation, installed
  file and directory names).

## Pick unique name

In \*nix world we historically put names of third party software
into flat namespaces. For instance, all package names usually reside
in a single namespace, and all executable files are put into a
single `bin/` directory, the same for library and configuration
files.

From one side, this is convenient because you don't need extra
qualifiers to refer to third party software (you install `firefox`
package instead of obscure `org.firefox.firefox` and run `firefox`
binary without need to specify an absolute path). From another side,
name conflicts are possible, e.g. cases where unrelated projects
have the same names.

Having such conflicting names is generally not allowed as it would
make it impossible to tell unrelated packages from each other, or
get files from unrelated packages mixed up and overwritten by each
other. So maintainers have to resolve these conflicts by renaming
stuff, usually by adding some sort of name suffixes. In *most* cases
this allows coexistence of similarly named projects, however things
are no longer named as authors intended them and users expect them
to be. In addition, the naming can be different in each repository,
which breaks distro migration and interoperability and portability
of dependent software.

So, project name conflicts are a bad thing which must be avoided,
that is why when choosing a name for your project, you should check
it first in at least the following sources:
- [Repology](https://repology.org/projects/) for existing package
  names (because it knows most package repositories). Also try
  `https://repology.org/project/<name>` to check for gone projects
  not shown in the search.
- Software repositories, markets and catalogues not covered by
  Repology, such as Google play or App Store, for other software
  products.
- [GitHub](https://github.com/search/advanced?type=Repositories)
  for existing repository names.
- Other source code hostings, even if these primarily host abandoned
  projects, as these may be resurrected at some point:
  [Launchpad](https://launchpad.net/),
  [Savannah](https://savannah.nongnu.org/),
  [SourceForge](https://sourceforge.net/).
  There's an unmaintained
  [script](https://github.com/Debian/devscripts/blob/master/scripts/namecheck.pl)
  from Debian which checks most of them and an
  [extension](https://www.linux.org.ru/forum/talks/16120740?cid=16123711)
  for it.
- Conventional search engines. Note that you generally want your
  project to be unique not only among other software products,
  but preferably worldwide, so users could find it right away
  by just typing your cool unique name into the search box.

Even if you've chosen a name which seem unique right now, it's not
impossible for *another* project (which doesn't care that much about
name uniqueness) to choose the same name in future.  It looks like
these additional considerations may decrease the odds of such an
event:
- avoid short names (shorter name → likelier the conflict);
- avoid simple single-world names (ski, slack, slice, slim, slime,
  smack…).

Some examples of existing name conflicts (taken from Repology, which
knows
[hundreds](https://github.com/repology/repology-rules/tree/master/850.split-ambiguities)
of them):

- `clementine` (music player vs. window manager)
- `clog` (changelog management utility vs. log tail utility vs. logging
  library vs. tcp logger)
- `et` (eternal terminal vs. egg timer vs. enemy territory)
- `grip` (cd ripper vs. markdown previewer vs. gambas previewer vs.
  regexp search vs. computer vision engine)
- `kup` (KDE backup software vs. kernel.org upload tool)
- `lux` (two unrelated brightness control utilities vs. fulltext
  search vs. kernel updater)
- `mars` (two unrelated games vs. MIPS Assembler and Runtime Simulator
  vs. chemical software vs. runtime system)
- `nomad` (wifi configurator vs. orchestrator vs. browser vs. active
  directory related tool)
- `pcl` (coroutile library vs. point cloud library)
- `sdb` (game vs. database library vs. sdbd client vs. hashtable
  library vs. mono soft debugger client)

## Pick packaging friendly name

Some repositories do not allow or just avoid, or force some name
patterns in package naming. Taking these into account when picking
a package name would allow maintainers to not have to mangle project
name.

- Avoid upper case.
- Prefer `-` as word separators.
  > Package names SHOULD be in lower case and use dashes in preference
  > to underscores. \
  > -- [Fedora Naming Guidelines](https://docs.fedoraproject.org/en-US/packaging-guidelines/Naming/)
- Avoid other non-alphanumeric characters, preferably stick to `[a-z0-9-]+`
  > When naming packages for Fedora, the maintainer MUST use the dash
  > '-' as the delimiter for name parts. The maintainer MUST NOT use
  > an underscore '\_', a plus '+', or a period '.' as a delimiter \
  > -- [Fedora Naming Guidelines](https://docs.fedoraproject.org/en-US/packaging-guidelines/Naming/)
- Prefer prefixing library project name with `lib`.
  > Package should be named lib%name%abiversion \
  > -- [Alt Linux Shared Libs Policy](https://www.altlinux.org/Shared_Libs_Policy) (Russian)
- Avoid prefixing project name with language name (as in `python-dateutil`).

  Most repositories prefix module packages themselves, so
  `python-dateutil` becomes confusing `python-python-dateutil`
  (prefix + complete original name), or gets mangled into e.g.
  `py3-dateutil` (part of original name stripped to not duplicate
  prefix). This in turn may spawn name conflicts if later someone
  tries to package e.g. `dateutil` module.

Examples of package naming discrepancies:
- `libc++` → `libcxx`
- `crypto++` → `cryptopp`, `libcryptopp`
- `freetype` → `libfreetype`
- `python-dateutil` → `python-python-dateutil`, `py-dateutil`

## Spell project name consistently

Another common problem is when a project name is spelled inconsistently
in different contexts (source code repository name; distribution file name;
internal naming, build system, documentation; executable and library
file names, include directory name; expected package name, taking
into account limitations described in the previous section).

The inconsistency may involve capitalization (`ddnet` vs. `DDNet`),
word separators (`dd-rescue`, `dd_rescue`, `ddrescue`), long/short
forms (`garden-of-coloured-lights` vs. `garden`, `speech-dispatcher`
vs. `speechd`, `src-highlite` vs. `source-highlight`), or project
development epochs (`mandelbulber` vs. `mandelbulber2`), and may
lead to different small, but nasty problems, such as inability for
a user to find package or executable file right away, for developer
to specify library name or includes path correctly, for maintainers
to package the project consistently in different distributions and
for automated tools to successfully track and report new project
releases and security vulnerabilities.

Examples of consistent naming:
- `diff-so-fancy` hosted at `https://github.com/so-fancy/diff-so-fancy`
  which distributes file `diff-so-fancy` and installs `diff-so-fancy`
  executable.
- `libvirt` hosted at `https://gitlab.com/libvirt/libvirt` and
  `https://libvirt.org/` which installs `include/libvirt/*.h` and
  `libvirt.so`.

## References and further reading

- [Fedora Packaging Guidelines: Naming](https://docs.fedoraproject.org/en-US/packaging-guidelines/Naming/)
- [Fedora Packaging Guidelines: Conflicts](https://docs.fedoraproject.org/en-US/packaging-guidelines/Conflicts/)
- [FreeBSD Porter's Handbook: Package Naming Conventions](https://docs.freebsd.org/en/books/porters-handbook/makefiles/#porting-pkgname)
