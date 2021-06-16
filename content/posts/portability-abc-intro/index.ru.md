---
title: "Азбука переносимости: введение"
date: 2021-05-29T19:16:05+03:00
---

> Как и [обещал]({{< ref "/posts/about-this-blog" >}}), начинаю
> серию постов по переносимости свободного ПО, которую когда-нибудь
> соберу в что-то типа энциклопедии.

Уже без малого 15 лет я занимаюсь созданием и поддержкой портов
FreeBSD, и с сожалением вынужден констатировать что сложность
создания портов/пакетов свободного ПО за это время значительно не
уменьшилась. В чем причина?

<!--more-->

Ведь, с одной стороны, во FreeBSD активно развивается сам фреймворк
портов, появляются новые инструменты, улучшается `pkg`. С другой,
в СПО мире появляются качественные инструменты сборки, улучшается
взаимодействие между разработчиками и мантейнерами, упрощается приём
изменений в апстрим, растёт число независимых пакетных репозиториев
(а значит, потенциальных источников этих изменений). Но несмотря
на это всё ещё нельзя просто взять и написать сценарий сборки пакета
в виде минимального набора необходимых атрибутов:

- Название пакета
- Версия
- URL дистрибутива с исходниками
- Список зависимостей
- Тип системы сборки

Серьёзно, я пока не встречал ни одного проекта которому бы этого
хватило. Обязательно понадобится что-то изменить, что-то пропатчить,
добавить или убрать каких-то флагов, что-то доставить руками.
И всё бы ничего если бы требовались только FreeBSD-специфичные
изменения - всё-таки система во многих местах отличается от
мейнстримного Linux под которым пишут софт, но большинство проблем
никак не связаны с FreeBSD, и упомянуты в том числе в гайдлайнах
по пакетированию основных дистрибутивов Linux.

Вывод напрашивается простой - несмотря на улучшение инструментов в
сообществе пока не появилось культуры оформления проектов,
репозиториев с кодом и сценариев сборки, равно как и представления
о различиях между системой автора и целевыми системами и понимания
требований возникающих при создании пакетов.

Попытаюсь использовать накопленный за эти 15 лет опыт чтобы улучшить
ситуацию, задокументировав частые заблуждения и ошибки, ухудшающие
переносимость ПО и мешающие опакечиванию.