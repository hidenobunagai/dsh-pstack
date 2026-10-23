# pstack in DeepSeek Harness

pstack skills use Cursor names. In DSH, read this file once per session, then map each Cursor name in a skill with the tables below. `<pstack>` means the folder that holds `skills/` and `docs/`. If a Cursor field has no row, drop it and say so. Never pass a field or an option that DSH does not accept.

## Tool mapping

| Cursor | DSH |
|---|---|
| `Task` tool | `subagent` tool. `subagent_fork` when the child needs this conversation. |
| `subagent_type: generalPurpose` | No field. The prompt you write is the role. |
| `subagent_type: "poteto-agent"` | No field. Write the delegation brief yourself. |
| `readonly: true` | No field. State "this is read-only, do not edit files" in the prompt, and rely on the session's permission preset. |
| `model` | `provider` plus `model` plus `reasoning_effort` on the `subagent` call. |
| `run_in_background: true` | No field. Issue the calls in one message so they run concurrently. |
| `environment: "cloud"` | No field and no equivalent. Every child runs in this process on this host. |
| `Task` response body | The child's final message, delivered by `send_message`. |
| Resume a child | `send_message` to the child's `agent_id`. |
| `TodoWrite` | `todo_write`. |

## Model roles

Cursor reads role models from a `pstack-models.mdc` rule. DSH reads them from `config/models.yml` in this repo, with a per-user override at `~/.dsh/pstack-models.yml`. Both use the same role names. See `config/models.yml` for the shipped defaults and the resolution order.

A role entry is `provider/model` plus an optional `effort`. Pass them to `subagent` as `provider`, `model`, and `reasoning_effort`. Call `list_subagent_models` when you need the exact routes and efforts this host advertises rather than guessing.

Families in the upstream fallback rules map by prefix: a `claude-*` entry needs a Claude route on a registered provider, a `grok-*` entry needs an `xai/*` route, and so on. When a requested route is rejected, use the role's default and say so in the reply.

The user's subagent settings page governs which routes a child may select at all. A route outside that allowlist fails no matter what the role file says.

## Effort

`reasoning_effort` is a per-model enum, and a value above the model's ceiling is clamped down rather than rejected. The ceiling differs by family, so a panel that mixes families has to normalize:

| Model | Efforts |
|---|---|
| `deepseek/deepseek-v4.1-flash` | low, high, max |
| `z-ai/glm-5.3-flash` | low, high, max |
| `xiaomi/mimo-v2.6-pro` | low, medium, high |

The parent turn's effort is owned by the `dsh-jev` router, which judges each user prompt and applies a per-model lift. For `deepseek/deepseek-v4.1-flash` every judgment from `medium` up lands on `max`. A skill should not fight it. Child effort is set by the role table instead, and the router does not decide that.

## Control skills

Cursor's `control-ui` and `control-cli` from `cursor-team-kit` are not available. Map by surface:

| Surface | DSH substitute |
|---|---|
| Web UI | the `web-verify` skill (Playwright screenshots plus console and network errors) |
| CLI or TUI | run the real binary and capture its output; no wrapper skill |
| Recorded demo | the `readme-demo` or `web-demo-video` skill |

Where a skill says a surface with no control skill is a risk, check that skill's own risk section.

## Commands

| Cursor command | DSH |
|---|---|
| `/deslop` | Fold into the `unslop` skill pass over the diff before commit. |
| `/no-comments` | Fold into the `Comments` section of `poteto-mode` and the `no-comments` skill when it is installed. |
| `/technical-writing` | The `technical-writing` skill. |
| `/loop 1h` | `schedule_create` with `every_seconds: 3600`. |

## Version control

Cursor skills assume `git` and `git worktree`. Every repo on this host is a colocated jj repo.

| Cursor | DSH |
|---|---|
| `git worktree add` | `jj workspace add <path>` |
| `git reset --hard origin/<branch>` | `jj git fetch` then `jj new <bookmark>@origin` |
| `git commit` | `jj commit -m "..."` |
| squash / reorder into a stack | `jj squash`, `jj split`, `jj rebase` |
| push | `jj bookmark set <name> -r @-` then `jj git push -b <name>` |
| `git show origin/main:<path>` | `jj file show -r <bookmark>@origin <path>` |

Never run a git write command. Read-only `git` and `gh` are fine, and `gh` stays the forge CLI.

## Skills

| Cursor | DSH |
|---|---|
| `.cursor/rules` always-applied rule | `AGENTS.md`, or a `customSkillDirs` entry that is read on demand |
| skill `icon` / `color` fields | dropped |
| `disable-model-invocation: true` | keep it for the `principle-*` skills. It keeps them out of the model catalog so every request does not pay for 21 descriptions, and the model reads the leaf file directly. The user-facing task skills drop it, so the model can also route to them on its own. |
| relative reference to a sibling skill | an absolute path, because a subagent's working directory may differ |
| `references/*.md` | the same relative path from the skill folder |
| `.cursor/skills/<name>/` (a generated project skill) | `~/.dsh/skills/<name>/`. DSH discovers skills only there, one level deep, or in a `customSkillDirs` entry. |
| `/setup-pstack`, the `pstack-models.mdc` rule | `config/models.yml` and `~/.dsh/pstack-models.yml`. See Model roles. |

## Transcripts and memory

| Cursor | DSH |
|---|---|
| Transcripts in `~/.cursor/projects/<slug>/agent-transcripts/` | `~/.dsh/sessions/<slug>/<session-id>/session.v4.jsonl.zstd`. The slug is the workspace path with `/` turned into `-` and wrapped in `-`, so `/home/pi` is `--home-pi--`. List `~/.dsh/sessions/` to confirm. The files are zstd-compressed JSONL: read them with `zstdcat <file>`, never with `read`. Read only this workspace's folder. |
| Past sessions and decisions (`recall`, `why`, session pickup) | Search the shared memmini memory first with `memory_smart_search`, using the user's wording, then read transcripts for what it misses. memmini is a lead, not a citation: check a hit against the code or the history before you rely on it. |

## Local equivalents

| Cursor | DSH |
|---|---|
| Bugbot or an agentic review pass | The `interrogate` skill. |
| Cursor cloud agent, its own machine | No equivalent. Every child runs on this host. Skip a step that needs one, and say so. |
| `/create-skill` | Write `~/.dsh/skills/<name>/SKILL.md` directly, then run `node <pstack>/scripts/check-skills.mjs` when the skill lives in this repo. |

## Comments

Code on this host is also written by agents running the ponytail working style, which marks a deliberate shortcut with a `ponytail:` comment that names its ceiling and upgrade path. Those comments are load-bearing. Every comment pass, including `no-comments`, keeps them.
