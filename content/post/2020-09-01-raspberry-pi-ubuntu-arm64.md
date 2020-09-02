---
title: "Configuring Wi-Fi on Ubuntu Server 64-bit on Raspberry Pi 4"
date: 2020-09-02T09:19:21-07:00
draft: false
toc: false
comments: false
categories:
- raspberrypi
- ubuntu
- arm64
tags:
- ubuntu
- wpa_supplicant
- netplan
- wi-fi
---

After discovering that by default Raspberry installs 32-bit OS, I wanted to reinstall 64 bit.

Decided to go with [Ubuntu Server 64](https://ubuntu.com/download/raspberry-pi).

Installed it on SD Card with [Raspberry Pi Imager](https://www.raspberrypi.org/downloads/).

After boot found out that need to connect it to WI-FI.

Configuring `wpa_supplicant` didn't help, still had issues with not getting IP Address from DHCP.

Finally, did the following:
1. Create `/etc/netplan/01-netcfg.yaml` and put the following content there:
    
    ```
    network:
	  version: 2
	  renderer: networkd
	  wifis:
	    wlan0:
	      dhcp4: true
	      dhcp6: true
	      optional: true
	      access-points:
	        "<replace with your wifi network name/SSID>":
	          password: "<replace with your password>"
    ```
2. Change permissions to make file accessible only to `root` user:
    ```
    chmod 600 /etc/netplan/01-netcfg.yaml
    ```
3. Configure [Linux wireless central regulatory domain agent](https://linux.die.net/man/8/crda). Put your country code in `/etc/default/crda`
   ```
   REGDOMAIN=US
   ```
4. After that, need to generate and apply netplan:
   ```
   sudo netplan --debug generate
   sudo netplan --debug apply
   ```
<!--more-->
