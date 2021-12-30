---
title: "История коммита: добавляем новую опцию в Doxygen"
date: 2021-12-30T16:40:44+03:00
---

Я использую [Doxygen](https://www.doxygen.nl/index.html) для генерации
[документации](https://sdl2pp.amdmi3.ru/) для одной из своих
библиотек, [libSDL2pp](https://github.com/libSDL2pp/libSDL2pp).
Однажды, просматривая оную документацию я наткнулся на интересный
факт: мой email в сгенерированном HTML был изменён до неузнаваемости,
очевидно в целях помешать спам-ботам собирать адреса. Меня такое
поведение категорически не устраивало, а в Doxygen не было настройки
чтобы его отключить, поэтому я решил её добавить.

<!-- more -->

Вот так выглядит изменённый email:

{{< img src="obfuscation.png" size="547x77" >}}

То же в HTML (отформатировано для читаемости):

```html
<a href="#" onclick="location.href='mai'+'lto:'+'amd'+'mi'+'3@a'+'md'+'mi3'+'.r'+'u'; return false;">
	amdmi<span style="display: none;">.nosp@m.</span>3@am<span style="display: none;">.nosp@m.</span>dmi3.<span style="display: none;">.nosp@m.</span>ru
</a>
```

> **Отступление**: в начале я как-то не осознал что `<span>`ы вставляемые в
> адрес должны быть невидимы из-за `display: none`, но этот встроенный
> стиль не работал из-за заголовка
> [Content-Security-Policy](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Security-Policy)
> у меня на сервере. Это отдельная проблема в Doxygen которую также
> нужно [исправить](https://github.com/doxygen/doxygen/pull/8992).

Это прямо серьёзная обфускация! Мне, однако, она совершенно не нужна:
- Я хочу чтобы мой email и читался в виде текста, и работал в
  качестве ссылки, даже при отключенном javascript.
- Спам меня не сильно беспокоит, даже при том что мой email
  опубликован в открытом виде на сотнях сайтов и я не использую
  никаких фильтров, поэтому роботов я не боюсь.
- Так как адрес уже опубликован на других сайтах, прятать его на
  каком-то одном вообще не имеет смысла.

Поэтому почему бы, подумал я, не добавить возможность отключить
это поведение Doxygen.

Начнём с того что найдём в коде место ответственное за обфускацию. Для
этого просто поищем по исходникам мусорный текст которые вставляется в
адрес. Нужное место находится сразу:

```
% git clone https://github.com/doxygen/doxygen/ .
% grep -R nosp@m . 
./src/htmldocvisitor.cpp:      if (*p) m_t << "<span style=\"display: none;\">.nosp@m.</span>";
```

Итак, мы в функции которая, судя по названию, как-то обрабатывает
URLы:

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

Тут не нужно вникать в алгоритм обфускации, достаточно осмотреться
и увидеть что нам приходит URL (в нашем случае email) в аргументе
`url`, с ним производятся какие-то манипуляции и результат выводится
в поток `m_t`. Можно заметить что URL передаётся также в функцию
`writeObfuscatedMailAddress()` которая ответственна за вывод
открывающего HTML тэга ссылки (`<a href="mailto:...">`) и также
обфусцирует в нём email адрес.

Нужно просто обернуть код обфускации в этих двух местах в `if`ы
проверяющие соответствующую настройку, в `else` ветках которых
выводить неизменённые адреса.

Осталось добавить опцию и научиться получать её значение из кода.
Для последнего я просто поискал `[Cc]onfig` в том же исходном файле
и сразу получил пример: `Config_getBool(DOT_CLEANUP)`. Теперь можно
найти где определяется `DOT_CLEANUP` (а там же и остальные опции).
Обычно это будет `#define` или `enum` значение в каком-то заголовочном
файле, но в случае Doxygen определение нашлось в .xml:

```
% grep -R DOT_CLEANUP .
...
./src/config.xml:    <option type='bool' id='DOT_CLEANUP' defval='1'>
...
```

Значит Doxygen строит код обработки опций (а скорее всего, и
документацию по ним) из определений в .xml файле - что-ж, удобно.
Добавляем в этот .xml определение новой опции по аналогии с
существующей, хотя бы той-же `DOT_CLEANUP`.

Всё готово, можно собрать Doxygen (`cmake . && cmake --build .`
после чего получим бинарник в `bin/doxygen`) и протестировать новую
опцию. При выключении обфускации сгенерированный HTML выглядит
как ожидается:

```html
<a href="mailto:amdmi3@amdmi3.ru">amdmi3@amdmi3.ru</a>
```

Можно создавать
[пулл реквест](https://github.com/doxygen/doxygen/pull/8989)
(упрощённые [изменения](https://github.com/doxygen/doxygen/pull/8989/files?diff=split&w=1)).

Мои изменения были приняты на следующий день, и должны попасть в
следующий релиз Doxygen `1.9.3`.

> **На будущее**: перед отправкой PR стоит посмотреть на стиль кода
> принятый в проекте и убедиться что изменения ему соответствуют,
> чтобы потом не исправить.
