# A Worked Example

**Scope:** one small generic server — it serves
a website, takes SSH logins, and exposes a
metrics endpoint to the local network — taken
from no firewall to a finished default-deny
posture. The whole thing ships as
`examples/firewall-setup.sh`; this chapter is
the script with its reasoning attached, and
every command output below is a real capture
from running the steps on the build machine,
except the two that only exist on a running
firewall — `enable`'s confirmation and the
final active listing — which are (documented)
and marked.

The machine: Ubuntu with UFW 0.36.2, one
network card, LAN `192.168.1.0/24`. Nothing
listens yet except SSH. The plan, using
chapter 6's question — *does the world need
this door, or the building?*:

| Service | Port | Who may reach it |
|---------|------|------------------|
| SSH | 22/tcp | anyone, rate-limited |
| Web | 80, 443/tcp | anyone |
| Metrics | 9100/tcp | the LAN only |
| everything else | — | nobody (default) |

## Step 1 — the defaults

Posture first, while nothing can go wrong:

```
$ sudo ufw default deny incoming
Default incoming policy changed to 'deny'
(be sure to update your rules accordingly)
$ sudo ufw default allow outgoing
Default outgoing policy changed to 'allow'
(be sure to update your rules accordingly)
```

These write `/etc/default/ufw`; the running
kernel won't see them until enable. The
parenthetical nag is UFW being right: a default
is only as good as the rules above it.

## Step 2 — the door you're standing in

Chapter 4's drill, before anything else can be
locked:

```
$ sudo ufw limit 22/tcp
```

On an ordinary Ubuntu machine this answers
"Rule added / Rule added (v6)". On the build
machine it answered with the `recent`-match
refusal quoted in chapter 7 — the one step of
this example that box could not perform, and
the script carries the command anyway, because
on your server it's the right one. SSH is
allowed (a `limit` is an allow with a
turnstile), from anywhere, because an admin's
address is the thing you can't predict in an
emergency; the rate limit is what makes
"anywhere" acceptable.

## Step 3 — the public doors

```
$ sudo ufw allow 80/tcp
Rules updated
Rules updated (v6)
$ sudo ufw allow 443/tcp
Rules updated
Rules updated (v6)
```

## Step 4 — the building's door

```
$ sudo ufw allow from 192.168.1.0/24 to any port 9100 proto tcp
Rules updated
```

One message, not two (chapter 6: a named IPv4
subnet makes an IPv4-only rule). From the
street, port 9100 does not exist.

## Step 5 — logging

```
$ sudo ufw logging on
Logging enabled
```

Low level: blocked-by-policy packets, logged
with the `[UFW BLOCK]` prefix, self-throttled.

## Step 6 — prove the notebook

Before the point of no return, read back what
was recorded:

```
$ sudo ufw show added
Added user rules (see 'ufw status' for running firewall):
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow from 192.168.1.0/24 to any port 9100 proto tcp
```

(plus, on a kernel that supports it, the
`ufw limit 22/tcp` line the build machine
couldn't record). If this list isn't the plan
from the table, fix it now — deleting is cheap
(chapter 4) and will not get cheaper.

## Step 7 — enable, and prove the door

(Documented — chapter 4 has the full drill,
including keeping the first session open:)

```
$ sudo ufw enable
Command may disrupt existing ssh connections. Proceed with operation (y|n)? y
Firewall is active and enabled on system startup
```

Then, from a **new** SSH session, the final
listing (documented):

```
$ sudo ufw status numbered
Status: active

     To                         Action      From
     --                         ------      ----
[ 1] 22/tcp                     LIMIT       Anywhere
[ 2] 80/tcp                     ALLOW       Anywhere
[ 3] 443/tcp                    ALLOW       Anywhere
[ 4] 9100/tcp                   ALLOW       192.168.1.0/24
[ 5] 22/tcp (v6)                LIMIT       Anywhere (v6)
[ 6] 80/tcp (v6)                 ALLOW       Anywhere (v6)
[ 7] 443/tcp (v6)                ALLOW       Anywhere (v6)
```

Four intentions became seven rules — the v6
twins of chapter 9 — and the metrics door
carries its subnet in the `From` column, the
only line in the list that isn't `Anywhere`
among the allows it should be. That's the
audit in one glance, and it's the state the
script leaves your server in: reboot-safe,
because `ENABLED=yes` now sits in `ufw.conf`
and the rules reload at boot from the files in
`/etc/ufw/`.

Check: your run is done when a fresh SSH login
works, the website answers from outside, the
metrics port answers from a LAN machine and
times out from an external one, and
`ufw status numbered` reads like the table at
the top of this chapter — intentions down the
left, in order.
