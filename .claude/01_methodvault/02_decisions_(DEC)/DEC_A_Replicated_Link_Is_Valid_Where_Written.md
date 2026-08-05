---
domain: DEC
id: DEC-MTH-024
created: 2026-08-05
last-verified: 2026-08-05
---
Date: 2026-08-05
Status: Accepted
Migrated 2026-08-05 from the appended decision log, "Amendment 2026-08-05c — A replicated link is valid only where it was written (Accepted)". Its `Measured on …` section keeps its position directly behind the context, as the last subsection of `## Context`.

## Context

`~/.claude/skills/mechatronics-docs` is a symlink into this repository,
created by the command the README told people to run. `~/.claude/skills/`
is also a Syncthing folder root, and Syncthing replicates a symlink as an
entry of its own type carrying the target as a string (BEP v1,
`symlink_target`); it never follows or dereferences one on Linux. So the
authoring host's path travels to every peer, and on a host that does not
have that path the entry reaches nothing.

Nothing in this repository could see that. The skill listing shows the
entry either way — it is the invocation that fails — the validator had no
opinion about its own installation, and the install command was the thing
producing the state. Issue #40 ran seven days on the server before anyone
noticed, during which documentation was written against the conventions
file with none of this layer's checks running.

### Measured on the two hosts, 2026-08-05

`--check-install`, run through the repository path on each:

| host | entry | stored target | verdict |
| --- | --- | --- | --- |
| laptop | `/home/jerome/.claude/skills/mechatronics-docs` | `/home/jerome/Documents/innovation/…` | reaches this copy, exit 0 |
| userver | `/home/asteraa/.claude/skills/mechatronics-docs` | `/home/jerome/Documents/innovation/…` | DANGLING, exit 1 |

Same replicated byte string, two verdicts. That is the defect stated as a
measurement rather than as an argument.

## Options

- **A — A relative symlink.** Rejected on the layout. GNU documents a
  relative link as the answer when the link is visible from more than one
  machine, but only while link and target keep the same relative
  relation. Here the repository sits at `~/Documents/innovation/…` on one
  host and `/srv/data/sync/Innovation/…` on the other while the link
  stays in `~/.claude/skills/`, so the relative path differs too.
- **B — Replicate the skill directory instead of a link.** Rejected
  twice over. `tests/run.sh` derives the template vault three levels
  above the skill directory and, since the guard was made loud, fails
  when it is absent — a copy under `~/.claude/skills/` puts that
  assertion permanently red. And two replicated folders holding the same
  bytes drift with nothing to arbitrate between them.
- **C — Ship it as a marketplace plugin.** Real, and the right answer for
  someone who only consumes this template: the install lands outside the
  replicated directory and stores no host path. Rejected for the people
  who develop the skill, because a marketplace plugin is copied into
  `~/.claude/plugins/cache` keyed by the manifest `version` — a change in
  the working tree reaches no session until commit, push, marketplace
  update and a version bump.
- **D — Keep the absolute link, take the entry out of the replication per
  device, and let the validator say what the entry reaches (chosen).**
  The precedent was already on the affected machine: the neighbouring
  `omarchy` entry is an absolute symlink into a host-local path and has
  never caused trouble, because one line of `.stignore` keeps it from
  replicating.

An installer script was designed for D and rejected before implementation.
The adversarial review found it would write the link before the ignore
line — reproducing the defect in the opposite direction, since the new
link can be scanned before the pattern is loaded — depend on GNU-only
`mv -T` in a public template, and add a predictable temporary symlink plus
an append that follows a symlink, both inside a directory peers write to
(CWE-59, CWE-61). The one thing it would have bought, an ignore line that
does not depend on being typed per machine, it cannot buy: a new device
runs the installer after Syncthing has already scanned.

## Decision

D. `--check-install` reports what the personal entry reaches; the README
says the global entry is the special case and how to keep it out of a
replicated directory; `SKILL.md` stops naming one host's home path.

## Justification

### Design points

- **`is_symlink()` before `exists()`, and this is the whole check.**
  `exists()` follows the link and is `False` for a dangling one — the
  exact state this exists for. Mutation: asking about existence first
  reports the server's dangling entry as absent and exits 0.
- **Readability is not the check.** An entry reaching a second clone of
  the template, or a replicated copy of the skill directory, opens
  `SKILL.md` fine and serves a version nobody is editing. The resolved
  target is compared against the validator's own directory. Mutation:
  dropping that comparison passes both wrong shapes.
- **Absent is exit 0.** Carrying the skill only inside the project is how
  this template ships, and a CI runner has no `~/.claude` at all. The
  cost is that an entry a Claude Code update removed
  (anthropics/claude-code#50052) also reports 0; the message names that
  case rather than guessing which one it is looking at.
- **The check is a flag on the validator, not a new program.** Stdlib
  only, writes nothing, and testable with the fixture pattern the suite
  already has — where a shell installer would have introduced the first
  code in this repository that writes into `$HOME`.
- **`${CLAUDE_SKILL_DIR}`, not the two-candidate probe.** The probe in
  this file's own hook definitions works because hooks are given
  `CLAUDE_PROJECT_DIR`. A bash call the model types from prose is not, so
  the probe would expand its first candidate to `/.claude/skills/…` and
  fall through to `$HOME/.claude/skills/mechatronics-docs` — the very
  path this amendment removes.
- **The suite's trap chain is replaced, not extended.** Bash substitutes
  the `EXIT` handler, so only the last one runs; the chain had already
  stopped removing two fixture directories. The new one lists all of them.

## Consequences

### Accepted residuals (documented, not solved)

1. **`.stignore` lives in no repository.** It is per device by design and
   is never replicated, so a rebuilt machine has no line, pulls the
   replicated entry again, and gets the same silent break. Syncthing
   writes no `.sync-conflict` copy for a symlink, so nothing marks the
   moment. `--check-install` detects the state; nothing prevents it.
2. **A removed entry and a deliberate project-only setup are the same
   observation**, and both exit 0. Distinguishing them needs a record of
   what the user intended, which this layer does not keep.
3. **Only the personal entry is checked.** The project-level workaround in
   place on the server — a gitignored `.claude/skills/mechatronics-docs`
   inside one unrelated project — is invisible to it.
4. **One host at a time.** Nothing in this repository knows the set of
   machines an entry is replicated to, so a green check on the machine you
   are sitting at says nothing about the other one.

### Realization

- `validate_vault.py` — `check_install()` and the `--check-install` mode
- `SKILL.md` — step 7 loses the hardcoded home path for
  `${CLAUDE_SKILL_DIR}`; the enforcement section names the check and when
  to run it
- `README.md` — the install section leads with "nothing to install in a
  project made from this template", gives `ln -sfn`, the anchored
  `.stignore` line for either folder root, and the check
- `tests/run.sh` — fixture 9, 245 to 251 assertions

Observed at the real entry point, the server before remediation:

    this copy:      /srv/data/sync/Innovation/obsidian-engineering-vault/…
    personal entry: /home/asteraa/.claude/skills/mechatronics-docs
      link target:    /home/jerome/Documents/innovation/…
      DANGLING - that path does not exist on this host.

Seven days of silence, printed in four lines.
