# Meet UFW

UFW is a translator with good habits. You speak
in services and ports; the kernel speaks in
chains, matches, and targets; UFW stands between
with a notebook. When you type

```
$ sudo ufw allow 443/tcp
Rules updated
Rules updated (v6)
```

three things have happened: your command was
parsed into a rule, the rule was **written into
UFW's own files** on disk, and — if the firewall
is running — the kernel's rule set was reloaded
from them. That middle step is the one to
remember. UFW's files are the source of truth;
the kernel holds a copy. (The two "Rules
updated" lines are real, captured from the
build machine: one per address family — chapter
9 explains.)

First, what you've got:

```
$ ufw version
ufw 0.36.2
Copyright 2008-2023 Canonical Ltd.
```

UFW is a Python program (`/usr/sbin/ufw`, with
its library in `/usr/lib/python3/dist-packages/
ufw/`) that drives the system's iptables tools,
which on current systems talk to the kernel's
nftables machinery underneath. You never need to
care which backend is underneath — until an
error message cares for you, as chapter 11
shows.

## The files, and which are yours

Everything UFW owns lives in `/etc/ufw/`:

| File | What it is |
|------|------------|
| `ufw.conf` | on/off at boot, log level |
| `user.rules`, `user6.rules` | your rules, translated |
| `before.rules`, `before6.rules` | UFW's house rules, run first |
| `after.rules`, `after6.rules` | UFW's house rules, run last |
| `sysctl.conf` | kernel settings UFW applies |
| `applications.d/` | service profiles (chapter 7) |

Plus one outsider: `/etc/default/ufw`, the
defaults file chapter 2 quoted, holding the
policies and the IPv6 switch.

**You edit almost none of these by hand.** The
`ufw` command edits `user.rules` for you; the
house files are rewritten by package upgrades
and by `ufw reset`. The exceptions — hand-adding
a profile in `applications.d/`, changing a
setting in `/etc/default/ufw` — are covered in
their chapters. Reading the files, though, is
encouraged: they're the ground truth when a
command's summary seems too tidy.

### ufw.conf — two settings

The real file, shipped in `examples/`:

```
# Set to yes to start on boot. If setting this remotely, be sure to add a rule
# to allow your remote connection before starting ufw. Eg: 'ufw allow 22/tcp'
ENABLED=no

# Please use the 'ufw' command to set the loglevel. Eg: 'ufw logging medium'.
# See 'man ufw' for details.
LOGLEVEL=low
```

That comment on `ENABLED` is the whole of
chapter 4 in one sentence, written by the
authors into the file itself. `ENABLED` flips
to `yes` when you run `ufw enable`; `LOGLEVEL`
is set by `ufw logging`, not by editing.

### user.rules — your list, translated

After the three rules of chapter 8's worked
example were recorded on the build machine,
this was the heart of `/etc/ufw/user.rules`
(captured verbatim):

```
### RULES ###

### tuple ### allow tcp 80 0.0.0.0/0 any 0.0.0.0/0 in
-A ufw-user-input -p tcp --dport 80 -j ACCEPT

### tuple ### allow tcp 443 0.0.0.0/0 any 0.0.0.0/0 in
-A ufw-user-input -p tcp --dport 443 -j ACCEPT

### tuple ### allow tcp 9100 0.0.0.0/0 any 192.168.1.0/24 in
-A ufw-user-input -p tcp --dport 9100 -s 192.168.1.0/24 -j ACCEPT

### END RULES ###
```

Each rule is stored as a **tuple** — UFW's
one-line memory of the command — followed by
the kernel rule it expands to. The file is in
iptables-restore format: `*filter` at the top,
chain declarations, the rules, `COMMIT` at the
bottom. It's readable, and reading it is the
fastest way to stop seeing UFW as magic.

### before.rules — the house rules

This file runs before yours and does the
unglamorous essentials, all of it quotable from
the shipped file:

- loopback traffic is always allowed
  (`-A ufw-before-input -i lo -j ACCEPT`)
- ESTABLISHED and RELATED traffic is accepted —
  the line chapter 2 walked
- INVALID packets are dropped
- a few ICMP types are accepted, because
  breaking ICMP breaks error reporting ("this
  host is unreachable" is an ICMP message)
- DHCP replies are let in, so the machine can
  keep its own address

`after.rules` is shorter: mostly instructions
to the logger to skip-to-policy on the noisy
broadcast ports so your log isn't all Samba and
DHCP chatter (chapter 5).

## The honest architecture

One command the whole guide leans on, because
it shows UFW's work: `--dry-run` prints the
complete generated rule set — every chain, both
families — and changes nothing. From the build
machine, the smallest interesting excerpt:

```
$ sudo ufw --dry-run allow 22/tcp
*filter
:ufw-user-input - [0:0]
...
### tuple ### allow tcp 22 0.0.0.0/0 any 0.0.0.0/0 in
-A ufw-user-input -p tcp --dport 22 -j ACCEPT
...
COMMIT
Rules updated
Rules updated (v6)
```

That is the whole design in one output: your
words in, a complete, reloadable rule document
out. Everything UFW "applies" to a running
firewall is this document, loaded whole. It's
why `ufw reload` exists, why reset is clean,
and why — when we reach the troubleshooting
chapter — "what did UFW actually generate?" is
always an answerable question.

Check: on your machine, `ls /etc/ufw` shows the
files above; `ufw version` names your version;
and `sudo ufw --dry-run allow 22/tcp` prints a
document ending in `COMMIT` without changing
anything (`sudo ufw show added` still says
`(None)` afterwards). If the dry run works,
your UFW and your kernel tools agree — the
rest is vocabulary.
