# 13: Name the `--map` file in a no-section timeout

Parent: [01: Spec: XS function injector](01-xs-function-injector-spec.md)

**What to build:** When `--map` is passed and the result is `Timeout`/`no-section`, the message says what happened to that one file. Today it always says "no .xsdat in the profile folder carries a response section", even when another file in the folder does carry one. That sent ticket 12's live check down the wrong path.

**Blocked by:** none

**Status:** ready-for-agent

- [ ] With `--map <stem>` and no `<stem>.xsdat` in the profile folder, the message says that file doesn't exist, names it in full, and reminds that editor test-play writes `default1`
- [ ] With `--map <stem>` and the file present but with no response section, the message names that file and says it carries no section
- [ ] Without `--map`, the message is unchanged
- [ ] `diagnosis` stays `no-section` in every case: no new diagnosis value (the spec's set is `no-section` / `older-id` / `stuck-running`)
- [ ] Applies to `run`, `ping` and `fetch` alike
- [ ] Driver-seam tests cover all three messages
- [ ] `docs/agents/troubleshooting.md` is updated: the first check that quotes today's `--map` message is rewritten to the new wording

## Notes

- The source is ticket 12's live run (2026-11-12, requests 64-66). `ping --map XsTesting` timed out `no-section` while `default1.xsdat` was being written and carried a section. The scenario's name is a natural but wrong guess, because editor test-play writes `default1`.
- Where: `_timeout` in `xsinject/driver.py` builds the message. `_candidate_files` already narrows to the one `--map` file, so `_timeout` needs the map name, or whether that file exists, passed in.
