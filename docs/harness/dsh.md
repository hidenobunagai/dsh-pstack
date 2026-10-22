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
