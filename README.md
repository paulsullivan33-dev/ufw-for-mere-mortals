# UFW for Mere Mortals

A **firewall** is the bouncer your computer
keeps at its own door: every packet of network
traffic that arrives is checked against a list
of rules, and what matches nothing gets turned
away. **UFW** — the Uncomplicated Firewall — is
the tool Ubuntu and Debian ship for writing
that list without learning the kernel's own
rule language first. One command opens a port;
one command closes the world out.

This guide teaches the ideas before the tool:
what a packet filter actually decides, the
vocabulary every firewall shares, and only then
UFW itself — rules, addresses, rate limits,
application profiles, IPv6, and a small server
hardened step by step, with the lockout drill
(the one where you cut off your own SSH
session) taught carefully and early.

A note on how this guide was verified, because
it matters more here than usual. UFW 0.36.2 was
installed for real on the build machine, and a
great deal ran: every configuration file it
ships is quoted from the disk it landed on,
rules were recorded, listed, and deleted, the
profile system was exercised with both a real
package's profile and a written-from-scratch
one, and UFW's own `--dry-run` mode was used to
print the exact netfilter rules it generates —
which is how the rate limiter's counting and
the IPv6 twin rules in these chapters can be
shown rather than described. What the build
machine's kernel could not do is *load* the
rules: it accepts simple rules but refuses the
connection-tracking matches UFW's rule set is
built from, and deliberately switching on a
default-deny firewall was never going to be
done to the machine doing the building. So
everything downstream of a running firewall —
live status listings, log lines, packets
actually being refused — is marked
**(documented)**: written from the tool's
documentation and the generated rules, in the
canonical form, and labelled wherever it
appears. `criteria.md` keeps the exact ledger.

## What this guide covers

- [**What a firewall is**](what-a-firewall-is.md) —
  host and network firewalls, packets and
  ports, and the default-deny philosophy
- [**The vocabulary**](the-vocabulary.md) —
  rules, policies, chains, interfaces, and why
  replies to your own requests get through
- [**Meet UFW**](meet-ufw.md) — the front end
  and the kernel machinery behind it, and a
  tour of the files it owns
- [**First rules**](first-rules.md) — the
  lockout drill, allow/deny/reject, ports and
  ranges, deleting rules
- [**Reading your firewall**](reading-your-firewall.md) —
  status in its three forms, the `show`
  reports, and the log
- [**Rules with addresses**](rules-with-addresses.md) —
  subnets, interfaces, directions, and the
  LAN-only service pattern
- [**Limiting and profiles**](limiting-and-profiles.md) —
  rate-limiting SSH guessing, and opening
  services by name
- [**A worked example**](worked-example.md) —
  a small server hardened end to end, as a
  script you can keep
- [**IPv6**](ipv6.md) — the second set of
  doors, managed in the same rule list
- [**Forwarding and NAT**](forwarding-and-nat.md) —
  where a host firewall turns into a network
  one, and where this guide stops
- [**Troubleshooting**](troubleshooting.md) —
  lockouts, rules that don't bite, and the
  reset button
- [**Glossary**](glossary.md) — the terms,
  collected in one place

## What it doesn't cover

Raw nftables or iptables as a language (UFW
exists so you don't start there; the last
chapter says when to outgrow it), dedicated
firewall distributions, cloud providers'
security groups (same ideas, different
console), and high-availability or clustered
firewalls. It also doesn't try to make your
server *secure* — a firewall decides who can
reach a service; what that service does with
them is another guide's problem.

## How to use this guide

Read the first two chapters away from the
keyboard; they are the part that transfers to
every firewall you will ever meet. Then, on a
machine you can afford to experiment on — a
spare box, a VM, anything with a local console
— work through chapters 4 to 8 in order, and
don't skip the lockout drill. It is the
difference between a firewall you configured
and a firewall you understand.
