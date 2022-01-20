## BBRF Helper Documentation

## checkProgram [program]

This command is used to check if we already have a program in our database. It is usually used before the **addProgram** command.

Example:

```bash
retr0@retr0:~$ checkProgram att
Program found: ATT
Automattic
Mattermost  
```
As you can see the command returns 3 results:

* ATT
* Automattic
* Mattermost

For our case, the program we wanted to check if it existed was **ATT**.

One advantage of the command is that it is not **case sensitive**, so we don't have to worry about typing the name correctly in upper or lower case. 

Another positive point is that **checkProgram** will not return any program whose name is exactly **att**, but any program that contains **att** in its name. This is good because if we do not remember the exact name of the program, but we know a part of its name, the command will show us the results that contain the **word** that you indicate. 

**( ¡¡¡ You just give the command a hint and it does the rest !!! )**.

## addProgram [(h1/bugcrowd/anything/) author]

This command is used to add a program to the database. The **addPrograms** command receives two parameters:

* The first one is the place where you will report the bugs you find in that program. It can be h1 (hackerone), bugcrowd, intigriti, etc.

* The second is the name of the person who added the program to the database.

Example:

**addProgram h1** (in case we want to add a hackerone program).

ó

**addProgram bugcrowd** (in case we want to add a bugcrowd program)

After that, the command will ask for information about the program:

```bash
retr0@retr0:~$ addPrograms h1
Program name: Test
Reward? (1:money[default:press Enter], 2:points, 3:thanks) 1
Url? https://hackerone.com/test?type=team                                      
Recon?  (1:false, 2:true) 2
Android app?  (1:false[default:press Enter], 2:true) 1
iOS app?  (1:false[default:press Enter], 2:true) 1
Source code?  (1:false[default:press Enter], 2:true) 1
 Add IN scope: 
*.test.com *.test-payment.example.com *.example.com domain.com     
 inscope: 
*.test.com
*.test-payment.example.com
*.example.com
domain.com

 Add OUT scope: noTest.example.com payment.example.com www.test.com
```
Once we have provided the data that **addPrograms** asks for, it will start finding all possible subdomains of the supplied domains, verify that they are alive and that they have an HTTP service enabled and finally return all URLs ready to be audited.

For example, this returns **addPrograms** when we add a program like **Trustpilot**:

```bash
retr0@retr0:~$ addPrograms h1
Program name: Trustpilot
Reward? (1:money[default:press Enter], 2:points, 3:thanks)  1
Url?  https://hackerone.com/trustpilot?type=team                                     
Recon?  (1:false, 2:true) 2
Android app?  (1:false[default:press Enter], 2:true) 1
iOS app?  (1:false[default:press Enter], 2:true) 1
Source code?  (1:false[default:press Enter], 2:true) 1
 Add IN scope: 
*.truspilot.com     
 inscope: 
*.truspilot.com

 Add OUT scope: *.apidoc.trustpilot.com *.apps.trustpilot.com *.press.trustpilot.com *.support.trustpilot.com trustpilot.com

 Running bbrf mode 
 Running subfinder 
[NEW] fr.truspilot.com
[NEW] widget.truspilot.com
[NEW] ns2.truspilot.com
[NEW] mx0.truspilot.com
[NEW] mail9.truspilot.com
[NEW] nl-be.truspilot.com
[NEW] ww11.truspilot.com
[NEW] post.truspilot.com
[NEW] secure.truspilot.com
[NEW] it.truspilot.com
[NEW] mailin.truspilot.com
[NEW] intranet.truspilot.com
[NEW] zmail.truspilot.com
[NEW] trustlytics.truspilot.com
[NEW] ww25.support.truspilot.com
[NEW] smtps.truspilot.com
[NEW] ww25.ww43.truspilot.com
[NEW] mailout.truspilot.com
[NEW] relay.truspilot.com
[NEW] polyfills.truspilot.com
[NEW] ww43.truspilot.com
[NEW] smtp1.truspilot.com
[NEW] www.truspilot.com
[NEW] mailserver.truspilot.com
[NEW] ww11.support.truspilot.com
[NEW] server.truspilot.com
[NEW] mx1.truspilot.com
[NEW] business.truspilot.com
[NEW] support.truspilot.com
[NEW] www2.truspilot.com
[NEW] imap.truspilot.com
[NEW] mail2.truspilot.com
[NEW] ww2.truspilot.com
[NEW] smtp2.truspilot.com
[NEW] imap2.truspilot.com
[NEW] smtp.truspilot.com
[NEW] mail01.truspilot.com
[NEW] ww25.fr.truspilot.com
[NEW] mxs.truspilot.com
[NEW] pop3.truspilot.com
[NEW] ns.truspilot.com
[NEW] ww25.truspilot.com
[NEW] ww25.business.truspilot.com
[NEW] ww25.trustlytics.truspilot.com
[NEW] ww38.truspilot.com
[NEW] ww25.nl-be.truspilot.com
[NEW] uk.truspilot.com
[NEW] ru.truspilot.com
[NEW] es.truspilot.com
 Running assetfinder 
 httpx domains 
[NEW] http://ww25.nl-be.truspilot.com
[NEW] http://ww25.business.truspilot.com
[NEW] https://ww25.trustlytics.truspilot.com
[NEW] http://ww25.fr.truspilot.com
[NEW] https://ww25.support.truspilot.com
[NEW] http://ww25.ww43.truspilot.com
[NEW] http://ww25.truspilot.com
[NEW] https://ns.truspilot.com
[NEW] https://mail2.truspilot.com
[NEW] https://truspilot.com
[NEW] https://mxs.truspilot.com
[NEW] https://mailin.truspilot.com
[NEW] https://smtp2.truspilot.com
[NEW] https://business.truspilot.com
[NEW] https://trustlytics.truspilot.com
[NEW] https://pop3.truspilot.com
[NEW] https://imap.truspilot.com
[NEW] https://support.truspilot.com
[NEW] https://nl-be.truspilot.com
[NEW] https://zmail.truspilot.com
[NEW] https://uk.truspilot.com
[NEW] https://imap2.truspilot.com
[NEW] https://widget.truspilot.com
[NEW] https://post.truspilot.com
[NEW] https://smtp.truspilot.com
[NEW] https://intranet.truspilot.com
[NEW] https://mx1.truspilot.com
[NEW] https://ww11.support.truspilot.com
[NEW] https://server.truspilot.com
[NEW] https://es.truspilot.com
[NEW] https://www.truspilot.com
[NEW] http://ww43.truspilot.com
[NEW] http://ww11.truspilot.com
[NEW] https://ww38.truspilot.com
[NEW] https://www2.truspilot.com
[NEW] https://ru.truspilot.com
[NEW] https://ns2.truspilot.com
[NEW] https://fr.truspilot.com
[NEW] https://secure.truspilot.com
[NEW] https://smtp1.truspilot.com
[NEW] https://it.truspilot.com
[NEW] https://polyfills.truspilot.com
[NEW] https://mailserver.truspilot.com
[NEW] https://mail9.truspilot.com
[NEW] https://mx0.truspilot.com
[NEW] https://smtps.truspilot.com
[NEW] https://ww2.truspilot.com
[NEW] https://relay.truspilot.com
[NEW] https://mailout.truspilot.com
[NEW] https://mail01.truspilot.com
 httprobe domains
```
Note that if **addProgram** finds new URL's it will mark them as [new], but if it finds URL's that were already registered in the database, then it will mark them as [update].

