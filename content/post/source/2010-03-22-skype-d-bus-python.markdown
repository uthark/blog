---
categories:
- article
- skype
- python
- dbus
- разработка
- development
date: 2010-03-22T23:50:00Z
title: Общение со Skype через D-Bus на Python
url: /2010/03/22/skype-d-bus-python/
---

<p><b>Summary</b>: в данной заметке описывается работа с программой Skype через D-Bus на Python.</p>

<h4>Введение</h4>
<p>Захотелось мне странного - когда я ухожу домой, мне нужно выключить amarok, kopete и Skype. Собственно, решено было через D-Bus отправлять вышеперечисленным приложениям релевантные сообщения.</p>

<h4>Используем dbus-send</h4>
<p>Сначала я использовал обычный dbus-send, что оформилось в виде следующего скрипта <tt>go2home</tt>:</p>

```bash
#!/bin/sh

# Stop amarok
dbus-send --session --type=method_call --dest=org.kde.amarok /Player org.freedesktop.MediaPlayer.Stop

# Logout from kopete
dbus-send --session --type=method_call --dest=org.kde.kopete /Kopete org.kde.Kopete.disconnectAll 

# Logout from Skype
skypeapi.py 'SET USERSTATUS OFFLINE'

# Lock screen
dbus-send --session --type=method_call --dest=org.freedesktop.ScreenSaver /ScreenSaver org.freedesktop.ScreenSaver.Lock
```

Детали и параметры работы команды <tt>dbus-send</tt> описаны в <a href="http://dbus.freedesktop.org/doc/dbus-send.1.html">man-странице</a>

<h4>Проблема со скайпом</h4>
<p> Со скайпом пришлось немного повозиться, так как для работы с ним необходима постоянная сессия, что нельзя сделать с помощью <tt>dbus-send</tt>. </p>
<p>Прочитав <a href="https://developer.skype.com/Docs/ApiDoc">описание протокола</a> на сайте </p>
<p> был создан нижеследующий скрипт: skypeapi.py</p>

```Python
#!/usr/bin/env python
import dbus, sys

def main():
    remote_bus = dbus.SessionBus()
    
    # Check if skype is running.
    system_service_list = remote_bus.get_object('org.freedesktop.DBus', '/org/freedesktop/DBus').ListNames()
    skype_api_found = 0
    for service in system_service_list:
        if service=='com.Skype.API':
            skype_api_found = 1
            break
    if not skype_api_found:
        sys.exit('No running API-capable Skype found')

    # Get skype dbus api
    skype_service = remote_bus.get_object('com.Skype.API', '/com/Skype')

    # Connect to skype.
    answer = skype_service.Invoke('NAME SkypeApiClient')
    if answer != 'OK':
        sys.exit('Could not bind to Skype client')

    # Check if protocol is supported.
    answer = skype_service.Invoke('PROTOCOL 1')
    if answer != 'PROTOCOL 1':
        sys.exit('This test program only supports Skype API protocol version 1')

    # Invoke operations
    for arg in sys.argv:
        skype_service.Invoke(arg)
    
    return 0    

if __name__ == &quot;__main__&quot;:
    main()
```

<p> При первом запуске скрипта появится скайповский диалог с вопросом, можно ли разрешить приложению доступ к скайпу. После нажатия на &quot;Да&quot; Skype добавит наш скрипт в разрешённые и мы сможем управлять скайпом.</p>

<a onblur="try {parent.deselectBloggerImageGracefully();} catch(e) {}" href="http://2.bp.blogspot.com/_y8p0_dtMJ38/S6ev4yVZkJI/AAAAAAAAA9Q/O87mz2Qnku0/s1600-h/skype.png"><img style="display:block; margin:0px auto 10px; text-align:center;cursor:pointer; cursor:hand;width: 376px; height: 185px;" src="http://2.bp.blogspot.com/_y8p0_dtMJ38/S6ev4yVZkJI/AAAAAAAAA9Q/O87mz2Qnku0/s400/skype.png" border="0" alt=""id="BLOGGER_PHOTO_ID_5451519264074338450" /></a>

После этого для скрипта <tt>go2home</tt> был создана иконка на панели.

<h4>Заключение</h4>
Как видно, работа с DBus из Python проста и элегантна.

В качестве домашнего упражнения предлагаю написать скрипт, который после разблокирования экрана будет запускать все нужные приложения.
