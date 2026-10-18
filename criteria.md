# Writing Criteria

Every guide in this repo is written to the same
standard. If you're adding or editing a guide —
human or AI — hold it to these.

1. **Plain words, real ideas.** Simple language,
   never dumbed-down concepts. Explain jargon on
   first use; collect terms in the glossary.
2. **No hype.** No marketing adjectives, no
   "revolutionary," no promises about what
   something will do for the reader.
3. **Honest about limits.** Say what the thing
   *can't* do. State uncertainty instead of
   smoothing it over. Validation notes include
   what remains unverified.
4. **No invented numbers.** Benchmarks, defaults,
   and specs are either measured or qualified with
   "depends on your setup." If it wasn't tested,
   say so.
5. **Checkable.** Commands are meant to be run,
   with "Check:" blocks showing what success looks
   like. Sources are linked, not asserted.
6. **Respect the reader's setup.** Call out
   Windows/Mac/Linux differences. Don't assume a
   GPU, a budget, or prior experience.
7. **Safety isn't skipped.** Real risks get
   stated plainly, not buried.
8. **Scoped.** Each guide says what it covers and
   points elsewhere for the rest. No guide
   pretends to be the whole subject.
9. **Structure over prose.** Tables, before/after
   examples, symptom → fix. Scannable beats essay.

## Verification notes for this guide

Standard 3 and 4 applied to this guide,
specifically. This guide's subject is a tool
whose whole purpose is changing a live system,
and it was built on a machine whose kernel
could not accept that change — so the line
between *ran* and *documented* is drawn
chapter by chapter below, and everything on
the documented side is marked **(documented)**
in the text.

**The ladder that was climbed, in order:**

1. *Inventory.* Root shell. `iptables` and
   `nft` present (iptables v1.8.10, the
   nftables-backed build); `ufw` absent;
   `/proc/net/ip_tables_names` present but
   empty; the legacy backend dead on arrival —
   `iptables-legacy -L` answers "can't
   initialize iptables table `filter': Table
   does not exist".
2. *Install.* `apt-get install -y ufw`
   succeeded: **ufw 0.36.2** (Ubuntu package).
   Every file quoted in chapter 3 was read off
   the disk it installed to.
3. *Read-only surface — all ran.* `ufw status`,
   `status verbose`, `status numbered` ("Status:
   inactive"), `ufw show raw`, `show builtins`,
   `show added` (empty and populated), `show
   listening` (empty output — nothing was
   listening), `ufw app list`, `app info`.
4. *Recorded rules with the firewall off — all
   ran.* `ufw default deny incoming` / `allow
   outgoing`, `ufw allow 80/tcp`, `443/tcp`,
   the LAN-scoped 9100 rule, `ufw logging on`,
   delete by repeating the rule, and finally
   `ufw --force reset` — each output captured,
   and the resulting `user.rules` read back.
   UFW records rules without a running
   firewall; that fact is itself taught in
   chapters 4 and 5.
5. *Generated rules — all ran.* `ufw --dry-run`
   prints the complete rule document a command
   would load and changes nothing (state
   re-checked after). Dry runs were captured
   for: a plain allow, a service name (`http`),
   a port range, deny vs reject, an outgoing
   rule, an interface-scoped rule, a `route`
   rule, a profile allow, and `limit` — the
   limit chapter's explanation of the counting
   is a walk of those generated lines.
6. *Kernel write probes — ran, and this is
   where the ladder ends.* A plain rule
   (`iptables -A INPUT -p tcp --dport 59999
   -j ACCEPT`) added, listed, and deleted
   cleanly, exit 0. Every rule using a match
   extension failed identically, exit 4:

   ```
   iptables v1.8.10 (nf_tables):  RULE_APPEND failed (No such file or directory): rule in chain INPUT
   ```

   preceded by warnings of the form "Extension
   conntrack revision 0 not supported, missing
   kernel module?" — for `conntrack`, `recent`,
   and `limit` alike. UFW's own rule set is
   built from exactly those matches (its
   `before.rules` opens with a conntrack
   accept), so no rule set UFW generates could
   ever load on this kernel; `ufw limit`
   detects the missing `recent` match itself
   and answers "Skipping unsupported IPv4
   'limit' rule", also captured. Enabling a
   default-deny firewall on the build machine
   was additionally ruled out in advance — it
   is the machine the guide was being built
   on. Probes left two empty kernel table
   shells (`ip filter`, `ip6 filter`, no rules,
   all policies ACCEPT), and UFW's recorded
   state was reset to factory afterwards.

**Verified by running, per chapter:**

- *Ch. 2:* the factory policies quoted from
  `/etc/default/ufw`; the conntrack accept line
  quoted from the installed `before.rules`.
- *Ch. 3:* `ufw version` (0.36.2); every file
  discussed was read from the real install —
  `ufw.conf` ships in `examples/` verbatim,
  `user.rules` is quoted with three recorded
  rules in it, `before.rules`/`after.rules`
  quoted line by line; the `--dry-run`
  architecture claim is the dry run's own
  output.
- *Ch. 4:* allow/record/delete message forms
  ("Rules updated", "Rules updated (v6)"),
  the service-name resolution (`http` → the
  port-80 tuple), the range rule's multiport
  line, and the deny/reject targets (DROP vs
  `REJECT --reject-with tcp-reset`) — all from
  dry runs; delete-by-repeating-the-rule ran
  for real against recorded rules.
- *Ch. 5:* `status`/`status verbose`/`status
  numbered` in the inactive state; `show
  added` empty and populated; `show raw` and
  `show builtins` heads; the `show user-rules`
  error ("No chain/target/match by that
  name"); `logging on` and its message; the
  `[UFW BLOCK]` logging rule from the dry run.
- *Ch. 6:* the LAN-scoped rule recorded for
  real — its single "Rules updated" (no v6
  twin for a named IPv4 subnet) and its tuple
  in `user.rules`; interface and outgoing
  rules as generated by dry runs.
- *Ch. 7:* the limit rule's three generated
  lines and the `ufw-user-limit` chain,
  captured by dry run, and the counting read
  off them (6 new connections, 30 seconds);
  the "Skipping unsupported" refusal,
  captured live; profiles end to end — the
  OpenSSH profile file verbatim from the
  openssh-server package, `app list` in its
  empty / one-profile / two-profile states,
  `app info` for both profiles including the
  case-sensitivity refusal, `app update`
  (silent success on an unchanged profile),
  the malformed-profile warning
  ("WARN: Skipping 'broken-profile': couldn't
  process"), and the profiled rule's `dapp_`
  comment in a dry run. The custom profile
  ships in `examples/` and was validated as
  INI (python3 configparser) as well as by
  UFW itself.
- *Ch. 8:* steps 1, 3, 4, 5 and the step-6
  `show added` readout are the build machine's
  own captures, in the order run. Step 2's
  divergence (the skip message instead of
  "Rule added") is stated in the chapter, not
  smoothed over. The shipped script passed
  `sh -n` and `bash -n` (no shellcheck was
  available in the sandbox); the script as a
  whole was not executed, because its last
  steps are the documented ones below.
- *Ch. 9:* `IPV6=yes` and its comment quoted
  from `/etc/default/ufw`; the v4+v6 twin
  outputs of every dual-family command above;
  `before6.rules` quoted for the RH0 drop and
  the ICMPv6 list.
- *Ch. 10:* the generated `route` rule
  (dry run) and the `ufw-user-forward` tuple;
  the three off-by-default switches, two of
  them quoted from real files
  (`DEFAULT_FORWARD_POLICY="DROP"`,
  `#net/ipv4/ip_forward=1`).
