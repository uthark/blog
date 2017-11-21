---
categories:
- delicious
- opera
date: 2009-07-04T01:13:00Z
title: Opera и del.icio.us
url: /2009/07/04/opera-delicious/
---

Так получилось, что в последнее время я стал пользоваться небезызвестной <a href="http://www.opera.com">оперой</a>.

В связи с этим я стал искать замену часто используемым расширениям, одно из них - delicious bookmarks. Сервис <a href="http://delicious.com">del.icio.us</a> предоставляет букмарклеты для различных браузеров, которые позволяют сохранять закладки быстро и удобно. Вот только есть один недостаток - <a href="https://addons.mozilla.org/en-US/firefox/addon/3615">официальный плагин для Firefox</a> в свойство Notes новой закладки добавляет выделенный текст со страницы, чего букмарклет не делает.

Посмотрев исходник букмарклета, а это обычный javascript, я добавил небольшой кусочек кода, который восстанавливает справедливость и тоже добавляет в поле Notes текст, выделенный на странице.

Ниже привожу изменённый код букмарклета:
```js
javascript:(function(){f='http://delicious.com/save?url='+encodeURIComponent(window.location.href)+'&title='+encodeURIComponent(document.title)+'&notes='+encodeURIComponent(document.getSelection())+'&v=5&';a=function(){if(!window.open(f+'noui=1&jump=doclose','deliciousuiv5','location=yes,links=no,scrollbars=no,toolbar=no,width=550,height=550'))location.href=f+'jump=yes'};if(/Firefox/.test(navigator.userAgent)){setTimeout(a,0)}else{a()}})()
```

