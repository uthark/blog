---
categories:
- extension
- delicious
- howto
- chromium
- article
- development
date: 2009-11-14T22:34:00Z
title: Расширение Delicious Bookmarks для Google Chrome/Chromium
url: /2009/11/14/delicious-bookmarks-google/
---


<h1>Введение</h1><br />
Решил научиться писать собственные расширения для <a href="http://www.google.com/chrome">Google Chrome</a>/<a href="http://www.chromium.org/">Chromium</a>.<br />
<br />
За идею взял официальное расширение от <a href="http://m.www.yahoo.com/">Yahoo!</a> для <a href="http://www.mozilla.com/en-US/firefox/firefox.html">Firefox</a> - <a href="https://addons.mozilla.org/en-US/firefox/addon/3615">Delicious Bookmarks</a>.<br />
<br />
<h1>Структура расширения</h1><br />
Расширение - файл с расширением <tt>.crx</tt>. На самом деле это просто <tt>ZIP</tt>-архив с файлом манифеста внутри.<br />
<br />
<h1>Файл манифеста</h1><pre class="brush:js; highlight: [2, 3, 4, 5, 10, 16, 23]">{
"name": "Delicious plugin", // 1
"version": "0.2", // 2
"background_page": "background.html", // 3
"permissions": [ // 4
"bookmarks",
"tabs"
],

"browser_action": { // 5
"name": "Save bookmark to delicious.com",
"default_title": "Save bookmark to delicious.com",
"default_icon": "delicious.20.gif" // optional
},

"content_scripts": [ // 6
{
"matches": ["http://*/*", "https://*/*"],
"js": ["getDocumentSelection.js"]
}
],

"options_page": "options.html" // 7
}
</pre><br />
Манифест - файл в формате <a href="http://json.org/">JSON</a>.<br />
<br />
Манифест состоит из следующих частей:<br />
<br />
1. <span style="font-weight:bold;"><tt>name</tt></span> - Имя расширения<br />
2. <span style="font-weight:bold;"><tt>version</tt></span> - Версия расширения<br />
3. <span style="font-weight:bold;"><tt>background_page</tt></span> - основной файл с расширением. Это обычный HTML-файл с разметкой.<br />
4. <span style="font-weight:bold;"><tt>permissions</tt></span> - разрешения для расширения. Указываем, что нам нужен доступ к вкладкам (tabs) и закладкам (bookmarks).<br />
5. <span style="font-weight:bold;"><tt>browser_action</tt></span> - указываем, что нужно отобразить на панели инструментов браузера.<br />
6. <span style="font-weight:bold;"><tt>content_scripts</tt></span> - Для доступа к DOM отображаемой страницы необходимы content scripts, данный блок регистрирует скрипт <tt>getDocumentSelection.js</tt> для всех <tt>http</tt> и <tt>https</tt> страниц.<br />
7. <span style="font-weight:bold;"><tt>options_page</tt></span> - страница с настройками.<br />
<br />
Подробное описание файла манифеста есть <a href="http://code.google.com/chrome/extensions/manifest.html">на официальном сайте</a>. <br />
<br />
<h1>Описание работы расширения</h1><br />
<br />
Расширение работает следующим образом:<br />
1. При клике на значок расширения вызывается обработчик <tt>addBookmark</tt><br />
2. Обработчик открывает коммуникационный порт и отправляет сообщение скрипту содержимого.<br />
3. Скрипт содержимого забирает выделенный текст и отправляет назад расширению выделенный текст.<br />
4. Расширение забирает выделенный текст, определяет настройки сохранения (Private/Public) и вызывает окно сохранения <span style="font-style:italic;">Delicious</span>.<br />
<br />
<h1>Реализация расширения</h1><br />
<br />
<span style="font-weight:bold;">background.html</span>:<br />
<pre class="brush:js; html-script: true">&lt;html&gt;
&lt;head&gt;
&lt;script&nbsp;type=&quot;text/javascript&quot;&gt;
&nbsp;&nbsp;&nbsp;&nbsp;function&nbsp;saveBookmark()&nbsp;{
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;//&nbsp;Send&nbsp;our&nbsp;password&nbsp;to&nbsp;the&nbsp;current&nbsp;tab&nbsp;when&nbsp;clicked.
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;chrome.tabs.getSelected(null,&nbsp;function(tab)&nbsp;{
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;var&nbsp;port&nbsp;=&nbsp;chrome.tabs.connect(tab.id,&nbsp;{
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;name&nbsp;:&nbsp;&quot;deliciousBookmark&quot;
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;});
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;port.postMessage(&nbsp;{
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;action&nbsp;:&nbsp;'getSelection'
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;});
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;});
&nbsp;&nbsp;&nbsp;&nbsp;}

