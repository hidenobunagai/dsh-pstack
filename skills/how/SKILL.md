---
name: how
description: "Use for \"how does X work\", code walkthroughs before changing something, and placement / ownership / layering questions (\"where should this live\", \"which package owns this\", \"is this the right layer\"). Explains subsystem architecture, runtime flow, onboarding mental models. Use why for motivation."
disable-model-invocation: true
---

# How

Explore the codebase to answer "how does X work?" questions. Produce architectural explanations at the level of a senior engineer onboarding onto a subsystem, enough to build a working mental model, not so much that it reads like annotated source code.

Every spawn is a `subagent` call. It has no `subagent_type`, so the role is the prompt you write, and it has no `readonly` flag, so each brief states that the work is read-only and that no files may be edited. Explorers use the `explorer` role in `config/models.yml` of this repo (or `~/.dsh/pstack-models.yml`), and every explainer uses the `explainer` role. Pass each role's `provider`, `model`, and `reasoning_effort` to the call. Leave `model` unset when a role has none, so the child inherits the parent's. If the host rejects a route, use the role's default and say so. If it rejects the default, call `list_subagent_models` and use the closest valid route of the same family. Pick each child's reasoning effort for the job, per the Subagents section of the **poteto-mode** skill.

Reference prompt templates live beside this file, at absolute paths under this skill folder. Read the template with the `read_file` tool and paste its text into the brief. A child cannot resolve a relative path against this file.

- `references/explorer-prompt.md`
- `references/explainer-prompt.md`

## 1. Assess complexity

If the scope is ambiguous, state your interpretation and explore. The user can redirect.

- **Simple** (a single module, a small utility, a narrow question such as "how does function X work"): no explorers. Spawn one explainer that explores and explains in one pass, built from `references/explainer-prompt.md` without the explorer-findings section. Go to step 4.
- **Complex** (a subsystem spanning multiple files or services, a cross-cutting feature, a full architectural overview): go to step 2.

When in doubt, take the simple path.

## 2. Explore (complex only)

Decompose the question into 2 to 4 angles, each a distinct slice of the subsystem. Issue all explorer calls in a single message, each with `references/explorer-prompt.md` and its angle filled in.

## 3. Synthesize (complex only)

Once all explorers have returned, spawn one explainer with `references/explainer-prompt.md` and every explorer's findings filled in.

## 4. Present

Present the explainer's output. Light edits for clarity or context from the conversation are fine. Do not substantially rewrite it.

## Output format

The explanation uses the sections defined in `references/explainer-prompt.md`, dropping any that do not apply: Overview, Key Concepts, How It Works, Where Things Live, Gotchas.
