---
name: swarm
description: "Fan out N parallel workers, drain them, and return one report. Use for /swarm, 'swarm this', or parallel coverage, races, gauntlets, and exploration."
disable-model-invocation: true
---

# Swarm

## Start

Open a todolist with one entry per phase before launching anything.

1. Frame
2. Fan out
3. Aggregate
4. Report

## Phase A: Frame

1. State the done predicate and the artifact or report the swarm must return.
2. Choose the shape. Partition into slices, race N workers on identical briefs, or mix both. For a race or mixed shape, declare `first pass`, `rank all`, or `best-of` before spawning.
3. Pick the worker model from the `swarm_workers` role in `config/models.yml` of this repo, or its per-user override at `~/.dsh/pstack-models.yml`. If the role is missing, use the file's `fallback`. Pass the role's `provider`, `model`, and `reasoning_effort` to every `subagent` call. When the role sets no model, omit `model` so the worker runs on the parent model. If the host rejects a route, use the fallback and say so in the report. If it rejects the fallback, call `list_subagent_models` and use the closest valid route of the same family. For a model race, name each arm's route up front. Pick each worker's reasoning effort for the job, per the Subagents section of the **poteto-mode** skill.
4. Give each worker its own writable output when it writes. When workers verify or measure commits, each brief names the exact revisions. A measurement brief also names the method (sample count, what one sample is, order). The worker records both in its result.

## Phase B: Fan out

Issue all N `subagent` calls in one message. They run concurrently, so there is no background flag. Each call carries its own `provider` / `model` / `reasoning_effort`, left unset when the role inherits the parent's.

A child cannot ask a question and cannot reach the user's machine beyond this host, so every brief stands alone. Include the goal, scope, exact slice or race arm, how to verify, and what to report. Reports use `PASS`, `ISSUES`, or `BLOCKED` with evidence. A worker that can prove a defect reports `ISSUES` and lists every issue it can prove, not only the first.

If a worker drops out, proceed with N-1 and note it.

## Phase C: Aggregate

Read the terminal results. Drop a result that does not record the revisions and method its brief names, and respawn that worker once. After a second miss, record a gap. A gap does not count as a pass. For coverage, every required slice needs a result. For a race, apply the selection rule declared up front. Use first pass, rank all, or best-of. Do not paste raw worker dumps.

## Phase D: Report

Return one consolidated in-chat report with the table, issue one-liners, gaps or dropouts, and the race rule when used.
