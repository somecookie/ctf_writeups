+++
title = "Dogcat"
date =  2020-06-10T18:31:05+02:00
author = "Somecookie"
description = "Dogcat - I made a website where you can look at pictures of dogs and/or cats!"
tags = ["php","lfi","docker","security","tryHackMe","CTF","medium"]
cover="img/dogcat/banner.png"
+++

## I made a website where you can look at pictures of dogs and/or cats!

Hello everyone! Today for my first write let's pawn the box [dogcat](https://tryhackme.com/room/dogcat) on TryHackMe! The difficulty of the box is medium. It took me a quite a lot of time to solve it but I learn a lot during the process! I had to first solve the [LFI basics](https://tryhackme.com/room/lfibasics) room to understand how to solve this one. So let's dive into the challenge.

### Enumerate

As for most challenge I started by running nmap to find the services that can be used to access the server.

{{< image src="/img/dogcat/nmap.png" alt="Hello Friend" position="center" style="border-radius: 8px;" >}}

SSH is open and a website is accessible!

### Let's see some dogs and cats!

Let's see the website.

{{< image src="/img/dogcat/index.png" alt="Hello Friend" position="center" style="border-radius: 8px;" >}}

Ok...that's probably the website referred as the subtitle of the challenge...I want to see a cute dog let's click on the dog button! 

{{< image src="/img/dogcat/dog.png" alt="Hello Friend" position="center" style="border-radius: 8px;" >}}

What a beautiful dog...but...did you also notice something weird? The URL! It changed and we can pass something as the parameter view of the GET request! Let's change it to cat...yeah...an ugly cat appeared, let's not show that here... It smells like local file injection! Let's change view to index.php...nope only dogs or cats are allowed...

After a few trials I found out that you can bypass that by...simply adding the word cat or dog in the url...but we still get an error and the a .php seems to be added to our input...

{{< image src="/img/dogcat/error.png" alt="Hello Friend" position="center" style="border-radius: 8px;" >}}

On the bright side we learn that the php script that handles our request is:

```text
/var/www/html/index.php
```

This php extension thingy is really annoying...It's google time! Let's see how we can bypass that. The answer is php filter! We can leverage that to see the source code of index.php!

```text
php://filter/convert.base64-encode/resource=index
```

Gives us a base64 encoded string. Once decoded we have the source code! 

{{< image src="/img/dogcat/index_html.png" alt="Hello Friend" position="center" style="border-radius: 8px;" >}}

Oh! we can use the ext parameter in the GET request to choose the extension! We can set it to the empty string and not be bothered by it anymore!

### It's time to poison the log!

That's the part that took me ages...not because it is difficult but because I had no idea you could do that! It's at this point that I did the LFI basics room and then it became much clearer for me...

Basically we want to write something to the log of the apache server and then get the log hoping that this something gets executed! After a bit of googling and with the help of the nmap recognition we did earlier, we located the log at:

```text
/var/log/apache2/access.log
```

{{< image src="/img/dogcat/log.png" alt="Hello Friend" position="center" style="border-radius: 8px;" >}}

We notice that the user-agent (typically Mozilla/5.0) of the GET request is written to the log. We can leverage that to execute arbitrary code!

You can use Burp to modify the user-agent in the request but I preferred to write a small python script for that...[don't be a script kiddie](https://www.youtube.com/channel/UClcE-kVhqyiHCcjYwcpfj9w)! 

{{< image src="/img/dogcat/lfi_py.png" alt="Hello Friend" position="center" style="border-radius: 8px;" >}}

The key is line 6. We set the user-agent to a php script that gets the cmd parameter of a get request and execute it. You can now call any system command through the cmd parameter and it gets executed! To check that everything is working let's run ls 

{{< image src="/img/dogcat/ls.png" alt="Hello Friend" position="center" style="border-radius: 8px;" >}}

Do you also see it? It's the first flag ever found on this blog!

### Reverse that shell!

We can execute code, let's get a reverse shell! [Pentest monkey](http://pentestmonkey.net/cheat-sheet/shells/reverse-shell-cheat-sheet) is your friend!. Let's open a listener with netcat and try the one-liner for the php reverse shell. After trying almost all one-liner I gave up, let's spawn an http server and download a [perl reverse shell](http://pentestmonkey.net/tools/web-shells/perl-reverse-shell) from it.

{{< image src="/img/dogcat/get_shell.png" alt="Hello Friend" position="center" style="border-radius: 8px;" >}}

I can now execute it through the cmd argument and get my shell!

### Go root or go home!

Normally I would start with some enumeration with linpeas but sudo -l just gave us all we need! 

{{< image src="/img/dogcat/sudo.png" alt="Hello Friend" position="center" style="border-radius: 8px;" >}}

We can execute env as root without password! We are one search on [GTFOBins](https://gtfobins.github.io/) away from root! As expected we found everything we need and are now root! 

{{< image src="/img/dogcat/root.png" alt="Hello Friend" position="center" style="border-radius: 8px;" >}}

We own the server, let's find the flags and burn the server to the ground! 

{{< image src="/img/dogcat/flags.png" alt="Hello Friend" position="center" style="border-radius: 8px;" >}}

Wait...what...where is the 4th flag???!

### Get away from docker!

At this point I was lost! I had no idea what to do...until I remember the keywords of the room...docker...we need to escape! If you didn't notice the keywords you still had a chance to find out thanks the random hostname, the .dockerenv and the 3rd flag!

Cool we know we are in a container and now what? I searched a lot and didn't find anything interesting. I decided to look around on the server and see if I found something peculiar...

{{< image src="/img/dogcat/backup.png" alt="Hello Friend" position="center" style="border-radius: 8px;" >}}

What's that backup folder? Oh and there is a script in it? Bingo that's our way out! backup.sh is probably run periodically to do...backups things... Let's put a (bash this time) reverse shell in it and get out of the container!

{{< image src="/img/dogcat/flag4.png" alt="Hello Friend" position="center" style="border-radius: 8px;" >}}

We found the last flag! Our first CTF solved together! What an emotional moment...Now it's fork bomb time! 