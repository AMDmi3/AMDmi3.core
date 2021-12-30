---
title: "Contribution Story: Adding an Option to Doxygen"
date: 2021-12-30T16:40:44+03:00
---

I use [Doxygen](https://www.doxygen.nl/index.html) to generate
[documentation](https://sdl2pp.amdmi3.ru/) for a library I maintain,
[libSDL2pp](https://github.com/libSDL2pp/libSDL2pp). One day I've
been looking the generated documentation through and my eye was
caught by what supposed to be my email address, which was obfuscated
beyond recognition. Email obfuscation is absolutely not what I
wanted, and Doxygen had no way to disable this behavior, so I've
decided to implement one.

<!-- more -->

Here's how it looked in the generated HTML:

{{< img src="obfuscation.png" size="547x77" >}}

Code (formatted for readability):

```html
<a href="#" onclick="location.href='mai'+'lto:'+'amd'+'mi'+'3@a'+'md'+'mi3'+'.r'+'u'; return false;">
	amdmi<span style="display: none;">.nosp@m.</span>3@am<span style="display: none;">.nosp@m.</span>dmi3.<span style="display: none;">.nosp@m.</span>ru
</a>
```

> **NB**: I didn't notice right away that these `<span>`s were supposed
> to be invisible, but that didn't work because of
> [Content-Security-Policy](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Security-Policy)
> HTTP header I use on my servers, which forbid embedded styles.
> That's another Doxygen problem to
> [fix](https://github.com/doxygen/doxygen/pull/8992).

That's some badass obfuscation! But I don't need it.
- I want my email to be readable as text, and `mailto:` link to be
  valid, even for these who have javascript disabled.
- I see spam problem as mostly fictional nowadays, for instance I
  have my email published verbatim on hundreds of sites, and I'm
  not using any spam filters, yet I'm not getting any intolerable
  amount of spam.
- Because my email is published verbatim on so many sites, obfuscating
  it on a single one doesn't change a thing anyway.

So, let's teach Doxygen to not mangle my email.

First, I need to find a place in the Doxygen code which does the obfuscation,
and that's straightforward, I just look for the text from the inserted garbage:

```
% git clone https://github.com/doxygen/doxygen/ .
% grep -R nosp@m . 
./src/htmldocvisitor.cpp:      if (*p) m_t << "<span style=\"display: none;\">.nosp@m.</span>";
```

That gets us into a function which, as the name suggests, handles
URLs somehow:

{{< highlight "c++" "linenos=inline,linenostart=375" >}}
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

You don't really have to grasp the obfuscation algorithm, it's just
enough to realize that this function gets an URL (which is email
address in our case) in the `url` argument, indeed inserts `<span>`s
with garbage into it, and outputs HTML code into `m_t` stream. One
may also notice that URL is as well passed to
`writeObfuscatedMailAddress()` which outputs a hypertext link tag
(`<a href="mailto:...">`) and obfuscates mail address there as well.

So all I need now is to wrap these two instances of obfuscation
code in `if`'s which check a configuration option, and write verbatim
URLs in `else` branches.

But before I do that I need to define a new option and I need to
know how to access it from the code. For the latter, I've tried
searching for `[Cc]onfig` in the same source file, and that returned
an useful example right away: `Config_getBool(DOT_CLEANUP)`.  Then
I've grepped `DOT_CLEANUP` through Doxygen sources to find where
it is defined. I'd expect a `#define` or `enum` value in some header
file, but in this case it was an .xml instead:

```
% grep -R DOT_CLEANUP .
...
./src/config.xml:    <option type='bool' id='DOT_CLEANUP' defval='1'>
...
```

So Doxygen generates code for configuration options and probably a
documentation for them as well from these xml definitions, neat.
All I have to do now is to copy a definition of any boolean option
and change it for my needs.

Finally I've build a fresh Doxygen (`cmake . && cmake --build .`
which produces `bin/doxygen`) and tested it with my new option. As
expected, the obfuscation was disabled:

```html
<a href="mailto:amdmi3@amdmi3.ru">amdmi3@amdmi3.ru</a>
```

With that I was ready to submit a
[pull request](https://github.com/doxygen/doxygen/pull/8989)
(simplified [diff](https://github.com/doxygen/doxygen/pull/8989/files?diff=split&w=1))
which got accepted the next day.

> **Note to self**: before submitting a PR, check a code style of a
> project you're contributing to and make sure your changes conform
> to it.
