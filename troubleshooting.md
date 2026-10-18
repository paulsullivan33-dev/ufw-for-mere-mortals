# Troubleshooting and Recovery

Firewall faults come in two temperatures:
you're locked out (hot), or a rule isn't doing
what you wrote (warm). Work the hot one with
the recovery ladder; work the warm one with
the reading skills from chapter 5. Both start
with the same question: *what state is it
actually in?*

## Locked out

The symptom: SSH connects to nothing; the
machine answers no service you enabled it
for; ping may still reply (ICMP has its own
house rules — the machine isn't dead, it's
defended against you).

There is no remote fix. That's not a gap in
this guide; it's the definition of a working
firewall. Recovery is physical, in ascending
order of trouble (documented — procedures,
not captures; no output is quoted because
none was earned):

1. **A console.** The server's keyboard and
   screen, the VM console in your hypervisor,
   the cloud provider's serial/web console, a
   lights-out card (IPMI/iDRAC/iLO) if the
   machine has one. Log in there, and
   `sudo ufw disable` takes the whole rule set
   back out — you're in, and the post-mortem
   happens at leisure with chapter 5's tools.
2. **Single-user / recovery boot.** If even
   the console login is entangled (rare —
   UFW doesn't gate local logins), boot the
   machine's recovery mode and set `ENABLED=no`
   in `/etc/ufw/ufw.conf`, or rename the rules
   files; UFW starts nothing it isn't told to.
3. **The lesson**, filed under chapter 4: this
   ladder exists because someone once skipped
   the second-session test. Don't be the
   second person.

Note what is *not* on the ladder: waiting.
There is no timeout, no "fails open after an
hour." Default-deny is patient.

## The clean slate: `ufw reset`

When the rule list itself is the mess — years
of accretion, three admins, no notes — reset
is honest surgery. Real output, from the
build machine's cleanup:

```
$ sudo ufw --force reset
Backing up 'user.rules' to '/etc/ufw/user.rules.20261018_055708'
Backing up 'before.rules' to '/etc/ufw/before.rules.20261018_055708'
Backing up 'after.rules' to '/etc/ufw/after.rules.20261018_055708'
Backing up 'user6.rules' to '/etc/ufw/user6.rules.20261018_055708'
Backing up 'before6.rules' to '/etc/ufw/before6.rules.20261018_055708'
Backing up 'after6.rules' to '/etc/ufw/after6.rules.20261018_055708'
```

Every file is backed up with a timestamp
before being replaced with the factory
version, defaults return to DROP/ACCEPT/DROP,
`ENABLED` returns to `no`, the recorded rules
return to `(None)`. Nothing about reset is
destructive that isn't also recoverable from
those backups. On a running firewall, do it
from a console — chapter 4's drill, again,
applies to the rebuild.

## A rule that "doesn't work"

In the order the build machine's experiments
suggest checking:

**1. Is the firewall even running that rule?**
`ufw status` vs `ufw show added` (chapter 5).
The build machine spent its whole life in the
gap: a tidy `show added` list and `Status:
inactive` — recorded, not running. Half of all
"ufw ignored my rule" reports are this gap,
or its mirror: rules added to a *disabled*
firewall and never enabled.

**2. Did an earlier rule catch the packet
first?** First match wins (chapter 2). The
numbered listing is the debugging view; a
broad `deny` above your careful `allow` is
the classic. Fix by deleting and re-adding in
order, or `ufw insert 1 <rule>` to place one
at the top.

**3. Did you rule the wrong door?** Port,
protocol, or family. `allow 53` without `/tcp`
or `/udp` covers both, but `allow 9100` from
the wrong subnet matches nobody you meant;
and a v4 subnet rule has no v6 twin to catch
the same client arriving over IPv6 (chapter
9). The log at `logging low`, watched while
you retry the connection, names the blocked
packet's actual `SRC` and `DPT` — believe
them over your memory of the rule.

**4. Did UFW refuse something upstream?**
Its errors are plain, and real examples fill
this guide: `ERROR: Invalid syntax` for a
command it can't parse (followed by the full
usage text — read it; the spelling is in
there), `ERROR: Could not find profile
'OpenSSH'` for a profile no package has
provided, `WARN: Skipping 'broken-profile':
couldn't process` for a malformed one, and
chapter 7's `Skipping unsupported ...
'limit' rule` for a kernel missing the match.
When the backend itself fails, UFW forwards
the kernel tools' words — the build machine's
parting example (its netfilter accepts simple
rules but not match extensions):

```
iptables v1.8.10 (nf_tables):  RULE_APPEND failed (No such file or directory): rule in chain INPUT
```

Shape to remember, whatever machine you're
on: *ufw is a front end; when the sentence
stops sounding like UFW, you're reading the
backend's diary, and the fix lives at that
layer* — modules, backend choice, kernel —
not in your rule list.

**5. Is the service even listening?**
`ufw show listening` exists for this: a perfect
rule in front of a dead daemon passes traffic
to nobody. The firewall is one layer; `ss -ltn`
tells you what's actually behind the door.

## When UFW is the wrong tool

Honest exits, in the order mortals meet them:

- **You think in tables and sets.** Many
  rules, ranges of ranges, timeouts per rule:
  you've outgrown the front end. Learn
  **nftables** directly — UFW's generated
  documents (chapter 3's dry runs) are a
  gentle on-ramp, being exactly that language
  with the training wheels visible.
- **The machine's job is being a firewall.**
  Multiple interfaces, NAT for a building,
  VPNs, reports for an auditor: install a
  purpose-built firewall system (OPNsense and
  pfSense are the usual names) on the box and
  let it be one thing well.
- **The firewall isn't on the host at all.**
  In cloud environments the provider's
  security groups may be the enforced layer;
  run UFW too if you like two locks, but know
  which one the traffic meets first.

Check: you can call the state in one breath —
`sudo ufw status` (running or not),
`sudo ufw show added` (what's written),
`sudo ufw show raw | head` (what the kernel
holds). Three commands, three vocabularies,
no rumors. Everything in this chapter is a
special case of those three disagreeing.
