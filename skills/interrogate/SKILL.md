---
name: interrogate
description: "Use for \"interrogate\", \"adversarial review\", \"multi-model review\", \"challenge this\", \"stress test this code\", \"find blind spots\", or \"tear this apart\". Multiple LLM reviewers challenge changes from independent angles."
---

# Interrogate

Spawn one reviewer per configured model to adversarially review code changes. The adversarial signal comes from model diversity, not assigned personas. The deliverable is a synthesized verdict. Do NOT auto-apply changes.

## Step 1, Scope

Identify what to review from context:

- If the user points at specific files or a diff, use that.
- If on a feature branch, run `jj diff --from <bookmark>@origin` for the full changeset. Fall back to `git diff main...HEAD` only when the repo is not colocated.
- If the user's message references recent work, gather the relevant files.

Package the diff or file contents with any surrounding context files the reviewers need to understand the code.

## Step 2, Intent

Before spawning reviewers, state the intent in one clear paragraph from the user's message, commit messages, the PR description if one exists, and the code. If you're unsure about the intent, ask the user via `ask_user_question` before proceeding.

## Step 3, Spawn Reviewers

Launch all reviewers in a single message, one `subagent` call per seat on the `interrogate_reviewers` role, labeled Reviewer A, B, and so on to match the seat count.

Each reviewer's brief states that the review is read-only and that no file may be edited. There is no read-only flag on the tool, so the brief carries that constraint.

Model diversity is this skill's whole signal. When the session cannot select child models, every reviewer shares the parent route, so assign each reviewer a different lens instead. Give one the correctness and failure modes, one the design and structure, one the tests and what they fail to cover. Read `references/rubric.md` and split it rather than handing every reviewer the whole thing. Per the shared rule below.

**Child model selection may be unavailable.** Before the first spawn in a session, glance at the `subagent` tool's own schema. When it declares `provider`, `model`, and `reasoning_effort`, pass the role's route from `config/models.yml` of this repo (or the user's `~/.dsh/pstack-models.yml`). When it declares only `prompt`, `description`, and `cwd`, every child runs on the parent's route: omit the route entirely, and get the diversity this step needs from the briefs instead. Never pass a field the schema does not declare.

Read `references/reviewer-prompt.md` and fill in the same template for every reviewer with the stated intent, the diff or file contents, the rubric from `references/rubric.md`, and the code-quality lens from `references/code-quality-review.md`. Pick each reviewer's reasoning effort for the job, per the Subagents section of the **poteto-mode** skill.

## Step 4, Synthesize

As results come back, build a unified picture. Parse every reviewer's findings. Merge findings that describe the same issue differently, and note which models raised each one. Findings two or more models raised independently are the highest signal. Read a lone model's finding, but weight it accordingly. Note disagreements. If one model flags something and another explicitly says the opposite, that is context for the verdict.

## Step 5, Lead Judgment

You are the lead reviewer, a pragmatic senior engineer, not a neutral aggregator. Read `references/lead-judgment.md` for the full framework. Put every finding in one of four buckets, with the model(s) that raised it and a one-line rationale.

- **Act on**. Real issues affecting correctness, security, or maintainability given the actual goals. They would block a real PR.
- **Consider**. Legitimate, but you're not sure they outweigh the cost of addressing them now. Worth the user's attention.
- **Noted**. Technically valid but not actionable. Context-dependent, premature optimization, or low-impact at this stage.
- **Dismissed**. Wrong, nitpicky, or missing context, with a brief reason.

## Output Format

### Intent
> [The stated intent paragraph from Step 2]

### Reviewers
- Reviewer [label]: [model name], [N findings] (one bullet per reviewer)

### Act On
[Each: description, which models raised it, why it matters.]

### Consider
[Each: description, which models raised it, the tradeoff.]

### Noted
[Brief list.]

### Dismissed
[Each with a brief rationale.]

### Agreement Map
[Where models agreed and diverged, and what that pattern tells us.]