¡¡¡ Now you have a good amount of URL's on which to start looking for errors :sunglasses: !!!

## getDomains ; getUrls

It may happen that you have already entered a program before and now you just want to search again for new domains and valid URL's to audit.

In that case you should do the following:

```bash
retr0@retr0:~$ checkProgram spotify
Program found: Spotify

bbrf use Spotify

getDomains; getUrls
```

After that you will get new valid domains (if **getDomains** found more) and finally based on those new domains found, **getUrls** will search which ones are alive and have a HTTP service running to return all valid URL's ready to be audited.

Now you are probably wondering several things, so I will proceed to explain:

1. Where does **getDomains** get the domains from if I haven't entered them ?

Well, as I told you, we don't need to do an **addProgram** because the domains are already in the database.

2. When did this happen ?

It happened when you entered the program for the first time. If you remember, one of the values that **addPrograms** asks for when you enter a program is **in Scope**, which is basically all the domains for which you then want to search for subdomains to expand your attack surface.

But what if for some reason you find out that a new website has just been set up at example.com, you're not going to do the addProgram again, right? In that case, just follow the steps I described above to use the **getDomains ; getUrls** commands and ¡¡¡ you're done !!!

3. Why should we use **bbrf use [program]** when we don't use addProgram ?

Well, **addProgram** is kind and internally takes care of defining the program you specify, as the **current/active** program to work on.

When you create a program it internally takes care of this. On the other hand, if you do not use it, there is nothing to do it for you, you must manually execute the instruction **bbrf use [program]** to establish this **program** as the **current/active** program to work on.

This is why when we use **getDomains ; getUrls** we do not specify a program on which to search for new domains, since these commands will automatically act on the program that was defined as the **current/active** one.

If you want to see where this configuration is stored when we do a **bbrf use [program]**, you can use the following command:

```bash
cat ~/.bbrf/config.json
```

And in the response of that command look at the **program** key, that is the **current/active** program that **getDomains** and **getUrls** will work on.

```
{"username": "obfuscate", "password": "obfuscate", "couchdb": "https://example.com:4444/bbrf", "slack_token": "", "program": "Spotify", "ignore_ssl_errors": "true", "debug": false}
```

## findProgram [domain/URL]

The **findProgram** command is useful at times when you can't remember the name of a program for whatever reason. Imagine you enter a program into the database and mistakenly give it the wrong name. 

Then you want to fix it but you don't remember what was the name you gave to the program, but you remember some domain or URL that was found when you added the program.

Well this is more than enough for **findProgram**, if you enter a domain or URL belonging to that program, **findProgram** will return the program!!!

Example:

```bash
retr0@retr0:~$ findProgram spotify.com
"h1, Spotify, money, https://hackerone.com/spotify?type=team, disabled:false, recon:false, source code: null"
retr0@retr0:~$ findProgram https://hrblog.spotify.com
"h1, Spotify, money, https://hackerone.com/spotify?type=team, disabled:false, recon:false, source code: null"
```

¡¡¡ Great, now we know **Spotify** is the name of the program we were looking for !!!

This was all the documentation for **BBRF Helper**, hope you enjoy the tool :heart:.
