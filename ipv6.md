# IPv6

Your machine very likely has two addresses:
an IPv4 one you know, and an IPv6 one you may
never have typed. Services listen on both by
default. A firewall that only guards the first
is a locked front door on a house with the back
wide open — and "I don't use IPv6" is not a
counterargument, because the *network* uses it
whether you ask or not.

UFW's answer is to make IPv6 not a separate
subject. One setting, in `/etc/default/ufw`,
quoted with its own instructions:

```
# Set to yes to apply rules to support IPv6 (no means only IPv6 on loopback
# accepted). You will need to 'disable' and then 'enable' the firewall for
# the changes to take affect.
IPV6=yes
```

`yes` is the factory setting, and it means:
**every rule you write is written twice.** You
have seen the evidence in every capture so far
without it being pointed at:

```
$ sudo ufw allow 443/tcp
Rules updated
Rules updated (v6)
```

One command, two updates. In `ufw status` the
twins appear as separate lines with `(v6)` in
the name (chapter 5's listing), in the dry run
they are two complete documents — the second
addressed to the `ufw6-` chains — and on disk
your rules live in a pair of files, `user.rules`
and `user6.rules`, with UFW's house rules
mirrored in `before6.rules` / `after6.rules`.

The twins are not always identical, and the
differences are the chapter:

- **Explicit addresses stay literal.** The LAN
  rule of chapter 6 named `192.168.1.0/24`, so
  it has no twin — one message, one tuple. An
  IPv6 subnet would need its own rule, with its
  own subnet, written deliberately. *Anywhere*,
  by contrast, means both `0.0.0.0/0` and `::/0`,
  every time.
- **ICMP is load-bearing in v6.** IPv6 replaced
  ICMP with ICMPv6 and put real work in it —
  neighbour discovery, and "packet too big"
  messages that path MTU discovery depends on.
  `before6.rules` accepts a careful RFC 4890
  list (destination-unreachable, packet-too-big,
  echo-reply, and friends) where the v4 file
  accepts four types. Blocking all of ICMPv6,
  a cargo-cult move from v4 folklore, breaks
  the protocol itself; UFW's defaults don't,
  which is what defaults are for.
- **Some v6-only housekeeping exists.** The
  same file drops routing-header type 0 packets
  (`-m rt --rt-type 0`), a deprecated extension
  header with a spoofing history — a rule with
  no v4 counterpart, there because the protocol
  needed it.

What UFW's one-list design saves you from is
the historically normal failure: a v4 rule set
polished for years, and a v6 side either empty
(so policy ACCEPT, everything open) or an
afterthought nobody audits. Here there is one
list, one `status`, one audit — and turning
`IPV6` off is a decision you'd have to make
deliberately, in writing, in that file.

Two honest limits. UFW manages addresses, not
address *privacy* — IPv6 privacy extensions,
temporary addresses, and your router's
advertisements are the operating system's and
network's business. And a rule written against
a *named* v6 subnet presumes your v6 addressing
is stable enough to name; on networks where it
isn't, interface-scoped rules (chapter 6) are
the steadier tool.

Check: `grep IPV6 /etc/default/ufw` says `yes`,
and any single `sudo ufw allow` on your machine
answers with both "Rules updated" lines. If it
answers with only one, somebody turned the v6
half off — find out who, and whether they knew
about the back door.
