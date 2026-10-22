# dsh-pstack

A port of [pstack](https://github.com/cursor/plugins/tree/main/pstack) to DeepSeek Harness, tuned for this host. Ported against 0.15.30.

pstack is Lauren Tan's (poteto) set of agent workflows: a strict working style, a set of playbooks for the four kinds of engineering work, and 34 skills that encode principles about design, verification, and delegation. The upstream targets Cursor and ships a Claude Code adapter. This repo does the same job for DSH.

## What changes from upstream

The skills keep their behavior. These parts change:

- **Delegation.** Cursor's `Task` tool becomes DSH's `subagent`. There is no `subagent_type`, so a role is the brief you write, and a role's model is the `provider` / `model` / `reasoning_effort` arguments on the call.
- **Models.** Cursor reads role models from `~/.cursor/rules/pstack-models.mdc`. This port reads `config/models.yml`, with a per-user override at `~/.dsh/pstack-models.yml`.
- **Version control.** Every repo here is a colocated jj repo, so `git worktree` becomes `jj workspace add`, and stacking uses `jj rebase` / `jj squash`.
- **Verification surfaces.** `control-ui` and `control-cli` from `cursor-team-kit` become `web-verify` for web UIs and a direct run of the real binary for CLIs.
- **Commands.** `/deslop` and `/no-comments` fold into skill passes. `/loop 1h` becomes `schedule_create`.

The full mapping, including every table, is in [`docs/harness/dsh.md`](docs/harness/dsh.md). Read that once per session before following a playbook.

## Install

```bash
scripts/link-skills.sh          # symlink skills/ into ~/.dsh/skills
scripts/link-skills.sh --unlink # remove the links
```

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

The 21 `principle-*` skills keep `disable-model-invocation: true`, as upstream has them. They stay out of the model's skill catalog so every request does not pay for 21 descriptions, and the model reads the leaf file when a trigger names one.

The 13 task skills (poteto-mode, the six routines, and the writing and review passes) drop that flag, so the model can also route to them on its own when a task matches. Upstream relies on the user typing the command. On this host the model finding `bug-fix` by itself is worth 13 catalog entries.

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
        model: xai/grok-4.7
```

The standard preset already sets `modelSelectionSettings: true` on its `tool-subagent` row, so the policy above is the only missing half. Two constraints, both read from the implementation:

- The policy is sampled when a session is composed, so it applies to **new sessions only**. A session already open keeps the schema it started with.
- The row lives in the `dsh-web-app` bundle. The `headless` profile does not mount it, so headless runs always use the parent route.

With it on, `config/models.yml` names a route per role. The shipped defaults are:

| Role | Route | Effort |
|---|---|---|
| `code` | `deepseek/deepseek-v4.1-flash` | max |
| `prose`, `judgment` | `xiaomi/mimo-v2.6-pro` | high |
| `arena` (2 seats) | mimo-v2.6-pro, grok-4.7 | high |
| `interrogate_reviewers` (3 seats) | mimo-v2.6-pro, grok-4.7, deepseek-v4.1-flash | high, high, max |
| `swarm_workers` | `deepseek/deepseek-v4.1-flash` | high |

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
skills/                    34 skills, one directory each, each with SKILL.md
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
