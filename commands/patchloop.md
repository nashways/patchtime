---
description: Run a task on a recurring patchtime window (week-of-month), e.g. /patchtime:patchloop a2 w2d2h10 pull the autoinstall logs. The session-level analog of cronie-patchtime's @patch keyword.
argument-hint: "[aN] wNdNhNN <task>"
---

You are setting up a **patchtime-gated loop**: wake on an interval, and run a
task only when the current patchtime window matches a target. This is the
in-session analog of the `@patch` crontab keyword from cronie-patchtime.

The bundled scripts are at `${CLAUDE_PLUGIN_ROOT}` (use `patchtime.py`). See the
`patchtime` skill for the window format.

## Arguments

Raw arguments: `$ARGUMENTS`

Parse them as: `[aN] [@]wNdNhNN <task...>`

1. **Optional anchor** — a leading token `aN` where `N` is the ISO weekday
   `1`=Mon … `7`=Sun the week count anchors on. Default `1` (Monday). This maps
   to the script's `-a N` flag. (`-t` is the legacy alias for `a2`.)
2. **Target window** (required) — a token of the form `wNdNhNN`:
   - `w` week of month `1`–`4` (avoid `w5`; not every month has one),
   - `d` ISO weekday `1`–`7`,
   - `h` hour `00`–`23`.
   Tolerate and strip a leading `@` if the user typed `@w...` (that's just the
   cron-keyword muscle memory; `@` is otherwise a file sigil here).
3. **Task** — everything after the window token is the work to run when the
   window matches. Free-form.

If no valid `wNdNhNN` token is present, do **not** start a loop. Print the usage
(`/patchtime:patchloop [aN] wNdNhNN <task>`) with a concrete example and stop.

## What to do

1. **Echo the plan back** so the user can confirm: the resolved anchor (name the
   weekday), the target window, the task, and the cadence (hourly). Example:
   "Anchor = Tuesday (a2); will run `<task>` when the window hits `w2d2h10`;
   checking hourly."

2. **Enter the loop** — repeat until the task fires (or the user interrupts):
   a. Run `"${CLAUDE_PLUGIN_ROOT}/patchtime.py" -a <anchor>` and read the
      `wNdNhNN` it prints.
   b. **If it equals the target window**, run the task now. Report what
      happened. Then ask the user whether to keep watching for the next
      occurrence (next month) or stop — a session rarely lives a whole month,
      so one-shot is the sensible default unless they say otherwise.
   c. **If it does not match**, do nothing this tick and schedule the next
      wake-up about an hour out (the window's finest unit is the hour, so
      checking more often is wasted). Use the loop/self-pacing mechanism to
      resume — schedule ~3600s, the cadence the loop skill uses for idle waits.

3. **Be honest about scope.** This loop lives inside the current session: if the
   session ends, it stops. For a durable monthly job that survives reboots, tell
   the user to use the standing options the `patchtime` skill documents instead —
   a crontab line gated on `patchtime.py`, a `/schedule` remote agent, or the
   `@patch` keyword in the cronie-patchtime fork.

## Example

`/patchtime:patchloop a2 w2d2h10 pull the hlx014 and hlx015 autoinstall logs and summarize failures`

→ anchor Tuesday, target second-Tuesday 10:00 (`w2d2h10`), and on match it pulls
and summarizes those logs.
