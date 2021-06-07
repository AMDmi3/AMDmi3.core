---
title: "Portability ABC: introduction"
date: 2021-05-29T19:16:05+03:00
---

> As [promised]({{< ref "/posts/about-this-blog" >}}), I'm staring
> a series of posts about F/OSS portability which, hopefully, I
> will be able to compiles into something like a book at some point

For 15 years already I create and maintain FreeBSD ports of different
F/OSS software, and forgetfully I have to state that the process has
not become easier in any way during this time. What's the cause?

<!--more-->

On the one hand, the FreeBSD ports collection has been actively
developed all this time - we've had countless framework improvements,
new tools and `pkg` enhancements. On the other hand, F/OSS ecosystem
has developed as well - for instance proper build systems have
appeared, collaboration between software developers and maintainers
has improved, upstreaming have become much easier and the number
of package repositories have boomed. Regardless, we still cannot
write a package recipe in form of minimal set of descriptive
attributes such as

- Name
- Version
- Source distribution URL
- Dependencies list
- Type of build system

Seriously, I have not encountered a software product for which this
would be enough - there's always need to change something, patch
something, tune some flags, install (or disable installation) of
some files manually. It would be totally understandable if these 
were FreeBSD-specific changes, because FreeBSD is quite different
from mainstream Linux most upstreams develop and test their software
on, but most problems are not related to FreeBSD at all, and are
mentioned in packaging guides of many huge Linux distros.

I conclude that despite tooling improvements, community still lacks
a culture of keeping their projects, software repositories and build
scripts portable and packaging friendly and basic understanding of
differences between authors and target systems, and additional
requirements packaging process imposes.

So I hereby embark on a quest to improve the situation and make use
of my vast porting/packaging experience to highlight and document
common mistakes which hinder portability and packaging friendliness.
