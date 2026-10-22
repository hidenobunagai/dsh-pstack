### Multi-phase or multi-PR plan

**You own the plan, not the code. The plan is a checklist an owner runs box by box and the operator audits from the evidence.** The plan is the deliverable. Do not implement.

1. When the change is one or two files with an obvious approach, skip the plan. Say so and stop.
2. Settle open questions by prototype before you write. Run `playbooks/prototype.md` for each. Keep the commit id and the screenshots for Appendix A. Ask the operator only about a product or preference call that no run can settle. Give options (the **never-block-on-the-human** principle skill).
3. Explore in subagents, one per angle, all issued in one message. Take their routes from the `explorer` role in `config/models.yml` of this repo (or `~/.dsh/pstack-models.yml`). Pick each one's reasoning effort for the job, per the Subagents section of the **poteto-mode** skill. Each returns file pointers, conventions, test commands, and entry points. No inlined dumps (the **guard-the-context-window** principle skill).
4. Copy the skeleton below into the plan file and fill every placeholder. Unless the operator names a path, write the file under `docs/plans/` in the work repo. Keep every heading and every sub-block in the order shown. One section per PR. One PR is one change with its own evidence (the **sequence-verifiable-units** principle skill). Name the execution playbook in **How to read this**.
5. Write under the `technical-writing` skill in full, then the `unslop` skill. The body is one Diátaxis mode, how-to. Appendices hold explanation and reference. Each heading states the task or the finding. No long dashes. No mid-sentence colons.
6. Run `node scripts/check-plan.mjs <plan.md>` and fix every line it prints (the **encode-lessons-in-structure** principle skill).
7. Hand back. Post the plan path and the script's output, then stop. Execution starts on the operator's explicit go, under the execution playbook the plan names.

**Verification.** Tests alone are not sufficient verification. A PR is verified only when its unit, live, and perf boxes are all checked (the **prove-it-works** principle skill). That sentence is the verification rule. Every verification block opens with it. The live block is mandatory. Ten lanes at the PR head drive the real surface through its control skill, per the **swarm** skill, on the `swarm_workers` role. Each lane is one box with a concrete scenario, the screenshot it saves, and its pass predicate. One lane is the **Regression lane against trunk.** It runs the same load-bearing scenario on trunk and head. If trunk does not have the feature, the lane records that fact and gates the behavior the diff adds plus the end state the user waits for instead of inventing a trunk result. The perf gate is dual-sided. Trunk and head must both produce the named metric. If trunk lacks the feature, also isolate the work the diff adds and set an absolute budget for that work plus the end-to-end state the user waits for. Do not claim a ratio between unlike scenarios. The perf block names the metric, the interleaved probe, the trunk baseline measured first, and the rule with the number that fails. A PR that changes an interaction is review-gated. The operator reviews it in chat with screenshots and a video before merge. A PR that changes no interaction writes `**Review gate.** None. <PR id> is not review-gated.` and no boxes under it.

**Control skill.** Pick it by surface. Web UIs and browsers use the `web-verify` skill. CLIs and TUIs are driven by running the real binary and capturing stdout and exit codes. Recorded demos use `readme-demo` or `web-demo-video`. Native mobile uses whatever simulator-driving skill the repo has. A PR that touches two surfaces gets lanes on both. A surface with no control skill is a risk in Appendix C, and its live block still names how each lane drives it.

````markdown
# <Program> plan

<Under ten lines. What changes, for whom, the rule the program enforces, and the PR ids in order.>

## How to read this

One box is one unit of work. Every box names the evidence that checks it. A nested box is a sub-step of the box above it. Check a box only when its evidence exists, a file, a log line, a screenshot, a test run, or a commit id. The body is a how-to. The appendices explain and record.

The program runs `playbooks/<execution playbook>.md`. <Who merges, and which PR ids are the operator's items that stop at merge-ready.>

Tests alone are not sufficient verification. A PR is verified only when its unit, live, and perf boxes are all checked.

## Program checklist

### Arm the program

- [ ] State the protocol and this plan to the operator, then stop. Start execution only on the operator's explicit go.
- [ ] Read these from trunk at program start. Re-read them at every tick.
  - [ ] `jj file show -r main@origin playbooks/<execution playbook>.md`
  - [ ] `jj file show -r main@origin skills/swarm/SKILL.md`
  - [ ] `jj file show -r main@origin <control skill path>`
  - [ ] `jj file show -r main@origin playbooks/opening-a-pr.md`
  - [ ] `jj file show -r main@origin <each other leaf skill the program uses>`
