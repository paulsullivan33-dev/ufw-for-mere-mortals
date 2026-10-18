# Reading Your Firewall

A firewall you can't read back is a rumor.
UFW gives you three views of the same truth —
what you *asked* for, what it *recorded*, and
what the *kernel is doing* — and most confusion
comes from mixing them up. This chapter takes
them in that order.

## The status family

On a machine where the firewall isn't running,
all three forms agree, and this is a real
capture:

```
$ sudo ufw status
Status: inactive
$ sudo ufw status verbose
Status: inactive
$ sudo ufw status numbered
Status: inactive
```

On a running firewall they diverge (documented
— the canonical forms from UFW's documentation;
the build machine's kernel couldn't host a
running UFW rule set, per the README):

```
$ sudo ufw status
Status: active

To                         Action      From
--                         ------      ----
22/tcp                     LIMIT       Anywhere
80/tcp                     ALLOW       Anywhere
443/tcp                    ALLOW       Anywhere
22/tcp (v6)                LIMIT       Anywhere (v6)
80/tcp (v6)                 ALLOW       Anywhere (v6)
443/tcp (v6)                ALLOW       Anywhere (v6)
```

`status verbose` (documented) adds the header
that gives the listing its context — the parts
you can't infer from rules alone:

```
Status: active
Logging: on (low)
Default: deny (incoming), allow (outgoing), disabled (routed)
New profiles: skip
```

and `status numbered` (documented) prefixes
each rule with the number `ufw delete` wants:

```
     To                         Action      From
     --                         ------      ----
[ 1] 22/tcp                     LIMIT       Anywhere
[ 2] 80/tcp                     ALLOW       Anywhere
```

Read the columns as the sentence they are:
*packets to this, get this action, from these
sources.* The `(v6)` twins are chapter 9.

## What you asked for: `ufw show added`

The recorded commands, in your own words.
Empty, then populated — both real:

```
$ sudo ufw show added
Added user rules (see 'ufw status' for running firewall):
(None)

$ sudo ufw show added
Added user rules (see 'ufw status' for running firewall):
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow from 192.168.1.0/24 to any port 9100 proto tcp
```

This is the view to reach for when a status
listing surprises you: it shows the *intent*,
before translation. It's also the honest view
with the firewall off — the rules above were
recorded on the build machine with UFW
inactive, and `ufw status` said so the whole
time. Recorded is not running; `show added` is
about the notebook, `status` is about the door.

## What the kernel is doing: `show raw` and friends

`ufw show raw` prints the live kernel chains
through iptables, counters and all. The head
of the real output, firewall inactive, kernel
chains empty:

```
$ sudo ufw show raw
IPV4 (raw):
Chain INPUT (policy ACCEPT 0 packets, 0 bytes)
    pkts      bytes target     prot opt in     out     source               destination
```

On a running firewall this is pages long —
UFW's chains (`ufw-user-input` and family)
hang off the built-ins — which is why the
companion reports exist: `ufw show builtins`
(the built-in chains), `ufw show user-rules`
(just UFW's), and `ufw show listening`, which
goes the other way entirely and reports which
*listening services* exist and what rules touch
them. Even their failures are informative
(real, firewall inactive):

```
$ sudo ufw show user-rules
ERROR: IPV4 (user):
iptables: No chain/target/match by that name.
```

No running firewall, no user chains — the
error is the truth, stated plainly. Learn to
like UFW's bluntness; chapter 11 collects more.

## The log

Blocked packets can be logged; the switch is
`ufw logging`, levels `off`, `low`, `medium`,
`high`, `full`, stored as `LOGLEVEL` in
`ufw.conf` (chapter 3). Turning it on, real:

```
$ sudo ufw logging on
Logging enabled
```

`low` logs blocked packets that match no rule
— the policy hits — rate-limited so a scan
can't flood the disk. The mechanism is visible
in the generated rules (dry-run, captured):

```
-A ufw-after-logging-input -j LOG --log-prefix "[UFW BLOCK] " -m limit --limit 3/min --limit-burst 10
```

so the log lines, which land in
`/var/log/ufw.log` (and the journal) on a
running system, carry that prefix (documented
— a representative line in context):

```
Oct 18 06:12:44 server kernel: [UFW BLOCK] IN=eth0 OUT= MAC=… SRC=203.0.113.9 DST=192.0.2.10 PROTO=TCP SPT=51244 DPT=23 …
```

`SRC`, `DPT`, `PROTO` are the fields you'll
actually grep: *who* knocked, on *which door*.
Medium and high also log allowed traffic and
invalid packets — volume rises fast; most
machines live happily at low, and `after.rules`'
skip-to-policy lines exist to keep the noisiest
broadcast ports out of even that.

Check: on your machine, with the firewall in
whatever state it's in, `ufw status` and
`ufw show added` tell the same story in two
vocabularies — if `show added` lists rules but
status says inactive, you're looking at a
notebook, not a firewall. Remember which is
which; chapter 11 will ask.
