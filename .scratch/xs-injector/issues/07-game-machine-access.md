# Game machine access

**Type:** task (HITL)
**Status:** resolved
**Blocked by:** none

## Question

The game is not installed on this desktop. Where does the agent loop run, and how does an agent there reach the live `.xsdat` folder?

Checklist for the maintainer:

- Name the machine that runs AoE2:DE and whether Claude Code runs on it.
- Give the profile `.xsdat` folder path on that machine.
- Confirm whether aoe2kit (Go 1.23+) can be built or downloaded there.

Resolved when the answer records the machine, the path, and the toolchain status.

## Answer

The question's premise was wrong: the game is on this desktop. The maintainer confirmed on 2026-11-10 that this desktop runs the agent loop and the live spike, so there is no remote access to solve.

- **Machine**: this desktop (Windows 11), with Claude Code running locally. AoE2:DE is the Steam install at `C:/Program Files (x86)/Steam/steamapps/common/AoE2DE/`.
- **Profile `.xsdat` folder**: `C:\Users\dmwev\Games\Age of Empires 2 DE\76561199655318799\profile`. It already holds the Ageipelago sidecars (`locations.xsdat`, `ATT1.xsdat`, `JOAN1.xsdat`, ...).
- **Toolchain**: Go 1.27.0 at `C:\Program Files\Go\bin\go.exe`. `chrae/aoe2kit` is cloned at `GitHub/aoe2kit` (HEAD `a5052ba`, 2026-10-23), and the built binary is at `aoe2kit/bin/kit.exe`.
