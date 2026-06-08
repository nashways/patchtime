---
name: patchtime
description: Compute or match a patchtime "patch window" (week-of-month schedule like w2d6h23) using the bundled patchtime.py/patchtime.sh scripts. Use when the user asks what the current patch window is, whether "now" matches a window, how to schedule something on a week-of-month / Patch-Tuesday-style cadence, or wants to gate a cron job, /loop, or scheduled agent on a patch window. Patch windows express "first/second/third/fourth <weekday> of the month", which plain cron cannot.
---

# patchtime

`patchtime` turns the current date into a **patch window** string of the form
`w<week>d<day>h<hour>` — e.g. `w2d6h23` = week 2 of the month, Saturday (ISO
day 6), 23:00. Weeks are counted from the first occurrence of an *anchor*
weekday in the month, so `w1` always means "the week containing the first
Monday (or first Tuesday, etc.)" regardless of which day the month starts on.
This is the "first Tuesday of the month" / Patch-Tuesday math that plain cron
(`0 9 1-7 * 2`) gets wrong as month-start drifts.

## Locating the scripts

The scripts are bundled with this plugin at its root. Always invoke them via the
plugin root env var so the path is correct on any machine:

```bash
"${CLAUDE_PLUGIN_ROOT}/patchtime.py"        # preferred (stdlib-only Python 3)
"${CLAUDE_PLUGIN_ROOT}/patchtime.sh"        # bash equivalent, needs `date`
```

If `${CLAUDE_PLUGIN_ROOT}` is somehow unset, fall back to `patchtime.py` on
`$PATH`. The `.py` and `.sh` implementations are interchangeable — same flags,
same output. Prefer `.py` for portability.

## Getting the current window

```bash
"${CLAUDE_PLUGIN_ROOT}/patchtime.py"          # anchor = Monday (default) -> e.g. w2d1h21
"${CLAUDE_PLUGIN_ROOT}/patchtime.py" -a 2     # anchor = Tuesday
"${CLAUDE_PLUGIN_ROOT}/patchtime.py" -t       # deprecated alias for -a 2
"${CLAUDE_PLUGIN_ROOT}/patchtime.py" -a 3     # anchor = Wednesday ... -a N, N = ISO weekday 1..7
```

Output is a single line like `w2d1h21` on stdout. The hour comes from the
current local clock.

## Flags

- `-a N` — anchor weekday, ISO `1`=Mon … `7`=Sun. Default `1`.
- `-t` — deprecated alias for `-a 2` (Tuesday).
- `-l` — print GPL warranty/terms links.
- `--?` (py) — usage text.

## Window format and valid range

- `w` week of month, `1`–`4` (a `w5` can appear in long months but is not
  guaranteed every month — don't schedule on `w5`).
- `d` ISO weekday, `1`=Mon … `7`=Sun.
- `h` hour, `00`–`23`.
- Dependable range: **`w1d1h00` – `w4d7h23`**.
- The last week of a month "borrows" the first days of the next month to
  complete itself, so every day maps to exactly one window.
- Note: when the first week of the month is already full, the anchor flag does
  not change the result — the anchor only matters when the first week is partial.

## Checking whether NOW matches a target window

The window string already encodes week+day+hour, so a string compare is the
whole check. To test "is now the second-Tuesday 10:00 window?":

```bash
[ "$("${CLAUDE_PLUGIN_ROOT}/patchtime.py" -a 2)" = "w2d2h10" ] && echo MATCH
```

To match a window regardless of hour, strip the hour:

```bash
[ "$("${CLAUDE_PLUGIN_ROOT}/patchtime.py" -a 2 | sed 's/h.*//')" = "w2d2" ] && echo MATCH
```

## Using it to schedule things (the point of this skill)

Cron/interval schedulers can't say "first Tuesday of the month." patchtime
can, so the pattern is always: **fire often (hourly), gate on patchtime.**

- **Plain crontab** — gate each line (use an absolute path to the installed
  script, since cron has no `${CLAUDE_PLUGIN_ROOT}`):
  ```cron
  0 * * * * [ "$(/opt/scripts/patchtime.py -a 2)" = "w1d1h10" ] && /opt/scripts/patch_legA.sh
  ```
- **A `/loop`** (this assistant, self-paced or hourly) — wake each hour, run the
  bundled `patchtime.py`, act only on a match, otherwise reschedule. Use this
  when the user wants me to drive a week-of-month task within a session.
- **A scheduled remote agent (`/schedule`) / `CronCreate`** — schedule hourly
  (`0 * * * *`) and gate the body on `patchtime.py`, same as crontab. Do **not**
  try to encode the week-of-month rule in the cron expression itself; that is
  exactly what patchtime exists to avoid.
- **Native cron** — the companion `cronie-patchtime` fork understands an
  `@patch w1 d1 h10 <cmd>` keyword and needs no gating. Mention it when the user
  controls the cron daemon.

## Notes

- Day-before override: if tomorrow is the 1st *and* is the anchor weekday, today
  counts as `w1` of the upcoming month (days before the first anchor belong to
  the previous month's last week).
- GPLv3. Don't strip the license headers when editing the scripts.