- [ ] On the operator's go, arm the audit tick with `schedule_create` at `every_seconds: 3600` and the tick prompt below. Never leave the cadence to memory.
- [ ] Use this tick prompt, verbatim. "Re-read the execution playbook from trunk. Audit the operation against it and fix drift in this tick. Probe every active lane and judge progress by side effects only. Stand down a stuck lane and dispatch its replacement now. Then post a short status message to the operator in chat only when the audit found a tracked change that no earlier status message reported, such as a PR opened, a code-ready head, a round launched or closed, a verdict, a merge, a stuck agent and the action taken, a blocker added or cleared, or a decision only the operator can make. Name every such change and nothing else. Do not repeat a table, the merged list, or an unchanged blocker. If the audit found none, end the turn with no reply text. Either way, log this tick's row in your decision trail. The row names the items reported, or none."
- [ ] On the operator's hold or stand-down, send every owner a zero-writes order at once.

### Spawn owners

- [ ] Spawn one owner per PR with the full lifecycle the execution playbook names.
- [ ] Follow this dependency graph. Start dependent work only after its parent merges, or base it on the parent bookmark when the execution playbook stacks.
  - [ ] <PR id> and <PR id> are independent and first. Both branch from trunk.
  - [ ] <PR id> after <PR id>.
- [ ] Hold the file boundaries. <PR id or class> touches only `<glob>`.
- [ ] Hold the review gate. <PR ids> change an interaction. They wait for the operator's review in chat with screenshots and a video before merge.

### PR mechanics, for every PR

- [ ] Resolve the forge once. Default to `gh`; if `command -v origin` succeeds and Origin can resolve the repository, use `origin pr` for every PR operation. Record any fallback to `gh`. Never require `gt`.
- [ ] Open the PR ready, never draft, per **Opening a PR**. Use `origin pr create --status open --base <base-branch>` or `gh pr create --base <base-branch>` according to the resolved forge. A stack child targets its parent branch.
- [ ] Run the repo's lint and typecheck once before the PR-facing push. Push with hooks on.
- [ ] Run the `unslop` skill before each commit and the `no-comments` pass before review.
- [ ] Triage every bot and security-reviewer comment per `references/bot-triage.md`.
- [ ] Rebase onto current trunk before the code-ready report and babysit. Keep that merge base in fix rounds. Rebase again only at merge prep, on a conflict with trunk, or on a CI failure that comes from a change on trunk.

### Verdict and merge, for every PR

- [ ] A full swarm runs once, at the code-ready head. Another full swarm runs only for new behavior, a redesign, or a large new diff. A rebase, a merge-conflict resolution, or a minor fix gets a single verifier at the new head. Run each full swarm per `skills/swarm/SKILL.md`. One gates lane. The ten live lanes from the PR's **Verify, live** block. The perf lane from its **Verify, perf** block. Two or more audit lanes, each with its own focus, that read the diff and the receipts and distrust the PR body. The root audits the receipts in the merge-ready report before the verdict.
- [ ] Clean only when every lane is `PASS`. Findings go back to the owner, including a defect that a lane filed as a note. A new head gets a fresh verdict.
- [ ] <The merge or append rule from the execution playbook.>

### Boot recipe, for every live lane

Each live lane runs on its own jj workspace at the PR head. Drive through the control skill the surface names.

- [ ] `jj workspace add /tmp/lane-<n> --revision <head commit>`.
- [ ] <Start the backend and the surface. Wait for ready.>
- [ ] <Deliver input only through the control skill's commands. Name the read-only diagnostics.>
- [ ] <Capture the screenshot or the log line that carries the pass predicate.>
- [ ] <Tear down the workspace.>

### Per-PR skeleton

Repeat this block once per PR.

**PR <id>.** <One line: what it does and the invariant it holds.>

**Depends on.** <PR id, or None.>

**Files.**

- [ ] Edit `<path>`.
- [ ] Create `<path>`.
- [ ] Delete `<path>`.

**Build.**

- [ ] <One change. Name the symbol and the file.>

**You see.**

- [ ] <One observable result, with the exact log line or screen state.>

**Verify, unit.**

- [ ] <Command and its passing output.>

**Verify, live.**

- [ ] <Lane 1..10: scenario, screenshot path, pass predicate.>

**Verify, perf.**

- [ ] <Metric, probe, trunk baseline, failing rule.>

**Review gate.** <None, or the operator's review items.>

## Appendix A: prototypes

<One entry per prototype: the question, the commit id, the screenshots, the verdict.>

## Appendix B: decisions

<One row per decision: what, why, evidence. Or point at the decision trail the **show-me-your-work** skill keeps.>

## Appendix C: risks

<Each risk with its surface, why it is a risk, and the mitigation. A surface with no control skill goes here.>
````
