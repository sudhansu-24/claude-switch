```
     ▐▛███▜▌
    ▝▜█████▛▘
      ▘▘ ▝▝
```

# Claude Switch

**Open more than one Claude Desktop on Windows — each with its own account.**

Want one Claude for work and another for personal stuff? Or a few Claudes
signed into different accounts, each with different MCP servers and settings?
Normally Windows won't let you — Claude Switch makes it happen with one
double-click.

- ✅ One-click setup
- ✅ Every window has its own login, MCP servers, and settings
- ✅ Your original Claude stays exactly as it is
- ✅ Keeps working after Claude updates itself

---

## What you need

- Windows 10 or 11
- Claude Desktop already installed
- Admin rights (asked for once during setup)
- About 200 MB of free space

---

## Get started

1. Grab this repo — hit the green **Code** button, choose **Download ZIP**,
   and unzip it (or clone it with `git clone`).
2. Double-click **`INSTALL.cmd`**. Say yes to the admin prompt.
3. That's it! Look at your Desktop — you'll see new shortcuts called
   **Claude 2** and **Claude 3**.

Need more (or fewer) copies? Open PowerShell **as admin** and run:

```powershell
powershell -ExecutionPolicy Bypass -File scripts\install.ps1 -Instances 3
```

---

## Signing in — read this first! 🔑

The very first sign-in for each new Claude has to happen **one window at a
time**, with every other Claude closed.

Here's why: when you sign in, your browser sends you back to the app through a
special link. That link lands on whichever Claude window happens to be open.
If several are open at once, the login can land on the wrong one — and suddenly
they're all the same account.

**So do it like this:**

1. Close **every** Claude window. Peek at the little arrow (▲) near the clock
   to make sure none are hiding in the tray.
2. Open **only Claude 2** and sign in (Google, or email + code — whatever you
   like).
3. When that's done, open **Claude 3** and sign in with the next account.
4. Your regular Claude (Start menu) still has your main account — untouched.

You only do this dance once. After that, every Claude remembers its own
account and you can open them all together whenever you want.

---

## When Claude updates itself

Claude updates on its own from time to time, and the extra copies stay on the
older version. Fixing that takes one step: **run `INSTALL.cmd` again.** It
grabs the new version and your shortcuts keep working as before.

---

## Removing it

```powershell
powershell -ExecutionPolicy Bypass -File scripts\uninstall.ps1
```

That deletes the extra copy, the shortcuts, and the extra profiles. Your
regular Claude is never touched. Want to keep the signed-in accounts for
later? Add `-KeepProfiles`.

---

## Where things live

| Place | What's there |
|-------|--------------|
| `C:\ClaudePortable\` | A copy of Claude that Windows lets you launch freely |
| `%APPDATA%\Claude-Instance2`, `...3` | Each window's own account, MCP servers, and settings |
| `Desktop\Claude 2.lnk`, `Claude 3.lnk` | The shortcuts that open each window |

Your normal Claude and its data (`%APPDATA%\Claude`) are never modified.

---

## Something not working?

| What you see | What to do |
|--------------|-----------|
| "Could not find Claude Desktop" | Check Claude is installed, and run the installer **as admin**. |
| "Windows cannot access the specified device..." | Don't launch Claude from the `WindowsApps` folder — use the `Claude 2` / `Claude 3` shortcuts. |
| Two windows show the same account | Delete that window's folder (`%APPDATA%\Claude-InstanceN`) and sign in again with all other Claudes closed. |
| Shortcuts broke after a Claude update | Run `INSTALL.cmd` once more. |
| Setup fails because files are "in use" | Close every Claude window (tray too!) and try again. |

---

## How does it work? (the nerdy bit)

Claude Desktop installs as an MSIX package inside `C:\Program Files\WindowsApps`.
Windows refuses to launch programs straight from that folder, and the package
is built to run as a single instance — so you can't just make a second
shortcut.

Claude Switch works around this:

- It finds your Claude install with `Get-AppxPackage`.
- It copies the app to a normal folder (`C:\ClaudePortable`) using
  `robocopy /MIR` — outside `WindowsApps`, launching is allowed.
- Each shortcut starts that copy with its own
  `--user-data-dir="%APPDATA%\Claude-InstanceN"`, so Electron keeps every
  window's account, tokens, and settings completely separate.

---

## Inside the box

```
INSTALL.cmd            Double-click me — asks for admin and runs the setup
scripts/install.ps1    Finds Claude, copies it, makes the shortcuts
scripts/uninstall.ps1  Cleans everything up again
```

---

## Good to know

- **Windows only.** On macOS: `open -n -a "Claude.app" --args --user-data-dir=...`.
  On Linux: run the binary with the same flag. Neither needs the copy trick.
- Each Claude window is a full app — only open as many as you actually use.
- Not affiliated with Anthropic. Use at your own discretion.

---

## Want to help?

Issues and pull requests are welcome! One request: keep the scripts compatible
with the PowerShell that ships with Windows (5.1) — no PowerShell 7-only
syntax — so everything works on a fresh machine.
