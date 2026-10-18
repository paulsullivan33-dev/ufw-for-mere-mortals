# Forwarding and NAT

Everything so far guarded a machine's own
doors. This chapter crosses the line chapter 2
drew: the FORWARD chain, packets passing
*through* — the moment a host with a firewall
starts behaving like a router. It is the
shortest chapter in the guide and most of it
is (documented), deliberately: the build
machine could generate the rules but, per the
README's verification note, no packet was ever
going to be forwarded by it. What follows is
the map of the territory and its fences, with
the parts verified here marked as such.

## Three switches, all off by default

Forwarding is refused at three independent
layers, and a working router needs all three
open:

1. **The kernel switch.** Linux won't forward
   at all until `net.ipv4.ip_forward` is 1.
   UFW's own sysctl file keeps it parked, as a
   comment (real, from `/etc/ufw/sysctl.conf`):

   ```
   #net/ipv4/ip_forward=1
   ```

   Uncommenting it in that file is the UFW way
   to ask; setting it with `sysctl` directly
   also works and is the system's way.
2. **The forward policy.** Chapter 2's third
   line, real from `/etc/default/ufw`:

   ```
   DEFAULT_FORWARD_POLICY="DROP"
   ```

   Set with `sudo ufw default allow routed` —
   "routed" is UFW's word for the FORWARD side
   in its command language.
3. **Rules for the traffic itself**, new in
   this chapter.

Factory state — all three closed — is why a
server with two network cards still isn't a
router, and why chapter 2 could call FORWARD
"a server's side job at most."

## Route rules

UFW spells forwarding rules with `route`,
and the generated form is real (dry-run,
captured):

```
$ sudo ufw --dry-run route allow in on eth0 out on eth1 to any port 80 proto tcp
### tuple ### route:allow tcp 80 0.0.0.0/0 any 0.0.0.0/0 in_eth0!out_eth1
-A ufw-user-forward -i eth0 -o eth1 -p tcp --dport 80 -j ACCEPT
```

The rule landed in `ufw-user-forward`, wearing
both interfaces: in on the LAN card, out on
the WAN card. Replies need no twin rule —
`before.rules` accepts ESTABLISHED,RELATED in
the forward chain too (its third conntrack
line, real, from chapter 3's file). The
discipline from chapter 6 applies doubled:
forward rules are where "allow from the LAN,
to anywhere, on these ports" shapes a whole
network's posture, and a sloppy one is a hole
with other people's machines behind it.

## NAT: the part UFW doesn't do in commands

Forwarding alone lets a LAN talk *through*
the box only if the outside world can route
back — with private LAN addresses, it can't.
**NAT** (network address translation), in its
masquerade form, rewrites outgoing packets to
carry the router's own public address and
remembers the mapping for replies. UFW has no
`ufw nat` command; the masquerade is a
hand-written block in `/etc/ufw/after.rules` —
the one house file you *do* edit, and the
exception that proves chapter 3's rule
(documented — the canonical block from UFW's
documentation):

```
*nat
:POSTROUTING ACCEPT [0:0]
-A POSTROUTING -s 192.168.1.0/24 -o eth1 -j MASQUERADE
COMMIT
```

placed *before* the file's `*filter` section,
followed by `sudo ufw reload`. Read it as:
packets leaving on eth1 from the LAN subnet
get the router's address. Port forwarding —
sending arrivals at one public port onward to
a specific inside machine — is a sibling block
in the same table (`-j DNAT --to-destination`),
same status: documented here, hand-edited
there, and testable only by doing it.

## Where this stops

A machine doing all of the above is a router
built from a server's spare parts, and for a
homelab or a tiny office it can be the right
answer. But notice what you accumulated:
forwarding rules in one grammar, NAT in
hand-edited restore syntax, DHCP and DNS as
separate services entirely, and no single view
of the whole. Dedicated firewall systems —
chapter 11 names the exits — exist precisely
at the point where the NAT table stops being
a curiosity. UFW's honest scope is a host;
this chapter is the guided tour of its fence,
not a recommendation to climb it.

Check: on a machine you administer, the three
switches tell you its intentions —
`sysctl net.ipv4.ip_forward` (0 or 1),
`grep DEFAULT_FORWARD /etc/default/ufw`, and
`sudo ufw show added | grep route` (usually
nothing). If all three are closed, whatever
the box is doing, it isn't routing.
