# First Rules

This is the chapter where a firewall can hurt
you, so the order is the lesson: **prepare,
record, enable, prove** — in that order, every
time. Everything before `enable` merely writes
configuration down; the build machine for this
guide recorded its whole rule set with the
firewall off, and yours can too. Enabling is
the one step that puts rules between you and
your machine.

## The lockout, and how not to meet it

The classic accident: you're logged into a
remote server over SSH. You enable the
firewall. The default incoming policy is DROP
and no rule allows SSH. Your existing session
usually survives — it's ESTABLISHED, chapter 2
— but the *next* login never arrives, and the
machine is a locked room you're standing
outside of, possibly on another continent.

The drill that prevents it:

1. **Know how you're connected.** If it's SSH,
   port 22 (or whatever port your sshd uses) is
   the door you're standing in. On a local
   console or a VM console, you can't lock
   yourself out at all — experiment there first
   if you can.
2. **Allow your door before enabling.** With
   the firewall still off:

   ```
   $ sudo ufw allow 22/tcp
   Rules updated
   Rules updated (v6)
   ```

   (Real output. If your SSH is on a different
   port, allow that one — and chapter 7's
   `limit` is the better version of this rule.)
3. **Keep this session open.** Don't log out
   when you enable. This window is your safety
   line.
4. **Enable** (documented — the one step the
   build machine didn't run, for the reasons in
   the README):

   ```
   $ sudo ufw enable
   Command may disrupt existing ssh connections. Proceed with operation (y|n)? y
   Firewall is active and enabled on system startup
   ```

   UFW warns you itself, in its own prompt.
   Believe it.
5. **Prove it from a second session.** Open a
   *new* SSH connection. If it logs in, the
   firewall passes the only test that matters.
   *Then* close the first session. If the new
   connection hangs, you still hold a live
   session in step 3's window — `sudo ufw
   disable` from it undoes everything.

That sequence — never vibes — is how firewalls
get enabled on machines people care about.

## Writing rules

The everyday grammar:

```
sudo ufw allow 80            # both TCP and UDP, both families
sudo ufw allow 443/tcp       # one protocol
sudo ufw allow http          # a service name
```

Service names come from `/etc/services`, and
UFW resolves them as it generates rules — real
dry-run output from the build machine:

```
### tuple ### allow tcp 80 0.0.0.0/0 any 0.0.0.0/0 in
-A ufw-user-input -p tcp --dport 80 -j ACCEPT
```

(http produced the port-80 rule; https would
produce 443. Names are conveniences — the
tuple remembers the number.)

A **range** uses a colon, and generates a
multiport rule (also real):

```
$ sudo ufw --dry-run allow 6000:6007/tcp
### tuple ### allow tcp 6000:6007 0.0.0.0/0 any 0.0.0.0/0 in
-A ufw-user-input -p tcp -m multiport --dports 6000:6007 -j ACCEPT
```

Every rule you add is matched *before* the
default policy and *after* the handful of house
rules in `before.rules`. Order among your own
rules is the order you added them; chapter 5
shows how to see and adjust that.

## Allow, deny, reject — what the other side sees

All three refuse or pass the packet; they
differ in what the *sender* experiences:

| Command | Kernel action | A scanner sees | A real client sees |
|---------|---------------|----------------|--------------------|
| `allow` | ACCEPT | the service | the service |
| `deny` | DROP | silence; a timeout | a long hang, then failure |
| `reject` | REJECT | an immediate refusal | "connection refused," instantly |

And those aren't abstractions — they're the
exact targets in the generated rules (dry-run,
captured):

```
-A ufw-user-input -p tcp --dport 23 -j DROP
-A ufw-user-input -p tcp --dport 23 -j REJECT --reject-with tcp-reset
```

**deny (DROP) is the default-deny philosophy at
packet level**: a dropped port is
indistinguishable from a dead machine or a
cable fault, so probing learns nothing and
gives up slowly. **reject (REJECT)** answers
politely with a TCP reset: faster failure for
legitimate clients who typo'd an address, and a
common kindness on *internal* networks, where
"hangs for thirty seconds" generates helpdesk
tickets and reveals nothing worth hiding. Rule
of thumb: deny facing the internet, reject
facing your own building, allow only what you
mean to serve.

## Deleting rules

Two ways. The script-friendly one repeats the
rule with `delete` (real, including against the
recorded rules of a firewall that isn't running
yet):

```
$ sudo ufw --force delete allow 443/tcp
Rules updated
```

(`--force` suppresses the confirmation prompt;
without it, UFW asks.)

The interactive one uses the number from
`ufw status numbered` (documented — numbering
belongs to the running listing of chapter 5):

```
$ sudo ufw delete 3
Deleting:
    allow 443/tcp
Proceed with operation (y|n)? y
Rule deleted
```

Delete by repeating the rule when you know what
you wrote; delete by number when you're looking
at the list and pointing. One warning from the
build machine's experiments: with the firewall
*inactive*, numbered deletion walks UFW's
recorded v4 and v6 lists in an order that isn't
the tidy single list the running status shows —
one more reason the numbered form is a tool for
a running firewall.

Check: with the firewall still off, record
`allow 22/tcp`, then `sudo ufw show added`
lists `ufw allow 22/tcp`. Delete it by repeating
the rule and `show added` returns to `(None)`.
You've then used the whole recording machinery
— everything except the word `enable`.