&nbsp;&nbsp;&nbsp;&nbsp;function&nbsp;addBookmark(id,&nbsp;bookmark)&nbsp;{
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;console.log(&quot;added&nbsp;bookmark:&nbsp;&nbsp;&quot;&nbsp;+&nbsp;bookmark);
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;saveBookmark();
&nbsp;&nbsp;&nbsp;&nbsp;}

&nbsp;&nbsp;&nbsp;&nbsp;chrome.bookmarks.onCreated.addListener(addBookmark);
&nbsp;&nbsp;&nbsp;&nbsp;console.log(&quot;Registered&nbsp;listener&quot;);

&nbsp;&nbsp;&nbsp;&nbsp;function&nbsp;getShareStatus()&nbsp;{
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;var&nbsp;markPrivate&nbsp;=&nbsp;localStorage[&quot;markPrivate&quot;];
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;var&nbsp;share&nbsp;=&nbsp;&quot;yes&quot;;
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;if&nbsp;(markPrivate&nbsp;==&nbsp;&quot;true&quot;)&nbsp;{
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;share&nbsp;=&nbsp;&quot;no&quot;;
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;}
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;return&nbsp;share;
&nbsp;&nbsp;&nbsp;&nbsp;}

&nbsp;&nbsp;&nbsp;&nbsp;chrome.extension.onConnect.addListener(function(port)&nbsp;{
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;console.assert(port.name&nbsp;==&nbsp;&quot;deliciousBookmark&quot;);
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;port.onMessage.addListener(function(msg)&nbsp;{
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;var&nbsp;selection&nbsp;=&nbsp;msg.selection;
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;chrome.tabs.getSelected(null,&nbsp;function(tab)&nbsp;{

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;var&nbsp;url&nbsp;=&nbsp;encodeURIComponent(tab.url);

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;if&nbsp;(!url&nbsp;||&nbsp;url&nbsp;===&nbsp;&quot;&quot;)&nbsp;{
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;return;
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;}

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;var&nbsp;title&nbsp;=&nbsp;encodeURIComponent(tab.title);
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;var&nbsp;description&nbsp;=&nbsp;encodeURIComponent(selection);

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;var&nbsp;share&nbsp;=&nbsp;getShareStatus();

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;var&nbsp;f&nbsp;=&nbsp;'http://delicious.com/save?url='&nbsp;+&nbsp;url&nbsp;+&nbsp;'&amp;title='&nbsp;+&nbsp;title&nbsp;+&nbsp;'&amp;notes='&nbsp;+&nbsp;description
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;+&nbsp;'&amp;share='&nbsp;+&nbsp;share&nbsp;+&nbsp;'&amp;v=5&amp;';
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;window.open(f&nbsp;+&nbsp;'noui=1&amp;jump=doclose',&nbsp;'deliciousuiv5',
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;'location=yes,links=no,scrollbars=no,toolbar=no,width=550,height=550');

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;});
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;});
&nbsp;&nbsp;&nbsp;&nbsp;});

