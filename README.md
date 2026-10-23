# dsh-pstack

A port of [pstack](https://github.com/cursor/plugins/tree/main/pstack) to DeepSeek Harness, tuned for this host. Ported against 0.15.30.

This is an unofficial personal fork. It is not affiliated with or endorsed by the author or Cursor. Provided as-is, with no support. Issues and pull requests may go unanswered. Fork it and make it yours.

pstack is Lauren Tan's (poteto) set of agent workflows: a strict working style, a set of playbooks for the four kinds of engineering work, and 49 skills that encode principles about design, verification, and delegation. The upstream targets Cursor and ships a Claude Code adapter. This repo does the same job for DSH.

## What changes from upstream

The skills keep their behavior. These parts change:

- **Delegation.** Cursor's `Task` tool becomes DSH's `subagent`. There is no `subagent_type`, so a role is the brief you write, and a role's model is the `provider` / `model` / `reasoning_effort` arguments on the call.
- **Models.** Cursor reads role models from `~/.cursor/rules/pstack-models.mdc`. This port reads `config/models.yml`, with a per-user override at `~/.dsh/pstack-models.yml`.
- **Version control.** Every repo here is a colocated jj repo, so `git worktree` becomes `jj workspace add`, and stacking uses `jj rebase` / `jj squash`.
- **Always-on poteto-mode.** A SessionStart hook (`hooks/poteto-always.sh`) injects `skills/poteto-mode/SKILL.md` into every session, the way Cursor pins a custom mode. Say "poteto-mode off" to drop it for a session. It stays on in headless runs too, including the scheduled jobs. `PSTACK_POTETO=off` in the environment is kept as an escape hatch that skips it.
- **Verification surfaces.** `control-ui` and `control-cli` from `cursor-team-kit` become `web-verify` for web UIs and a direct run of the real binary for CLIs.
- **Commands.** `/deslop` and `/no-comments` fold into skill passes. `/loop 1h` becomes `schedule_create`.

The full mapping, including every table, is in [`docs/harness/dsh.md`](docs/harness/dsh.md). Read that once per session before following a playbook.

Left out on purpose: `make-bot-ui` and `automate-me` (Cursor-only), `setup-pstack` (DSH reads `config/models.yml`), `statechart` and the formal verification skills (they need Java and TLA+), `typescript-best-practices` (the host has its own TypeScript standards), and `bro`.

Like the Claude Code fork, this port keeps `ponytail:` comments through every comment pass and searches the shared memmini memory first in `why` and `recall`.

## Install

```bash
scripts/link-skills.sh          # symlink skills/ into ~/.dsh/skills
scripts/link-skills.sh --unlink # remove the links
```

The always-on hook needs a second `@deepseek-ai/dsh-hooks-claude-code` row (id `hooks-pstack`) in `~/.dsh/cordis.patch.yml` with `configPath` set to this repo's `hooks/hooks.json`.

DSH discovers `~/.dsh/skills/<name>/SKILL.md`. The links point at this repo, so an edit here lands in the catalog without reinstalling. A running web host may need a reload to pick up a new skill name.

Validate before installing:

```bash
node scripts/check-skills.mjs
```

## Use

Type `/poteto-mode` or say "poteto" to enter the working style. From there the playbooks route by task:

| Task | Playbook |
|---|---|
| Read-only question | `skills/poteto-mode/playbooks/investigation.md` |
| A reported defect | `skills/poteto-mode/playbooks/bug-fix.md` |
| New behavior | `skills/poteto-mode/playbooks/feature.md` |
| Behavior-preserving restructure | `skills/poteto-mode/playbooks/refactoring.md` |
| Work spanning phases or PRs | `skills/poteto-mode/playbooks/multi-phase-plan.md` |
| Any of the above, at the end | `skills/poteto-mode/playbooks/opening-a-pr.md` |

The supporting skills are user-invocable in their own right: `how`, `why`, `architect`, `arena`, `swarm`, `interrogate`, `reflect`, `unslop`, `no-comments`, `technical-writing`, `show-me-your-work`, `benchmark-checklist`.

## Catalog visibility

The 24 `principle-*` skills keep `disable-model-invocation: true`, as upstream has them. They stay out of the model's skill catalog so every request does not pay for 24 descriptions, and the model reads the leaf file when a trigger names one.

The 25 task skills (poteto-mode, the routines such as how, why, recall, teach, tdd, and figure-it-out, and the writing and review passes) drop that flag, so the model can also route to them on its own when a task matches. Upstream relies on the user typing the command. On this host the model finding `bug-fix` by itself is worth 25 catalog entries.

## Model roles

**This only works when child model selection is on.** In the default configuration the `subagent` tool declares just `prompt`, `description`, and `cwd`, so every child runs on the parent's route and the roles below stay inert. The skills detect this from the tool's own schema and fall back to getting diversity from the briefs.

To turn it on, add this to `~/.dsh/cordis.patch.yml`:

```yaml
- id: subagent-model-selection-settings
  config:
    enabled: true
    allowedModels:
      - provider: commandcode-goat
        model: deepseek/deepseek-v4.1-flash
      - provider: commandcode-goat
        model: xiaomi/mimo-v2.6-pro
      - provider: commandcode-goat
        model: z-ai/glm-5.3-flash
```

The standard preset already sets `modelSelectionSettings: true` on its `tool-subagent` row, so the policy above is the only missing half. Two constraints, both read from the implementation:

- The policy is sampled when a session is composed, so it applies to **new sessions only**. A session already open keeps the schema it started with.
- The row lives in the `dsh-web-app` bundle. The `headless` profile does not mount it, so headless runs always use the parent route.

With it on, `config/models.yml` names a route per role. The shipped defaults are:

| Role | Route | Effort |
|---|---|---|
| `code` | `deepseek/deepseek-v4.1-flash` | max |
| `prose`, `judgment` | `xiaomi/mimo-v2.6-pro` | high |
| `arena` (2 seats) | mimo-v2.6-pro, glm-5.3-flash | high, high |
| `arena_judge` | deepseek-v4.1-flash | max |
| `interrogate_reviewers` (3 seats) | mimo-v2.6-pro, glm-5.3-flash, deepseek-v4.1-flash | high, max, max |
| `swarm_workers` | `deepseek/deepseek-v4.1-flash` | high |

Effort is set to each model's ceiling rather than one value across the board. MiMo V2.6 Pro stops at `high`, so an arena seat on MiMo cannot go deeper; the GLM seat is held at `high` as well so the two candidates are compared at the same depth. The review seats keep `max` on the models that accept it, because a review is a single diff read rather than a long loop.

Why these and not a premium reasoning model: `subagent` calls run an agent loop, so input volume dominates and a $2/$6 route costs roughly ten times a $0.15/$0.5 one. `z-ai/glm-5.3-flash` carries the highest measured intelligence of the cheap tier (57.5) and a different training lineage from MiMo and DeepSeek, which is the property the arena and the adversarial reviewers actually need. Diversity comes from the family, not the price tag.

Deliberately avoided: `xai/grok-4.7` at $2/$6 for no measured intelligence gain, and the `*-contributor` routes. Those are 95% cheaper but trade data contribution for the discount, which is the wrong deal for work that touches private repos.

To override a role without editing the repo, write `~/.dsh/pstack-models.yml` with the same shape and only the roles you want to change. It wins over this file.

Check what the host actually advertises before trusting a route. Call `list_subagent_models` with no arguments to list providers, then with a provider id for its models and efforts. The settings page gates which routes a child may select at all, so a role naming a route that is not checked there fails even with the flag on.

## Keeping up with upstream

The upstream is vendored as a snapshot for diffing:

```bash
scripts/sync-upstream.sh          # fetch cursor/plugins at main, refresh .upstream-snapshot
scripts/sync-upstream.sh --check  # report files that changed, change nothing
```

A sync does not rewrite the port. It tells you what moved, and you decide which ports to redo.

## Layout

```
skills/                    49 skills, one directory each, each with SKILL.md
  poteto-mode/             the working style
    playbooks/             one per kind of task
    scripts/check-plan.mjs validates a multi-phase plan
  how/ why/ architect/ …   supporting skills, some with references/
config/models.yml          role to route mapping
docs/harness/dsh.md        the Cursor to DSH mapping
scripts/link-skills.sh     install into a DSH skills root
scripts/check-skills.mjs   validate skills
```

## License and provenance

Ported from pstack (0.15.30 at the time of writing) by Lauren Tan, MIT licensed. The upstream LICENSE is in this repo. Skill text is derived from the upstream and rewritten for DSH; the changes are the mapping above, not the ideas. Anything wrong with the port is the port's fault, not upstream's.
