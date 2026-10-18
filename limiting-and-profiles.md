# Limiting and Profiles

Two features that separate a firewall you
administer from one you merely switched on:
**limit**, which turns a door into a turnstile,
and **application profiles**, which let you
open a service by name and let the package that
owns the service keep the port list current.

## Limit: allow, but slowly

SSH has to be reachable — that's the point —
but a reachable SSH port attracts an endless
rain of password guesses from the whole
internet. `ufw limit` answers with arithmetic
instead of a lock:

```
sudo ufw limit 22/tcp
```

The generated rules are the clearest
explanation ever written of it (dry-run,
captured verbatim from UFW 0.36.2):

```
### tuple ### limit tcp 22 0.0.0.0/0 any 0.0.0.0/0 in
-A ufw-user-input -p tcp --dport 22 -m conntrack --ctstate NEW -m recent --set
-A ufw-user-input -p tcp --dport 22 -m conntrack --ctstate NEW -m recent --update --seconds 30 --hitcount 6 -j ufw-user-limit
-A ufw-user-input -p tcp --dport 22 -j ufw-user-limit-accept
```

Walk them:

1. Every **NEW** connection to port 22 has its
   source address written into a kernel list —
   the `recent` match's notebook (`--set`).
2. If that same source has now made **6 new
   connections within 30 seconds** (`--update
   --seconds 30 --hitcount 6`), the packet is
   sent to the `ufw-user-limit` chain, whose
   whole content is:

   ```
   -A ufw-user-limit -m limit --limit 3/minute -j LOG --log-prefix "[UFW LIMIT BLOCK] "
   -A ufw-user-limit -j REJECT
   ```

   Log it (slowly — 3 a minute at most) and
   reject it.
3. Otherwise, fall through to
   `ufw-user-limit-accept`: an ordinary ACCEPT.

The human consequence: a person logging in,
even fumbling twice, never notices. A script
trying passwords at machine speed gets six
attempts per half-minute per address — a rate
at which a dictionary attack outlives its
operator. It's not a lock and doesn't pretend
to be; key-only SSH is still the real fix.
It's friction, priced exactly right.

One honest sighting from the build machine.
There, the same command answered:

```
$ sudo ufw limit 22/tcp
Skipping unsupported IPv4 'limit' rule
Skipping unsupported IPv6 'limit' rule
```

UFW tests whether the kernel offers the
`recent` match before recording a limit rule;
the build machine's kernel refused it (its
netfilter is a partial implementation — the
full story is in `criteria.md`), so UFW skipped
rather than recording a rule it couldn't load.
On ordinary Ubuntu the command answers "Rule
added." If you ever meet the skipping message
for real, you've learned something true about
that kernel, and the fix is kernel-side, not
UFW-side.

## Profiles: services by name

Packages know their own ports better than you
do, so they may ship a **profile**: a small
INI file in `/etc/ufw/applications.d/`. SSH's,
installed with the openssh-server package,
complete and verbatim:

```
[OpenSSH]
title=Secure shell server, an rshd replacement
description=OpenSSH is a free implementation of the Secure Shell protocol.
ports=22/tcp
```

Four fields: a name in brackets, a title, a
description, and `ports` — which can list
several, in both protocols (`ports=80,443/
tcp|53/udp` is the shape; the syntax is
comma-separated ports, each with an optional
`/tcp` or `/udp`, and `|` for "plus"). UFW
reads them all:

```
$ sudo ufw app list
Available applications:
  Node Metrics
  OpenSSH

$ sudo ufw app info OpenSSH
Profile: OpenSSH
Title: Secure shell server, an rshd replacement
Description: OpenSSH is a free implementation of the Secure Shell protocol.

Port:
  22/tcp
```

(the heading is `Port:` for a single port,
`Ports:` for several — UFW is literal-minded).
Then the name works anywhere a port does:

```
sudo ufw allow OpenSSH
```

Names are **case-sensitive** — a real refusal:

```
$ sudo ufw app info "node metrics"
ERROR: Could not find profile 'node metrics'
```

The profile is `Node Metrics`; spelled exactly,
`app info` answers properly. And profiles only
exist once something provides them: on the
build machine before openssh-server was
installed, `app list` was an empty heading and
`app info OpenSSH` answered with that same
"Could not find profile" error. If a service
has no profile on your machine, the port-number
form is not a fallback of shame — it's the same
rule, spelled out.

Two mechanics worth knowing. When you allow by
profile, the rule remembers it — the generated
rule carries a comment (dry-run, captured):

```
-A ufw-user-input -p tcp --dport 9100 -j ACCEPT -m comment --comment 'dapp_Node%20Metrics'
```

so `ufw app update OpenSSH` can later re-read a
changed profile file and adjust the live rules
to match — updating profiles is how a package
that moves ports tells the firewall. (`app
update` on an unchanged profile succeeds
silently; no news is the news.)

## Writing your own profile

For services no package profiles — your own
daemons, a metrics exporter, an internal tool —
drop a file in `/etc/ufw/applications.d/`. This
guide ships one in `examples/`, and it's the
exact file the build machine loaded:

```
[Node Metrics]
title=Node metrics exporter
description=Prometheus-style node metrics endpoint, plain HTTP.
ports=9100/tcp
```

Within minutes of writing it (no restart; UFW
reads the directory per command), `app list`
showed `Node Metrics` between nothing and
OpenSSH, and `app info "Node Metrics"` printed
its fields. Malformed files are skipped with a
warning, not a crash — also captured:

```
$ sudo ufw app list
WARN: Skipping 'broken-profile': couldn't process
```

Write the file as strict INI: one bracketed
section, `key=value` lines, no quotes around
values. Then `sudo ufw allow "Node Metrics"`
(in quotes — the shell must pass the space as
one name) opens 9100/tcp with the profile's
bookkeeping attached. Chapter 8 uses the
port-number form instead, deliberately: a
worked example you might adapt to a machine
without the profile file should carry its
numbers with it.

Check: write the shipped profile into
`/etc/ufw/applications.d/` on a test machine,
and `sudo ufw app info "Node Metrics"` prints
the title, description, and `9100/tcp`. Then
`sudo ufw --dry-run allow "Node Metrics"`
shows port 9100 in the generated rules with
the `dapp_` comment — the profile, end to end,
without opening anything.
