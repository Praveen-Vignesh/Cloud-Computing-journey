# Day 005

**Title:** Shell scripting: `backup.sh` on a systemd timer

**Did:**
- Wrote `backup.sh` and made it executable.
- Wrote a `.service` and a `.timer` so it runs on a schedule instead of by hand. First systemd timer.
- Learned the loop: write the unit, `daemon-reload`, start it by hand to test, read the journal, then enable the timer.

Notes: `Notes/linux/systemd-timers.md`