- *Ch. 11:* the `reset` output with its
  timestamped backups, captured as the build
  machine was cleaned up; the error forms
  collected through the whole build —
  "ERROR: Invalid syntax" (with usage text),
  "ERROR: Could not find profile", the
  profile warning, the limit refusal, the
  backend's RULE_APPEND failure.

**Documented-only (not run), and why:**

- *`ufw enable` and everything downstream of a
  running firewall:* the enable prompt and
  "Firewall is active and enabled on system
  startup", `disable`, active `status` /
  `status verbose` / `status numbered`
  listings (chapters 4, 5, 8), delete-by-number
  against a running listing (chapter 4), live
  `[UFW BLOCK]` lines in `/var/log/ufw.log`
  (chapter 5 — the prefix itself is verified,
  from the generated rule), limit actually
  refusing a fast connector (chapter 7), and
  boot-time activation. Why: the kernel
  refuses the match extensions UFW's rule set
  requires (probe evidence above), so no
  truthful active state was obtainable here;
  and enabling default-deny on the build
  machine itself was excluded beforehand.
  These outputs are given in UFW's canonical
  form from its documentation and the
  generated rule documents, and are marked
  **(documented)** where they appear.
- *Delete-by-number with the firewall
  inactive* was run and deliberately *not*
  taught: it walks the recorded v4 and v6
  lists in a merged order that doesn't match
  the running numbered listing (two deletions
  removed the v4 halves of two different
  rules while `show added` still displayed
  both, via their v6 halves). The chapters
  present numbered deletion only in its
  active-firewall context, marked documented,
  and say why the inactive behaviour isn't
  the model.
- *Forwarding and NAT (chapter 10):* the
  masquerade block for `after.rules`, DNAT
  port forwarding, and any actual routed
  traffic — documented from UFW's
  documentation; the sandbox has one
  interface and, per the probes, no kernel
  path to test with. The chapter's one
  generated `route` rule is verified, above.
- *Lockout recovery (chapter 11):* console
  and recovery-boot procedures are described
  without quoted output — none could be
  earned without locking the build machine,
  which is the one experiment this guide was
  never going to run.
- *Installation on the reader's machine*
  (`apt install ufw`) is described, not
  prescribed as a captured session — the build
  machine installed it its own way (ladder
  step 2), and criteria 6 applies.

Sandbox state after the build, for the
record: UFW's files reset to factory
(`ENABLED=no`, no recorded rules), the custom
test profile left in place alongside
OpenSSH's, and the kernel holding no rules.
