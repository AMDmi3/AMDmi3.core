---
title: "Packaging Friendliness: Don't Call Git During the Build"
date: 2021-12-22T21:49:09+03:00
draft: true
---

Some developers find it useful to include VCS information (such as
the commit ID, branch, or date) into the builds of their software.
This is usually done by calling `git` (or another VCS) during the
build and recording its output, or by using dedicated tools like
[autorevision](https://autorevision.github.io/). Unfortunately, this
doesn't work at all when software is packaged.

<!--more-->

## TL;DR

Don't call `git` or `autorevision` from your build.

## It won't work

In most cases, package building process **does not** involve VCS
(I'll assume it's `git` for the purpose of this post) when fetching
upstream sources. Regardless of whether a tag or a random commit
is fetched, it's fetched as a *tarball*, which most VCS hosting
facilities support (for example, GitHub link may look like
`https://github.com/<account>/<project>/archive/<commit>.zip`).
The reason for this is that archive is much faster and easier to
download and handle, and allows caching, mirroring, and verification.

Because the project is not built in the repository, `git rev-parse`,
`git describe`, or `git log --oneline | wc -l` you're probably
trying to call will fail with `fatal: not a git repository` error.

Obviously, the very basic thing to do would be to ensure that you
build does not fail when either repository or `git` itself is not
available. However, the better would be to drop the call completely,
bacause not only it fails to reliably do its job, but may also have
more malicious side effects.

### It forces dependency on `git`

Most of us don't like it when a package pulls in needless dependencies,
and in this case a dependency on `git` is required for no good reason.

A package maintainer can't just ignore it as otherwise the package
build would behave inconsistenly, e.g. produce different contents
depending on whether `git` is or is not available on the system. So
in most practical cases of fine packaging the VCS polling logic would
be axed out instead.

### It may access the wrong repository

As said, it's unlikely to have a repository in the package building
process.  But what if there's `.git` somewhere higher in the directory
tree? It's not uncommon to manager user home directory or a system
root as a repository, and in that case VCS polling logic may see
*that* repository instead, and produce a completely unrelated commit
information. In some cases (when it's included into crash ports,
for instance), it may as well leak private info.

### Avoid `autorevision`

A specific warning about autorevision, which, being susceptible to
above mentioned problems, it a pretty complex script which may
introduce inconsis
portability problems on its own. When I first encountered it, I've
had to do a [whole
bunch](https://github.com/Autorevision/autorevision/commits?author=AMDmi3)
of portability fixes to it.

## Countering

Most maintainer would just axe the VCS calls out. In some cases it
requires patching, in some cases a less invasive solution is possible,
such as preventing CMake 

## Alternative

- Make sure you need to include commit info to the build

- Note that there's no problem including commit info into the 

Make sure you need it. If someone is building your code from
repository, can't they include commit information in the bug
reports manually?
