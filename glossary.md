# Glossary

**Application profile** — a small INI file in
`/etc/ufw/applications.d/`, shipped by a
package or written by you, naming a service's
ports so it can be allowed by name:
`ufw allow OpenSSH`. See chapter 7.

**Chain** — the kernel's name for a path
packets take through the rules: INPUT, OUTPUT,
FORWARD, and UFW's own sub-chains hanging off
them. Rules live in chains and are read top to
bottom.

**Connection tracking (conntrack)** — the
kernel machinery that remembers connections in
progress, so packets can be judged by the
conversation they belong to — the basis of
stateful filtering.

**Default policy** — the action applied when
no rule matches: one per direction, kept in
`/etc/default/ufw`. Default-deny incoming is
the posture this guide teaches.

**DENY** — a rule action: the packet is
dropped (in the kernel, the DROP target) and
the sender hears silence.

**Dry run** — `ufw --dry-run <command>`: UFW
prints the complete generated rule set the
command would load, both families, and
changes nothing. This guide's microscope.

**ESTABLISHED** — connection state: a packet
belonging to a connection already in progress.
UFW's house rules accept it, which is why
replies to your own requests get in.

**FORWARD** — the chain for packets passing
through the machine to somewhere else. The
router's chain; refused by policy until you
deliberately build a router (chapter 10).

**Host firewall** — a firewall running on the
machine it protects, guarding that machine
only — as opposed to a network firewall
guarding everything behind it.

**INPUT** — the chain for packets addressed
to this machine itself. "Incoming" in UFW's
commands.

**Interface** — one network connection of the
machine: `lo` (loopback), `eth0`, `wlan0`, and
so on. Rules can be scoped to one.

**INVALID** — connection state: a packet that
belongs to no tracked connection or is
malformed. Dropped by UFW's house rules.

**iptables** — the older of the kernel's two
packet-filter interfaces, and the command-line
tools of the same name; on current systems
they usually speak to nftables underneath.
UFW drives these tools.

**limit** — a UFW action like allow, but
rate-limited per source: `ufw limit 22/tcp`
refuses a source making its 6th new connection
within 30 seconds (chapter 7).

**Loopback** — the interface `lo`, the machine
talking to itself. Always allowed by the house
rules; half your services would break without
it.

**Masquerade** — the common form of NAT: many
private addresses share one public address,
rewritten on the way out and remembered for
replies. In UFW, a hand-written block in
`after.rules` (chapter 10).

**NAT** — network address translation:
rewriting addresses (and sometimes ports) as
packets pass, so private networks can share
public addresses or arrivals can be redirected
to an inside host.

**NEW** — connection state: the first packet
of a connection, the knock. Most rules you
write are implicitly about NEW packets;
ESTABLISHED is handled by the house rules.

**nftables** — the current Linux kernel
packet-filtering machinery, underneath the
iptables tools UFW drives.

**OUTPUT** — the chain for packets this
machine sends. "Outgoing" in UFW's commands.

**Packet** — one addressed envelope of network
traffic: source, destination, port, protocol,
state. The only thing a packet filter judges.

**Port** — a numbered door, 1–65535, one per
service: 22 SSH, 80 HTTP, 443 HTTPS. Written
`443/tcp` when the protocol matters.

**Profile** — see **Application profile**.

**REJECT** — a rule action: the packet is
refused *with an answer* — a TCP reset — so
the sender fails immediately instead of
waiting out a timeout. Contrast DENY.

**RELATED** — connection state: a new
connection an existing one announced (FTP's
data channels are the textbook case). Accepted
by the house rules alongside ESTABLISHED.

**Route rule** — a UFW rule written with
`route`, governing the FORWARD chain: which
forwarded traffic may pass, in on one interface
and out on another.

**Rule** — one instruction: packets matching
these conditions get this action. First match
in the chain decides.

**Stateful filtering** — judging packets by
connection state rather than in isolation.
What makes default-deny incoming compatible
with ordinary outgoing use.

**Subnet** — a range of addresses written
`192.168.1.0/24`: the `/24` counts the fixed
leading bits, so `/24` is 256 addresses and
`/32` is exactly one host.

**Tuple** — UFW's one-line stored form of a
rule inside `user.rules`, recording action,
protocol, ports, addresses, and direction —
the memory from which kernel rules are
generated.

**UFW** — Uncomplicated Firewall: Ubuntu and
Debian's front end over the kernel's packet
filter. You write rules in services and ports;
it keeps them in `/etc/ufw/` and generates the
kernel's rule documents.
