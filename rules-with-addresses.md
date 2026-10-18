# Rules with Addresses

`ufw allow 443/tcp` opens a door to the entire
internet. Often that's the point of a web
server. Often it isn't — the database, the
metrics endpoint, the admin panel were only
ever meant for the building. This chapter is
the grammar for saying *who* may use a door,
*where* it may be used, and *which way* the
rule faces.

## From: naming the visitor

The long form of a rule spells out both ends:

```
sudo ufw allow from 192.168.1.0/24 to any port 9100 proto tcp
```

Read it literally: *allow, from the subnet
192.168.1.0/24, to any address of mine, port
9100, protocol TCP.* Recorded on the build
machine, it produced exactly one message —

```
Rules updated
```

— where the web rules produced two. No
`(v6)` twin: a rule naming an IPv4 subnet is
an IPv4 rule, full stop. The tuple UFW stored
(captured from `user.rules`) shows the same
specificity:

```
### tuple ### allow tcp 9100 0.0.0.0/0 any 192.168.1.0/24 in
-A ufw-user-input -p tcp --dport 9100 -s 192.168.1.0/24 -j ACCEPT
```

The source became `-s 192.168.1.0/24`; everyone
not in that range falls through to the default
DROP. Sources can be:

- **a subnet** — `192.168.1.0/24`, the whole LAN
- **one host** — `192.168.1.50` or, explicitly,
  `192.168.1.50/32`
- **anywhere** — `any`, or just leave `from`
  off, as the simple rules do

## To: naming the door precisely

`to any port 9100` hides two defaults worth
seeing once: the destination address is `any`
(this machine, whichever of its addresses), and
you can name one instead —

```
sudo ufw allow from any to 192.0.2.10 port 8080 proto tcp
```

— for machines wearing several addresses, where
a service should exist on one and be absent
from the others. `to` also takes the interface's
partner in the fuller grammar below.

## On: naming the interface

A multi-homed machine — office LAN on one card,
internet on another, say — can scope a rule to
the cable it arrives on (dry-run, captured):

```
$ sudo ufw --dry-run allow in on eth1 to any port 8080 proto tcp
### tuple ### allow tcp 8080 0.0.0.0/0 any 0.0.0.0/0 in_eth1
-A ufw-user-input -i eth1 -p tcp --dport 8080 -j ACCEPT
```

The rule grew `-i eth1` ("in on interface
eth1"). Interface scoping and subnet scoping
solve overlapping problems; subnets travel with
the addressing plan, interfaces with the
hardware, and on a simple one-cable server you
will rarely need either. On a laptop that roams
between trusted and hostile networks, interfaces
are how "home rules" and "café rules" would
differ — though switching rule sets is a job
UFW leaves to you (profiles of a sort return in
chapter 7, but they aren't this).

## Direction: in is not the only way

Everything so far faces `in`, because that's
the default. Rules can face `out`:

```
$ sudo ufw --dry-run allow out 53/udp
### tuple ### allow udp 53 0.0.0.0/0 any 0.0.0.0/0 out
-A ufw-user-output -p udp --dport 53 -j ACCEPT
```

Note the chain changed: `ufw-user-output`. With
the usual `default allow outgoing`, outgoing
rules are decorations — everything passes
anyway. They earn their keep the day you set
`default deny outgoing`, the strict posture in
which the machine may only make the calls you
list: DNS out (above), web out, mail out, and
nothing else — no surprise beacons, no quiet
uploads. It's a real technique and a real
commitment; the list of things a modern system
calls out to is longer than anyone guesses, and
you'll debug by log for a week. Chapter 11
mentions it again; most mortals stop at
default-allow outgoing, and the replies still
protected by chapter 2's statefulness.

## The pattern: LAN-only services

Put the pieces together and you get this
guide's most useful idiom. Any service that
exists for the local network — metrics,
dashboards, admin panels, file shares, the
printer's web page on your server — gets:

```
sudo ufw allow from 192.168.1.0/24 to any port <port> proto tcp
```

and no general `allow`. The service stays
reachable from every desk in the building and
invisible from the street: not "protected by a
password the internet can also try," but
*absent*, as far as the internet can tell. If
you take one habit from this guide to machines
you administer, take this one — audit your
`allow`s and ask of each, *does the world need
this door, or does the building?*

Check: record the LAN rule above, then read
`sudo ufw show added` and the matching tuple in
`/etc/ufw/user.rules`. The added-list speaks
your command back; the tuple shows the stored
form — source last in the tuple's fields,
`-s` in the rule. Same rule, two accents; you
should be fluent in both by now.
