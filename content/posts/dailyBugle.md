+++
title="DailyBugle"
date=2020-06-10T21:19:10+02:00
author = "Somecookie"
description = "Daily Bugle - Compromise a Joomla CMS account via SQLi, practice cracking hashes and escalate your privileges by taking advantage of yum."
tags = ["joomla","sqli","yum","sqlmap","tryHackMe","CTF","hard","OSCP-learning-path"]
cover="img/dailyBugle/banner.png"
+++

Hello everyone! I'm currently going through the `offensive pentesting` learning path on TryHackMe. So today I'm going to do the [Daily Bugle](https://tryhackme.com/room/dailybugle) room. This a hard room however I found it not that difficult! If you have done the previous rooms of the learning path you should be able to solve it!

## NMAP is your best-friend!

As always I start with `nmap`! 

{{< image src="/img/dailyBugle/nmap.png" alt="Hello Friend" position="center" style="border-radius: 8px;" >}}

There are three open services `SSH`, an `Apache` webserver and a `MariaDB` database. I wanted to try something I learnt in the [Blue](https://tryhackme.com/room/blue) room. `nmap` can run the script `vuln` to detect vulnerabilities on the remote server. Thus I ran a second scan `nmap -sC -sV --script=vuln 10.10.114.124`. I found out two interesting things with this scan, some subdirectories of the webserver

{{< image src="/img/dailyBugle/enum.png" alt="Hello Friend" position="center" style="border-radius: 8px;" >}}

but most importantly, the CMS used, `Joomla! 3.7.0`, is vulnerable!

{{< image src="/img/dailyBugle/joomla.png" alt="Hello Friend" position="center" style="border-radius: 8px;" >}}

## Spidey the thief

Let's access the HORRENDOUS website...

{{< image src="/img/dailyBugle/dailyBugle.png" alt="Hello Friend" position="center" style="border-radius: 8px;" >}}

Okay `Spider-man` robbed a bank...Other than this masterpiece of article, there is nothing interesting on the website. Let's see what we can find on [ExploitDB](https://www.exploit-db.com/exploits/42033) about Joomla 3.7.0.

{{< image src="/img/dailyBugle/sqli.png" alt="Hello Friend" position="center" style="border-radius: 8px;" >}}

The command of the exploit tells us the available databases, let's run it without the `level=5` otherwise I take ages...

```bash
sqlmap -u "http://10.10.34.93/index.php?option=com_fields&view=fields&layout=modal&list[fullordering]=updatexml" --risk=3 --random-agent --dbs -p list[fullordering]

...

available databases [5]:
[*] information_schema
[*] joomla
[*] mysql
[*] performance_schema
[*] test
```

The most interesting database is probably `joomla`, let's find out its tables:

```bash
sqlmap -u "http://10.10.34.93/index.php?option=com_fields&view=fields&layout=modal&list[fullordering]=updatexml" --risk=3 --random-agent --dbs -p list[fullordering] --threads 10 -D joomla --tables
```

mmmh there are 72 tables...I guess `#__users` is the one we want to dump...

```bash
sqlmap -u "http://10.10.34.93/index.php?option=com_fields&view=fields&layout=modal&list[fullordering]=updatexml" --risk=3 --random-agent --dbs -p list[fullordering] --threads 10 -D joomla -T "#__users" --dump
```

Bingo we find a user!

{{< image src="/img/dailyBugle/superuser.png" alt="Hello Friend" position="center" style="border-radius: 8px;" >}}

## Johnny

The password is not in plaintext! That would be too easy. It's hashed with `bcrypt`.
Let's try to brute-force it with our friend `john`:

```bash
sudo john -format=bcrypt --wordlist=/usr/share/wordlists/rockyou.txt hash.txt
```

After a few long minutes we cracked the password! Ah yeah...how surprising...

{{< image src="/img/dailyBugle/jonah.jpg" alt="Hello Friend" position="center" style="border-radius: 8px;" >}}


## The super template!

Since Jonah is the editor-in-chief, he is probably also admin of the website. Let's see if we can connect to the `Administrator` page we found in the `nmap` scan.

{{< image src="/img/dailyBugle/admin.png" alt="Hello Friend" position="center" style="border-radius: 8px;" >}}

It works! After a few minutes looking around I finally found out where I could upload a reverse shell! Directly in the default template `protostar`!

{{< image src="/img/dailyBugle/index.png" alt="Hello Friend" position="center" style="border-radius: 8px;" >}}

Let's get the [reverse shell code](https://github.com/pentestmonkey/php-reverse-shell/blob/master/php-reverse-shell.php), put it in `index.php` with the desired IP address and port. Last thing left to do is to set up a listener with netcat...btw what's your favorite port?

We have a shell! 

{{< image src="/img/dailyBugle/shell.png" alt="Hello Friend" position="center" style="border-radius: 8px;" >}}

But don't be too happy, the user `apache` is...mmeeeh... you can't even access the home directory of the other user `jjameson` where the flag is probably located...

## It's time for the cutest peas in the world!

{{< image src="/img/dailyBugle/peass.png" alt="Hello Friend" position="center" style="border-radius: 8px;" >}}

Let's upload [linpeas](https://github.com/carlospolop/privilege-escalation-awesome-scripts-suite/tree/master/linPEAS) onto the webserver...for example in `/dev/shm` with a simple http server.

{{< image src="/img/dailyBugle/upload.png" alt="Hello Friend" position="center" style="border-radius: 8px;" >}}

There is something odd in the results from linpeas...a password in `/var/www/html/configuration.php`...but for what??!

{{< image src="/img/dailyBugle/pwd.png" alt="Hello Friend" position="center" style="border-radius: 8px;" >}}

## And as always don't forget SSH

I was stuck on this...for ages...I have a username, a password, ssh is open, I wonder what are the links between those...oh...

{{< image src="/img/dailyBugle/facepalm.jpg" alt="Hello Friend" position="center" style="border-radius: 8px;" >}}

I connect with SSH  with the user `jjameson` and the password found by linpeas and BAM it works! Plus I get the `user.txt` flag.

## Not the biggest mountain

Let's first use `sudo -l` to see our permissions:

```bash
[jjameson@dailybugle ~]$ sudo -l
Matching Defaults entries for jjameson on dailybugle:
    !visiblepw, always_set_home, match_group_by_gid, always_query_group_plugin, env_reset, env_keep="COLORS DISPLAY HOSTNAME HISTSIZE KDEDIR LS_COLORS", env_keep+="MAIL PS1 PS2 QTDIR USERNAME LANG LC_ADDRESS LC_CTYPE",
    env_keep+="LC_COLLATE LC_IDENTIFICATION LC_MEASUREMENT LC_MESSAGES", env_keep+="LC_MONETARY LC_NAME LC_NUMERIC LC_PAPER LC_TELEPHONE", env_keep+="LC_TIME LC_ALL LANGUAGE LINGUAS _XKB_CHARSET XAUTHORITY",
    secure_path=/sbin\:/bin\:/usr/sbin\:/usr/bin

User jjameson may run the following commands on dailybugle:
    (ALL) NOPASSWD: /usr/bin/yum

```

We can run `sudo` on `yum` without password! Let's use the exploit found on [GTFOBins](https://gtfobins.github.io/gtfobins/yum/) and spawn a root shell!

{{< image src="/img/dailyBugle/gtfo.png" alt="Hello Friend" position="center" style="border-radius: 8px;" >}}

Simply copy it and...

{{< image src="/img/dailyBugle/root.jpg" alt="Hello Friend" position="center" style="border-radius: 8px;" >}}

As always the root flag is in `/root/root.txt`. We are done! You know what it means...DELETE EVERYTHING!!!

{{< image src="/img/dailyBugle/rm.png" alt="Hello Friend" position="center" style="border-radius: 8px;" >}}