---
title: "Contribution Story: Adding an Option to Doxygen"
date: 2021-12-29T22:51:07+03:00
draft: yes
---

I use [Doxygen](https://www.doxygen.nl/index.html) to generate
[documentation](https://sdl2pp.amdmi3.ru/) for a library I maintain,
[libSDL2pp](https://github.com/libSDL2pp/libSDL2pp). One day I've
decided to regenerate the documentation to check that the process
is not broken and my eye was caught by obfuscated email in the docs.
That is absolutely not what I wanted and there was no option do
disable this behavior, so I've decided to add one.

<!-- more -->

Here's how it looked in the generated HTML:

{{< img src="obfuscation.png" size="547x77" >}}

Code (formatted for readability a bit):

```html
<a href="#" onclick="location.href='mai'+'lto:'+'amd'+'mi'+'3@a'+'md'+'mi3'+'.r'+'u'; return false;">
	amdmi<span style="display: none;">.nosp@m.</span>3@am<span style="display: none;">.nosp@m.</span>dmi3.<span style="display: none;">.nosp@m.</span>ru
</a>
```

That's some badass obfuscation! But I don't need it.
- I want my email to be readable as text, and `mailto:` link be
  valid, even for these who have javascript disabled.
- I see spam problem as mostly fictional nowadays, as not using I
  have my email published verbatim on hundreds of sites, and I'm
  not using any spam filters, yet I'm not getting any intolerable
  amount of spam.
- Because it is published on many sites, obfuscating it in a single
  one won't change a thing anyway.

So, let's teach Doxygen to not break my email.

First, I need to find a place in the code which does the obfuscation,
and that's straightforward:

```
% git clone https://github.com/doxygen/doxygen/ .
% % grep -R nosp@m . 
./src/htmldocvisitor.cpp:      if (*p) m_t << "<span style=\"display: none;\">.nosp@m.</span>";
```

That gets us into a function which, as the name suggests, handles
URLs somehow:

{{< highlight "c++" "linenos=true,linenostart=375" >}}
void HtmlDocVisitor::visit(DocURL *u)
{
  if (m_hide) return;
  if (u->isEmail()) // mail address
  {
    QCString url = u->url();
    // obfuscate the mail address link
    writeObfuscatedMailAddress(url);
    const char *p = url.data();
    // also obfuscate the address as shown on the web page
    uint size=5;
    while (*p)
    {
      for (uint j=0;j<size && *p;j++)
      {
        p = writeUTF8Char(m_t,p);
      }
      if (*p) m_t << "<span style=\"display: none;\">.nosp@m.</span>";
      if (size==5) size=4; else size=5;
    }
    m_t << "</a>";
  }
  else // web address
  {
    m_t << "<a href=\"";
    m_t << u->url() << "\">";
    filter(u->url());
    m_t << "</a>";
  }
}
{{< /highlight >}}

You don't really have to grasp this code to see that it indeed
inserts `<span>`s with garbage into link text and also passes it
to `writeObfuscatedMailAddress()` which, as it turns out, writes
link tag (`<a href="mailto:...`) and obfuscates it as well.

So all I need now is to wrap the code in `if`'s which check a config
variable, and write verbatim URLs in `else` branches.

But to do that I need to add a config variable and I need to know
how to access it. For the latter, I've tried searching for `[Cc]onfig`
in this very source file, and that returned an example case of
variable access right away: `Config_getBool(DOT_CLEANUP)`. Then
I've grepped `DOT_CLEANUP` through Doxygen sources to find where
it is defined. Usually it'll be a `#define` or `enum` value in some
header file, but in this case it was an .xml instead:

```
% grep -R DOT_CLEANUP .
...
./src/config.xml:    <option type='bool' id='DOT_CLEANUP' defval='1'>
...
```

So Doxygen generates code for configuration variables and probably a
documentation for them as well from these xml definitions, neat.
All I have to do now is to copy a definition of any boolean option
and change it for my needs.

Next I build a fresh Doxygen (`cmake . && make` which produces
`bin/doxygen`) and test it with my new option.

```html
<a href="mailto:amdmi3@amdmi3.ru">amdmi3@amdmi3.ru</a>
```

With that I'm ready to submit a
[pull request](https://github.com/doxygen/doxygen/pull/8989) ([diff](https://github.com/doxygen/doxygen/pull/8989/files?diff=split&w=1) with whitespace disabled which visualizes the changes) which gets accepted in [FIXME].

> **Note to self**: before submitting a PR, check a code style of
> project you're contributing to and make sure your changes conform
> to it.