&nbsp;&nbsp;&nbsp;&nbsp;chrome.browserAction.onClicked.addListener(saveBookmark);
&lt;/script&gt;
&lt;/head&gt;
&lt;/html&gt;

</pre><br />
<br />
<span style="font-weight:bold;">getDocumentSelection.js</span><br />
<br />
<pre class="brush:js">var port = chrome.extension.connect( {
name : "deliciousBookmark"
});

// Also listen for new channels from the extension for when the button is
// pressed.
chrome.extension.onConnect.addListener(function(port) {
console.assert(port.name == "deliciousBookmark");
port.onMessage.addListener(function(msg) {
if (msg.action == 'getSelection') {
var responsePort = chrome.extension.connect( {
name : "deliciousBookmark"
});
var description = document.getSelection() ? '' + document.getSelection() : '';
responsePort.postMessage( {
selection : description
});
}
});
});


</pre><br />
<br />
<span style="font-weight:bold;">options.html</span><br />
<br />
<pre class="brush:js; html-script: true">&lt;html&gt;
&lt;html&gt;
&lt;head&gt;
&lt;title&gt;Delicious Bookmarks Options&lt;/title&gt;
&lt;/head&gt;
&lt;script type=&quot;text/javascript&quot;&gt;
    // Saves options to localStorage.
    function saveOptions() {
        var share = document.getElementById(&quot;share&quot;);
        localStorage[&quot;markPrivate&quot;] = share.checked;

        // Update status to let user know options were saved.
        var status = document.getElementById(&quot;status&quot;);
        status.innerHTML = &quot;Options Saved.&quot;;
        setTimeout(function() {
            status.innerHTML = &quot;&quot;;
        }, 1500);
    }

    // Restores select box state to saved value from localStorage.
    function restoreOptions() {
        var share = localStorage[&quot;markPrivate&quot;];

        if (!share) {
            return;
        }
        var shareCheckbox = document.getElementById(&quot;share&quot;);

        shareCheckbox.checked = share;
        
    }
&lt;/script&gt;

&lt;body onload=&quot;restoreOptions()&quot;&gt;

&lt;label for=&quot;share&quot;&gt;Mark as Private&lt;/label&gt;
&lt;input type=&quot;checkbox&quot; class=&quot;checkbox&quot; name=&quot;share&quot; id=&quot;share&quot; /&gt;


&lt;br&gt;
&lt;button onclick=&quot;saveOptions();&quot;&gt;Save&lt;/button&gt;
&lt;div id=&quot;status&quot;&gt;&amp;nbsp;&lt;/div&gt;
&lt;/body&gt;
&lt;/html&gt;
</pre><br />
<br />
<h1>Сборка расширения</h1><br />
В Chromium есть возможность собрать расширение.<br />
1. Открываем адрес <tt>chrome://extensions/</tt><br />
2. В правом верхнем углу нажимаем Developer Mode.<br />
3. На появившейся панели инструментов кликаем Pack Extension<br />
4. Выбираем каталог, в котором находится расширение<br />
5. Chromium автоматически собирает расширение в каталоге с исходниками расширения.<br />
<br />
<h1>Заключение</h1><br />
Писать расширения для Google Chrome не просто, а очень просто. <br />
<br />
Готовое и собранное расширение можно <a href="http://bit.ly/2KYnr8">скачать здесь</a>.<br />
<br />
<h1>Дополнительная информация</h1><br />
<ol><li><a href="http://code.google.com/chrome/extensions/devguide.html">Google Chrome Extensions Developer's Guide</a></li>
<li><a href="http://code.google.com/chrome/extensions/manifest.html">Manifest file description</a></li>
<li><a href="http://code.google.com/chrome/extensions/api_index.html">Chrome Extensions API</a></li>
<li><a href="http://code.google.com/chrome/extensions/packaging.html">Extension Packaging</a></li>
</ol><br />
<br />
В следующей заметке опишу работу messaging для коммуникации расширения со скриптами содержимого.