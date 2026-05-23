---
name: commit-changes
description: Stages and creates one or more Conventional Commits split by coherent change; does not push unless the user explicitly asks to push. Invoked only when the user runs this skill or names it—never as automatic “task finished” cleanup.
disable-model-invocation: true
---

# Commit changes (explicit invoke only)

## When this applies

Run this workflow **only** because the user **invoked this skill** or **explicitly asked** to run this commit workflow. **Do not** stage, commit, or amend merely because other work in the chat appears done.

## Push

**Do not** `git push` unless the user **explicitly** asks to push (including force-push: only if they explicitly request it).

## Steps

1. `git status` and review the full diff. **One commit = one coherent change** (same subsystem / same intent).
2. Message format and **semver / semantic-release**: follow `.cursor/rules/conventional-commits-and-prs.mdc`, including the subsection **Commit type vs release (semantic-release)**: choose `type` by the **release bump you intend** (`feat` ⇒ minor, `fix` / `docs` / `refactor` / `style` ⇒ patch per `.releaserc.json`, `chore` ⇒ typically no release). Do not use `feat` for constant-only or maintenance changes that are not new product capabilities.
3. If the working tree mixes unrelated edits, **split before committing**: stage by path or `git add -p` so each commit is reviewable and semantic-release-safe.
4. Commit each group with `type(scope): summary` (and body when it helps readers).
5. If the user asked for checks before commit (e.g. `bun check`), run them before committing; if something fails, fix or report before committing.

## Afterward

Summarize what was committed (subjects only unless they need detail). If nothing was staged, say so and why.
