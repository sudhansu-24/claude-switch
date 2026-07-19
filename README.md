# Claude Desktop Multi-Instance (Windows)

Run **multiple Claude Desktop instances side by side on Windows**, each with its
own account, MCP servers, and settings — even though Claude ships as a
single-instance MSIX app.

One click. Survives auto-updates. Doesn't touch your normal install.

---

## Requirements

- Windows 10/11
- Claude Desktop installed from the official installer (MSIX / Microsoft Store style install)
- Administrator rights (only needed while installing, to read the protected `WindowsApps` folder)
- ~200 MB free disk space per portable copy

---

## Why this is needed

Claude Desktop for Windows installs as an **MSIX package** under
`C:\Program Files\WindowsApps`. That causes two problems if you want a second
instance:

1. **Windows blocks launching the `.exe` directly** from `WindowsApps`
   (`"Windows cannot access the specified device, path, or file"`). So shortcuts
   pointing straight at the packaged exe fail.
2. The package is built to run **one instance**. Even with Electron's
   `--user-data-dir` flag, you can't reach the exe to pass it.

**The fix:** copy Claude to a normal folder *outside* `WindowsApps`
(`C:\ClaudePortable`), where Windows allows direct launch, then create one
shortcut per instance — each with its own `--user-data-dir`. Each instance gets
a fully isolated profile: separate account, separate MCP servers, separate
Cowork/settings.

> This is the part most guides miss: on Windows the MSIX exe can't be launched
> in place, so you have to run a portable copy. That's exactly what `install.ps1`
> does, and re-running it picks up Claude's latest auto-update.

---

## Quick start

1. **Download** this repo (green `Code` button → `Download ZIP`, then extract),
   or clone it with `git clone`.
2. Double-click **`INSTALL.cmd`**. It asks for Administrator (needed once, to
   read the protected `WindowsApps` folder) and sets up **2 extra instances**.
3. On your Desktop you'll now have **`Claude 2`** and **`Claude 3`** shortcuts.

Want a different number? Run from an **admin** PowerShell:

```powershell
powershell -ExecutionPolicy Bypass -File scripts\install.ps1 -Instances 3
```

---

## Logging into different accounts (important!)

The first login of each new instance must be done **one at a time, with the
other Claude windows closed**.

Why: Claude's login opens your browser and returns to the app via a `claude://`
link. That link goes to whichever instance is currently open — so if several are
open, the login lands on the wrong one and they all end up on the same account.

**Do this:**

1. Close **all** Claude Desktop windows (check the system tray ▲ near the clock).
2. Open **only `Claude 2`** → log in (Google sign-in, or email + code — any
   method works) → finish the login.
3. Open **`Claude 3`** → log in with a different account.
4. Open your normal Claude (Start menu) → it keeps your main account.

After the first login, each session persists. You can then run all of them at
once, in any order.

---

## Updating

When Claude Desktop auto-updates, the portable copy stays on the old version.
To refresh it, just **run `INSTALL.cmd` again** (or `scripts\install.ps1`).
It detects the new version, recopies, and your existing Desktop shortcuts keep
working — no need to recreate them.

---

## Uninstall

```powershell
powershell -ExecutionPolicy Bypass -File scripts\uninstall.ps1
```

Removes the portable copy, the `Claude N` shortcuts, and the isolated profiles.
Your normal Claude install is left untouched. Add `-KeepProfiles` to keep your
logged-in instance data.

---

## What gets created

| Path | What |
|------|------|
| `C:\ClaudePortable\` | Portable copy of Claude (launchable, outside WindowsApps) |
| `%APPDATA%\Claude-Instance2`, `...3`, ... | Isolated profile per instance (account, MCP, settings) |
| `Desktop\Claude 2.lnk`, `Claude 3.lnk` | Shortcuts that launch each instance |

Your normal install and its data (`%APPDATA%\Claude`) are never modified.

---

## How it works (technical)

- `Get-AppxPackage *Claude*` finds the current MSIX install location (robust
  across version bumps).
- `robocopy /MIR` mirrors `…\app` into `C:\ClaudePortable`.
- Each shortcut runs `C:\ClaudePortable\Claude.exe --user-data-dir="%APPDATA%\Claude-InstanceN"`.
- Electron stores **all** per-instance state (auth tokens included) under that
  data dir, so instances are fully independent.

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| `Could not find Claude Desktop` | Make sure Claude Desktop is installed and you ran the script **as Administrator**. |
| `Windows cannot access the specified device...` | You're launching the exe inside `WindowsApps` directly — use the generated `Claude N` shortcuts instead. |
| Two instances ended up on the same account | Delete the wrong profile folder (`%APPDATA%\Claude-InstanceN`), then redo the login with **all other Claude windows closed**. |
| Shortcuts stopped working after a Claude update | Re-run `INSTALL.cmd` — it recopies the new version to the portable folder. |
| Copy fails / files locked | Close every Claude window (including tray icon) and re-run the installer. |

---

## Notes & limitations

- **Windows only.** On macOS use `open -n -a "Claude.app" --args --user-data-dir=...`;
  on Linux invoke the AppImage/binary with the same flag — no portable copy needed
  there.
- Re-run after each Claude update to keep the portable copy current.
- RAM: each instance is a full Electron app. Don't open more than you need.
- Not affiliated with Anthropic. Use at your own discretion.

---

## Project structure

```
INSTALL.cmd            One-click entry point (self-elevates, calls install.ps1)
scripts/install.ps1    Finds the MSIX install, copies it portable, creates shortcuts
scripts/uninstall.ps1  Removes the portable copy, shortcuts, and (optionally) profiles
```

---

## Contributing

Issues and PRs welcome. Keep changes Windows-PowerShell-5-compatible (no
PowerShell 7-only syntax) so the scripts run on a stock Windows install.

