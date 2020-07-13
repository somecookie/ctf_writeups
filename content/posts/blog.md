+++
title = "Blog"
date = 2020-07-13T17:08:40+02:00
author = "Somecookie"
description = "Blog - Billy Joel made a Wordpress blog!"
tags = ["cve-2019-8943","wordpress","blog","web","tryHackMe","CTF","medium"]
cover="img/blog/blog.png"
+++

Hello friend! Long time no see. I'm back for some [Try Hack Me](https://tryhackme.com/) challenge! This time I'm going to solve the challenge [Blog](https://tryhackme.com/room/blog). This is a medium room. Except for the privesc, this was not to difficult to solve. Still a fun room to do! Let's go!

## What do we do first? NMAP!

As always, let's first scan the the ports with `nmap`

{{< image src="/img/blog/nmap.png" alt="Hello Friend" position="center" style="border-radius: 8px;" >}}

Three services are running: `ssh`, `webserver` and `samba`. I'll let you go, on your own, deep down the rabbit hole that is samba and I will start with the webserver!

## Wordpress 5.oups

This is simply `Billy Joel's IT Blog` powered by `Wordpress 5.0`.

{{< image src="/img/blog/wp-home.png" alt="Hello Friend" position="center" style="border-radius: 8px;" >}}

Mmh 5.0 seems old...let's see if we find an exploit for it! For this we can use `searchsploit`.

{{< image src="/img/blog/ssploit.png" alt="Hello Friend" position="center" style="border-radius: 8px;" >}}

Bingo! We have at least two exploits at our disposal to gain access to the server! Let's start with the second one using `metasploit`!

### Metasploit first take

Let's search for it...wah 207 results! Way too much garbage results... The one we are looking for is the 95th!

{{< image src="/img/blog/search.png" alt="Hello Friend" position="center" style="border-radius: 8px;" >}}

Let's see the options we need to exploit the blog.

{{< image src="/img/blog/metasploit1.png" alt="Hello Friend" position="center" style="border-radius: 8px;" >}}

Oh...we need an username and a password...we have neither...it's time to go back to the blog to gather more information.

### We also need to scan the blog??!

Since the blog uses Wordpress we can use `wpscan` to enumerate it. We find out two users!

{{< image src="/img/blog/users.png" alt="Hello Friend" position="center" style="border-radius: 8px;" >}}

That's a good start but it is not enough. We still need a password. Let's invoke a mystical creature...`The Hydra of Lerna`!

### Brute-force, brute-force, brute-force

Let's start with Billy's mother...why? Glad you ask! Simply...because it may not work with Billy (I quit after 20 minutes). Before we use `hydra`, let's look at the login page.

{{< image src="/img/blog/login.png" alt="Hello Friend" position="center" style="border-radius: 8px;" >}}

It's a classical wordpress login page. It even tells us that the user we will brute-force exists...how lovely! Let's capture the requests and run `hydra`.

{{< image src="/img/blog/post.png" alt="Hello Friend" position="center" style="border-radius: 8px;" >}}

This is a `POST` request. We can grab the `request body` and use it with `hydra`!

{{< image src="/img/blog/hydra.png" alt="Hello Friend" position="center" style="border-radius: 8px;" >}}

Yeah a password!

### Metasploit second take

{{< image src="/img/blog/metasploit2.png" alt="Hello Friend" position="center" style="border-radius: 8px;" >}}

We got a shell! It's privEsc time!

## Little detour

Before we try to root the box, let's make a little detour that might be useful for another time!

Let's imagine you already have gained access to the server with some reverse shell of any kind. You get this really annoying shell where you cannot make any mistake, you cannot use `CTRL+C` without breaking it, you don't get any auto-completion etc. 

{{< image src="/img/blog/shell1.png" alt="Hello Friend" position="center" style="border-radius: 8px;" >}}

If `python` is available, the first thing you want to do is to spawn a bash shell and then set the `TERM` environnement variable.

{{< image src="/img/blog/shell2.png" alt="Hello Friend" position="center" style="border-radius: 8px;" >}}

This shell is already better, but now it is when the magic happens! Press `CTRL+Z`. This put the shell in the background and type the command `stty raw -echo;fg`. You get your shell back, but now you have a full interactive experience!

## Cute little peas

We gained access, now we have to get better privileges. Let's upload [linpeas](https://github.com/carlospolop/privilege-escalation-awesome-scripts-suite/blob/master/linPEAS/linpeas.sh) to `/dev/shm` and run it! Since we have a `meterpreter` shell you can simply use the command `upload linpeas.sh` to do so. Let's run it! This will enumerate the server and point out the things that are odd. 

### Loosing patience and time

At this point I spent a few hours to find out what was wrong with the server! First thing I did was to go to `/home/bjoel` to get the `user.txt` flag and maybe get some ssh keys.

{{< image src="/img/blog/troll.png" alt="Hello Friend" position="center" style="border-radius: 8px;" >}}

Mmeh I got trolled and no keys were there. Then I tried to look at the `cronjobs`, but again I couldn't exploit anything. Finally, I looked at the exploits for `Apache 2.4.29`. It seems that you there are some exploits to get [root privilege escalation](https://medium.com/@knownsec404team/the-recurrence-of-apache-root-privilege-escalation-cve-2019-0211-1b02fcb31c37). But again I couldn't exploit it...

## Back to the peas

In a last desperate attempt, I went back to linpeas. It was there in front of me this whole time...this weird binary with the `SUID` bit set.

{{< image src="/img/blog/checker.png" alt="Hello Friend" position="center" style="border-radius: 8px;" >}}

I had never heard of this binary. I could not find any information about it on the internet and could not find it on my machine. I tried to run it to see what it does.

{{< image src="/img/blog/checker2.png" alt="Hello Friend" position="center" style="border-radius: 8px;" >}}

YES I KNOW! That's exactly what I am trying to be!

## NSA super cool stuff

I still had no idea what was the purpose of this binary. Therefore, I decided to reverse engineer it using [Ghidra](https://ghidra-sre.org/). I know it is a bit overkilled, I could probably just have used `gdb`, but I wanted to apply the skills I learn with [CC: Ghidra](https://tryhackme.com/room/ccghidra) and [Reversing ELF
](https://tryhackme.com/room/reverselfiles).

{{< image src="/img/blog/main.png" alt="Hello Friend" position="center" style="border-radius: 8px;" >}}

Oh...it was much easier than expected. We simply need to set the environment variable `admin`.

{{< image src="/img/blog/exploit.png" alt="Hello Friend" position="center" style="border-radius: 8px;" >}}

## Get the flags

The root flag was at its expected location. However the `user` flag wasn't. Let's locate it using `find / -name "user.txt"`. 

{{< image src="/img/blog/flags.png" alt="Hello Friend" position="center" style="border-radius: 8px;" >}}

Done!

