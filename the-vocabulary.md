# The Vocabulary

Every firewall — UFW, the router in the closet,
the security groups in a cloud console — speaks
the same small language. Learn it once here and
the rest of the guide is just spelling.

## Rules and policies

A **rule** is one instruction: packets matching
these conditions get this **action**. Conditions
combine the envelope facts from chapter 1 —
source, destination, port, protocol, interface,
state. Actions are few:

| Action  | The packet | The sender learns |
|---------|------------|-------------------|
| ALLOW   | passes     | nothing unusual   |
| DENY    | dropped    | nothing — silence |
| REJECT  | refused    | "refused," at once |

(DENY and REJECT get a full comparison in
chapter 4; the table is the whole difference.)

A **policy** is the action applied when *no*
rule matches — the default the rule list falls
through to. There is one policy per direction,
and UFW keeps them in `/etc/default/ufw`,
quoted here from the real file:

```
DEFAULT_INPUT_POLICY="DROP"
DEFAULT_OUTPUT_POLICY="ACCEPT"
DEFAULT_FORWARD_POLICY="DROP"
```

Read that as the factory posture: incoming —
refuse; outgoing — allow; forwarded (chapter
10) — refuse. Chapter 4 sets the first two
deliberately rather than inheriting them.

## The three doors: INPUT, OUTPUT, FORWARD

The kernel sorts every packet into one of three
**chains** — its word for the path a packet
takes through the rule list:

- **INPUT** — packets addressed to this machine
  itself. Someone knocking on *your* doors.
- **OUTPUT** — packets this machine sends.
  Your own programs calling out.
- **FORWARD** — packets addressed elsewhere
  that this machine is being asked to pass
  along. Only relevant when the machine routes
  for others: a router's whole job, a server's
  side job at most. Chapter 10.

"Incoming" and "outgoing" in UFW commands mean
INPUT and OUTPUT. When someone says a firewall
"blocks port 22," they always mean INPUT unless
they say otherwise.

## Interfaces and addresses

An **interface** is one network connection of
the machine: `lo` the loopback (the machine
talking to itself), `eth0` the first ethernet
port, `wlan0` wifi, and so on. Rules can name
an interface, because "reachable from the office
LAN" and "reachable from the internet" are
often the same machine wearing different cables.

Addresses are the familiar IP numbers, and they
come in **subnets** — a range written
`192.168.1.0/24`, meaning "the 256 addresses
that start 192.168.1." The `/24` counts the
fixed leading bits. Chapter 6 puts subnets to
work; for now, read `/24` as "the whole street"
and `/32` as "one house."

## New, established, related — why replies work

Here is the puzzle every beginner hits: the
policy says incoming is dropped, yet when your
machine asks a website for a page, the answer
comes back in. Isn't the answer "incoming"?

The kernel's **connection tracking** (conntrack)
sorts it out. Every packet is labelled with a
**state**:

- **NEW** — the first packet of a connection,
  knocking.
- **ESTABLISHED** — part of a connection already
  in progress, either direction.
- **RELATED** — a new connection that an
  existing one announced (some protocols open
  side channels; FTP is the textbook case).
- **INVALID** — belongs to nothing, or is
  malformed.

And UFW's rule set — its `before.rules` file,
which chapter 3 tours — contains this real line
ahead of almost everything:

```
-A ufw-before-input -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
```

In English: *input that belongs to a connection
already going is welcome, whatever the ports.*
Your web request went out as NEW on OUTPUT
(allowed by policy), the reply comes back
ESTABLISHED on INPUT (allowed by that line),
and strangers knocking NEW on closed ports hit
the DROP policy. Stateful filtering — deciding
by conversation, not by packet — is the single
feature that makes default-deny livable, and
it's why the rule list can stay short.

The INVALID state earns its drop two lines
later in the same file: packets claiming to
belong to connections that don't exist are
noise at best, probes at worst.

## Order matters

Rules are tried **top to bottom**, and the
first match decides — a packet doesn't collect
opinions. So the list is read like a program,
not a pile: specific exceptions go before
general ones, and "why didn't my rule work?"
is very often "an earlier rule caught the
packet first." Chapter 5 shows the numbered
listing that makes order visible, and
chapter 11 returns to the debugging.

Check: given the factory policies above and one
rule, `allow 443/tcp`, say what happens to
(a) a stranger's NEW packet to port 443
(allowed — the rule matches before the policy
is consulted), (b) a stranger's NEW packet to
port 25 (dropped by policy), and (c) the reply
to an email check your machine started
(ESTABLISHED — allowed by the conntrack line,
before either rule or policy).
