# Platforms: Claude Code and DSH

RevRef is a set of Markdown instructions, scripts and git protocols, so it works in any agent that can read files, run commands and work with git. There are two main platforms: **Claude Code** and **DSH** (DeepSeek Harness). Their rules, protocols and `.revref/` files are the same; tools, subagents, the guard check and the token limit differ. Read this file together with `SKILL.md`; it does not override `ORCHESTRATOR.md`, `PIPELINE.md`, `POLICY.md` or `PROTOCOLS.md`.

## Detecting the platform

- **Claude Code:** the tools `Task` (named agents), `Bash`, `Read`, `Write`, `Edit`, `TodoWrite` exist; hooks from the `SKILL.md` frontmatter run.
- **DSH:** the tools `subagent` (or `subagent_fork`), `pwsh` on Windows or `bash` on macOS and Linux, `read`/`write`/`edit`, `todo_write` exist; the `/revref` command is discovered from `~/.dsh/skills/revref` or `<project>/.dsh/skills/revref`; hooks do not run.

If the platform is unclear, look at the tool list in the system prompt. Everything not described below is identical.

## Tool mapping

| Task | Claude Code | DSH |
|---|---|---|
| Shell command | `Bash` (on Windows — `PowerShell`) | `pwsh` (Windows) or `bash` (macOS, Linux) |
| Read a file | `Read` | `read` |
| Write and edit | `Write`, `Edit` | `write`, `edit` |
| Find files and lines | `Glob`, `Grep` | `glob`, `grep` |
| Task list | `TodoWrite` | `todo_write` |
| Subagent | `Task` (named agent or general-purpose) | `subagent` (fresh child), `subagent_fork` (with a prefix of the parent's history) |
| Ask the owner | `AskUserQuestion` | `ask_user_question` |
| Web | `WebFetch`, `WebSearch` | `web_fetch`, `web_search` |

## Subagents

### Claude Code

The role is passed to a named agent (`revref-reviewer`, `revref-verifier`, `revref-fixer`) or to a general-purpose agent; the `Task` call is synchronous and returns the result. The fixer runs with `isolation: "worktree"`.

### DSH

- **The call is asynchronous.** `subagent` returns `started subagent <id>` immediately, and the child's final text arrives later as a separate message in the parent's history. Do not wait for it synchronously, do not poll and do not sleep: start a batch of independent children in one message, continue useful work (state files, checkpoint), and end the turn when there is nothing left to do — the notice wakes an idle parent.
- **The child does not see your context.** Put everything it needs into `prompt`: the role description, the task package from `PROTOCOLS.md` §1, absolute paths to prompts, the area and the constraints. If there is no `Task` tool, the child reads its role from `roles/<role>.md` by an absolute path.
- **Limits.** By default up to 8 live children per tree, with no queueing, and depth 1: a child cannot start its own children. Keep `CONFIG.Параллельность` within these limits; start the next batch after the previous batch's notices.
- **Collecting results.** Each child produces one completion notice containing its final text. The answer must follow the `PROTOCOLS.md` §1 format and be at most 15 lines. An empty final text means "no answer" — restart the task or do it yourself.
- **Follow-up.** A local child can be sent a message after it settles (`send_message`) or have its current turn interrupted (`interrupt_agent`); `list_agents` gives a state snapshot, not a wait.
- **Agent Teams.** If the experimental team profile is enabled, `subagent`/`subagent_fork` are replaced by `spawn_teammate` and `team_task_*`, and every member shares the working folder. Then a role is a teammate and tasks are board entries; the single-writer rule still applies. This mode is off by default, and the kit relies on `subagent`.
- **Without subagents.** If there is no subagent mechanism at all, perform the roles sequentially per `ORCHESTRATOR.md`, rule 8.

### Worktrees for fixers in DSH

DSH has no isolation mode for a subagent: the orchestrator creates the worktree and passes its path in the child's `cwd`.

```bash
git worktree add ../revref-wt/<ID> -b revref/task/<ID> HEAD
# the fixer subagent works with cwd = ../revref-wt/<ID>
git -C ../revref-wt/<ID> add -A && git -C ../revref-wt/<ID> commit -m "revref(W<n>): <task> ..."
git merge --no-ff revref/task/<ID>
git worktree remove ../revref-wt/<ID>
```

## Shell

- **Claude Code** runs commands through `Bash` (on Windows — `PowerShell`), and state carries over within a session.
- **DSH** runs `pwsh -Command <command>` (Windows) or `bash -c` (macOS, Linux) in a fresh process every time: no state persists and `cd` does not carry over. Pass the working directory through the tool parameter and use absolute paths or `git -C <path>`. The syntax of one platform is not translated into the other.
- **The kit's POSIX scripts** (`hooks/guard.sh`, `bin/update.sh`, `hooks/usage.sh`) require `sh`. On Windows, DSH has no documented way to run POSIX scripts: if Git for Windows is installed, you can call `& 'C:\Program Files\Git\bin\sh.exe' <script> …`, but that is unsupported; without it, perform the same steps manually (`PROTOCOLS.md` §11 → "Without `sh`").
- **Sandbox.** In read-only mode PowerShell switches to ConstrainedLanguage, and in both confined modes capturing another program's output through a pipe may fail with `EPERM`. A run needs a mode that permits writing and running commands.

## Guard check

- **Claude Code:** the `hooks/guard.sh` hook is wired automatically through the `SKILL.md` frontmatter and the agent files and blocks dangerous git commands and secret commits while `.revref/STATE.md` exists. Nothing extra is needed.
- **DSH:** there are no tool hooks — no `PreToolUse`, no hook settings file. A skill cannot intercept a command automatically; deterministic interception is possible only with a separate DSH plugin. Therefore in DSH the check is **mandatory and manual**: before every command protected by `POLICY.md` → "Git" (branch switch, commit, merge, push, reset, rebase, etc.), first run the check on that same command:

```powershell
# Windows / DSH
pwsh "<skill dir>/hooks/guard.ps1" -Command "git push --force"
# macOS, Linux or Windows with Git Bash
sh "<skill dir>/hooks/guard.sh" --check "git push --force"
```

- Exit code 0 — the command may run; code 2 — forbidden, the reason is on stderr, do not run the command and do not work around it; code 3 — the check is unavailable (no POSIX shell): verify against the `POLICY.md` rules manually and tell the owner the hook is not working.
- Check `git commit` too: the guard also catches secrets in the commit message and in added lines of `.revref/` and `docs/revref/`.
- The protection is the same on both platforms; only the way it is started differs.

## Token limit

- **Claude Code** passes subscription limit percentages only to the status-line command; `hooks/usage.sh` stores them and the orchestrator reads them with `--read` (`PIPELINE.md` → "Token limit").
- **DSH** has neither a status line nor agent access to subscription limit data. `hooks/usage.sh` does not work there. If `CONFIG.md` sets a limit threshold, write "not tracked" at `init` and in `status`, tell the owner once, and rely on the time budget (`CONFIG.Бюджет времени`). Do not estimate the percentage from your own token counts: that is unreliable. The owner can track the limit and stop the run with a command.

## Sessions, context and checkpoints

- The `.revref/` files and the checkpoint protocol are identical. When DSH compacts the context (this happens automatically) and whenever in doubt, re-read `STATE.md` and `PLAN.md`, as `ORCHESTRATOR.md` requires.
- Compaction does not replace checkpoints: before a long wait for subagents and at the end of a step, the state must be in the files.
- `/revref resume` in a new session is the normal path after an interruption. In DSH the loaded skill text refreshes on the next `/revref` call, but text already inserted into the current turn becomes stale; after `/revref update`, start a new session.
- Goal auto-continuation in DSH is not durable and is disarmed on session resume — do not rely on it, work with commands.

## DSH autonomous loop

In Autonomous loop mode (`resumeCompletedTurns`) the `dsh-client-auto-continue` plugin sends "Continue" by itself after every completed turn. Successful continuations are unlimited: only the owner (session switch, pause, Stop) or `turn/end:blocked` stops the loop. The skill cannot control the plugin — neither pausing it nor changing its mode is available to it.

Consequence: in the autonomous loop a turn must not end "empty" — with a status, a recap or a repeated card and no new actions. The plugin treats that as a normal completion, sends "Continue", and the turn starts repeating. When the model repeats itself, the plugin's **loop guard** cancels the turn (`agent.cancel`) and restarts it after a cooldown with the text "You may be stuck in a loop. Stop repeating the last action and continue with a different approach." No useful work happens in this cycle.

The loop guard trips on any of these signals (thresholds are configurable in the plugin; defaults shown):

- 4 consecutive identical assistant messages (of any length);
- 4 near-duplicate paragraphs inside one streamed message;
- 12 short (under 40 characters) messages within 30 s with no tool call in between;
- 5 calls of the same tool with identical arguments and identical results.

What RevRef does:

1. **A turn ends in only two ways:** either autonomous work exists — and the turn ends with work actually done; or no work remains without the owner — then `wait` (`PROTOCOLS.md` §13): a full checkpoint "stopped: waiting for owner answers" and a blocking question through `ask_user_question` (in Claude Code the loop does not continue the turn, so a blocking question is not mandatory there — cards and the end of the turn are enough).
2. **The blocking question keeps the turn open.** Until the owner answers, no `turn/end` happens, so the autonomous loop does not send "Continue". That is the run stopping without touching the plugin.
3. **Before asking, verify that the work is really exhausted** against the checklist in `PROTOCOLS.md` §13 → "When to stop". While at least one task, check or merge independent of the answers exists — keep working, do not ask.
4. **The loop guard is a signal, not a working method.** If the text "You may be stuck in a loop…" arrives, do not repeat the same action: run the exhaustion checklist; if work exists — change the approach, if not — move to `wait`.
5. **Do not repeat cards and statuses.** A second similar status in a row is already a loop-guard risk; instead of repeating, take a checkpoint and `wait` (or perform a concrete new action).
6. **Any stop with no further work** — the time budget (W9), the token limit threshold, "ready to merge", a finished or merged run — also goes through `wait` in the loop: cards and a blocking question "wait or switch the loop off / run the owner's command". Otherwise the loop continues the turn idly and runs into the loop guard.

A repeated "Continue" message without owner text is a sign that the session is in the autonomous loop; more reliably, record it at `init` in `CONFIG.md` ("Autonomous loop (DSH): yes"). When the loop is off, `wait` acts as an ordinary stop: checkpoint, cards, end of turn.

**Limitation.** The skill cannot stop the autonomous loop itself: only the owner does that (session switch, pause, Stop). If the owner is not answering and wants the continuations to stop, they switch the loop off in the session switch. If the run is finished or merged while the loop is still on, repeated "Continue" messages are pointless: say so in one line and suggest turning the loop off, without repeating the status.

## Command arguments

- **Claude Code** substitutes `$ARGUMENTS` in `SKILL.md`.
- **DSH** substitutes nothing: the owner's message stays literal (`/revref review SEC`), and the skill body is inserted after it. Read the arguments from the owner's message itself: everything after the `/revref` token. `SKILL.md` says so.
- DSH's own commands (for example `/permission`, `/compact`) receive free text, but skills do not; do not expect the host to parse arguments for a skill.

## Installing and updating in DSH

- Globally: `${DSH_HOME:-~/.dsh}/skills/revref`; in a project: `<project root>/.dsh/skills/revref`. A project installation shadows the global one: DSH finds the project root by the nearest `.git`.
- Install: `./install.sh --dsh` or `./install.ps1 -Dsh`; for a project — `--project <path>` / `-Project <path>`. No named agent files are installed: the roles live in the kit's `roles/`.
- In DSH the command appears in the `/` menu after a new session or a page reload: the client caches the skill catalog per session. The skill is marked `disable-model-invocation`, so it is absent from the model catalog — that is expected; only the owner starts it.
- Update: `/revref update` or `bin/update.sh` (on Windows through `sh`, when Git Bash is present). A project installation committed to git changes the paths under `.dsh/skills/revref` (not `.claude/skills/revref`); `PROTOCOLS.md` §11 takes the platform from `INSTALL`.

## Project instructions

DSH reads `AGENTS.md`, `CLAUDE.md`, `AGENTS.local.md`, `CLAUDE.local.md` in `$DSH_HOME`, in `$DSH_AGENTS_HOME` and in every directory from the project root down to the working directory, with a 64 KB budget; the more specific file wins. The `.dsh/` folder is not read for instructions, and `.claude/rules/` and `@path` imports are ignored. The project's custom reviews live in `.revref/reviews/` and work the same on both platforms.

## DSH run checklist

1. Make sure the guard is available (`hooks/guard.ps1` or `hooks/guard.sh --check`) and check every protected git command with it.
2. Start subagents in batches in one message, keep working and collect notices; never exceed 8 live children.
3. Create a worktree for each fixer yourself and pass it in `cwd`.
4. `CONFIG.Лимит токенов` in DSH is "not tracked" or the owner's data; rely on the time budget.
5. Before switching platforms or updating the kit — take a full checkpoint; after the update — start a new session and run `/revref resume`.
6. If autonomous work is exhausted and owner answers are needed — `wait` (`PROTOCOLS.md` §13), not an empty status: otherwise the autonomous loop continues the turn and runs into the loop guard.
