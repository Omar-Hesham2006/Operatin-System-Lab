# Simple Antivirus Daemon (Lab 2)

A shell-based mini antivirus: a polling daemon that quarantines suspicious
files, a restore tool, a Makefile, and a cron variant.
`dir` contains only files (no subdirectories).

## Folder hierarchy

```
studentID-lab2/
├── antivirusd.sh        # daemon: antivirusd.sh dir malicious_dir interval-secs
├── restore.sh           # restore.sh dir malicious_dir
├── antivirus-cron.sh    # Bonus 1: one-shot scan for cron
├── Makefile             # targets: run, restore, setup, clean
├── README.md
├── dir/                 # monitored directory
├── malicious_dir/       # quarantine directory
├── whitelist.txt        # generated: restored (safe) file names
└── directory-info.last / directory-info.new   # generated: ls -l snapshots
```

## Prerequisites (Ubuntu)

```bash
sudo apt update
sudo apt install -y make
```

## Running

1. `cd studentID-lab2`
2. Start the daemon: `make run` (override with e.g. `make run INTERVAL=2`).
   The pre-build step creates `malicious_dir` if it does not exist.
3. In another terminal, add files to `dir/`, e.g. `echo x > dir/bad.exe`.
   The daemon prints `dir/bad.exe is malicious and it is DELETED`, copies the
   file to `malicious_dir/`, and deletes the original.
4. Stop the daemon with Ctrl+C (do not run it together with restore.sh).
5. Review quarantined files: `make restore`. Pick a number, then
   1 = restore, 2 = permanently delete, 3 = leave it. `q` quits.

Change detection: `ls -l dir` is saved to `directory-info.new` every interval
and compared with `directory-info.last` using `cmp`. If they differ, `dir` is
scanned and `.new` is copied over `.last`. The first run scans immediately.

## Where the detection lists are defined

At the top of `antivirusd.sh` (and `antivirus-cron.sh`), under the
CONFIGURATION block:

```bash
FLAGGED_EXTENSIONS=(.exe .bat .vbs .scr .ps1)
FLAGGED_KEYWORDS=(virus trojan malware worm ransomware)
```

## Bonus 1: Cron job

Prerequisites:
- `sudo apt install -y cron`
- `sudo systemctl enable --now cron`
- `chmod +x antivirus-cron.sh`, and `dir` and `malicious_dir` must exist
  (`make setup`). Use absolute paths in the crontab.

Steps:
1. Run `pwd` to get the absolute path of the project.
2. Run `crontab -e`.
3. Add this line (runs every minute at second 23):
```
   * * * * * sleep 23 && /abs/path/antivirus-cron.sh /abs/path/dir /abs/path/malicious_dir >> /abs/path/antivirus-cron.log 2>&1
```
4. Save, then check with `crontab -l` and `tail -f antivirus-cron.log`.

Cron expression for every 3rd Friday of the month at 12:31 am:

```
31 0 * * 5 [ "$(date +\%d)" -ge 15 ] && [ "$(date +\%d)" -le 21 ] && /abs/path/antivirus-cron.sh /abs/path/dir /abs/path/malicious_dir
```
The 3rd Friday always falls on day 15-21. Writing `31 0 15-21 * 5` would be
wrong because cron ORs the day-of-month and day-of-week fields (it would also
run on every Friday), so the date is checked in the command instead.

## Bonus 2: Whitelist

- Added: choosing option 1 (restore) in `restore.sh` appends the file name to
  `whitelist.txt` (in the same folder as the scripts, no duplicates).
- Checked: during a scan the scripts run `grep -Fxq -- name whitelist.txt`
  (exact whole-line match). A whitelisted name is skipped before the extension
  and keyword rules are applied.
- Persistence: the whitelist is a file on disk, so it survives restarts of
  the daemon. To un-whitelist a file, delete its line from `whitelist.txt`.
