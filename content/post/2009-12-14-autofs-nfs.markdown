---
categories:
- article
- autofs
- linux
- howto
- nfs
date: 2009-12-14T23:14:00Z
title: Настройка autofs для монтирования NFS-ресурсов
url: /2009/12/14/autofs-nfs/
---


Summary: В данной заметке описана настройка autofs для доступа к сетевым ресурсам, доступным по NFS.<br />
<br />
Последние несколько лет (с тех пор, как количество компьютеров дома стало больше одного) возникла проблема беспрепятственного доступа к данным, хранящимся на одном компьютере с другого.<br />
<br />
Было найдено самое простое решение - <a href="http://en.wikipedia.org/wiki/Network_File_System_(protocol)">NFS</a>.<br />
<br />
Как выяснилось позже это было не самое удачное решение - ноутбук не всегда находился дома, а, значит, домашние сетевые ресурсы не всегда доступны. Соответственно, при загрузке операционной системы происходили задержки из-за поиска компьютера с сетевыми ресурсами. Не очень удобно, но жить можно.<br />
<br />
Решил окончательно разобраться с этим и начал искать решение. Оно оказалось на поверхности и затронуло только клиента ресурсов, то есть ноутбук. Решение называется <tt><a href="http://www.autofs.org/">autofs</a></tt>.<br />
<br />
1. Устанавливаем <tt>autofs</tt>.<br />
<pre class="brush: bash">sudo aptitude install autofs5 nfs-common
</pre><br />
2. Производим настройку.<br />
Редактируем файл <tt>/etc/auto.master</tt>. Расскомментируем строку, содержащую строки <tt>/net -hosts</tt>:<br />
<pre class="brush: bash">/net -hosts
+auto.master
</pre><br />
3. В файл <tt><a href="http://en.wikipedia.org/wiki/Hosts_file">/etc/hosts</a></tt> можно внести адреса серверов с NFS-ресурсами (для того, чтобы избежать <a href="http://en.wikipedia.org/wiki/Domain_Name_System">DNS</a>-запросов). В моём случае:<br />
<pre class="brush: plain">192.168.18.1 server
</pre><br />
4. Перезапускаем сервис <tt>autofs</tt><br />
<pre class="brush: plain">sudo service autofs restart
</pre><br />
5. Теперь открываем в файловом браузер адрес <tt>/net/server</tt> и видим его сетевые ресурсы, доступные для данного клиента.<br />
<br />
<div class="separator" style="clear: both; text-align: center;"><a href="http://2.bp.blogspot.com/_y8p0_dtMJ38/SyZxDikTDxI/AAAAAAAAAvk/LTr3KsGATGk/s1600-h/Screenshot-media+-+administrilo+de+dosieroj.png" imageanchor="1" style="margin-left: 1em; margin-right: 1em;"><img border="0" src="http://2.bp.blogspot.com/_y8p0_dtMJ38/SyZxDikTDxI/AAAAAAAAAvk/LTr3KsGATGk/s320/Screenshot-media+-+administrilo+de+dosieroj.png" /></a><br />
</div><br />
6. Пользуемся.
