# What a Firewall Is

Every program on your machine that talks to the
network does it through **ports**: numbered
doors, one per service. The web server waits at
port 80 and 443, the SSH daemon at port 22, and
so on up to 65535. Traffic arrives in
**packets** — small addressed envelopes, each
saying where it came from, which door it wants,
and whether it is starting a conversation or
continuing one.

A **firewall** is software that stands in front
of those doors and inspects every packet
against a list of **rules**: allow this, refuse
that, and — the rule that matters most — a
**default policy** for everything the list
doesn't mention. That's all a firewall is. The
complications in every later chapter are just
the list getting more precise.

## Two kinds of firewall

**Network firewalls** sit between networks —
in your router, or a dedicated box at the edge
of an office — and guard everything behind
them at once. **Host firewalls** run on the
machine itself and guard only it. This guide is
about host firewalls, and specifically UFW, the
one Ubuntu and Debian provide.

The distinction matters because the two fail
differently. A network firewall can be
misconfigured and leave a whole building
exposed; a host firewall protects a machine
even when it's plugged into a network you don't
control — a laptop in a café is the classic
case — and keeps guarding services that were
only ever meant for the local network when
someone moves the machine. Defence in depth is
the formal name; "locks on the inside doors
too" is the idea.

## What the firewall can see

A packet filter decides using only what's on
the envelope:

- the **source** and **destination** addresses
- the **port** it's headed for (or came from)
- the **protocol** — TCP, UDP, ICMP and friends
- which **interface** it arrived on (the
  loopback, the ethernet port, the wifi)
- its **state** — is this the start of a new
  connection, or part of one already going?

It cannot see inside an encrypted conversation,
doesn't know which user a packet "belongs" to
in any deep sense, and has no opinion about
whether the program behind the door is any
good. A firewall that allows port 443 lets
*anything* talk to whatever listens on 443.
Keeping that program patched is a different job.

## Default-deny: the one idea to keep

There are two ways to write the list:

- **Default-allow:** everything passes except
  what you block. Feels friendly, fails open.
  Every new service you install — and programs
  install listeners you never asked about —
  starts life reachable by the whole network
  until you notice and block it.
- **Default-deny:** nothing passes except what
  you allow. Fails closed, and sometimes fails
  *you* closed, out of your own machine —
  chapter 4 exists because of that. But the
  list of what's open is short, deliberate, and
  entirely yours. A service you forgot about is
  a service nobody can reach.

Every serious firewall setup is default-deny
with a short allow list. The work in this guide
is learning to write that list well. The
matching habit for outgoing traffic is looser —
most machines allow all outgoing connections
and their replies — and chapter 2 explains why
that isn't the hole it first looks like.

## Where UFW fits

The Linux kernel has filtered packets for
decades, through a machinery currently called
**nftables** (with the older **iptables**
interface still widely used). Its native rule
language is precise and, for a human writing a
short list of doors, miserable. **UFW** —
Uncomplicated Firewall — is a front end: you
say `ufw allow 443/tcp`, it keeps the list,
translates it into kernel rules, and loads
them. Chapter 3 opens it up and shows the
seams, because a front end you can't see past
will eventually confuse you.

What UFW won't do: it is one machine's list.
It won't coordinate a fleet, route between
networks (except in the limited way chapter 10
describes), or inspect the *contents* of
traffic. Tools that do those things exist and
chapter 11 names them; they start where this
guide stops.

Check: nothing to run yet — but one question to
be able to answer before chapter 2: if a
stranger's packet arrives at port 22 of a
default-deny machine with no rule about SSH,
what happens to it, and what does the stranger
see? (Dropped, and nothing at all — silence.
Chapter 4 returns to why the silence itself is
a design choice.)
