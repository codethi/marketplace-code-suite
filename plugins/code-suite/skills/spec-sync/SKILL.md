---
name: spec-sync
description: code-suite `spec-sync` capability. Use after implementation, before delivery, to compare the spec (docs/specs/<slug>.md) with the base...HEAD diff — routes, methods, fields, error codes, rules, flows — update the spec where the code deliberately differs, report unexplained deviations as pending instead of hiding them, refresh existing docs (README, OpenAPI/Swagger, request collections, unreleased CHANGELOG) and mark implemented ADRs Accepted. Edits documentation only, never code.
argument-hint: "[slug] [base]"
---

# Spec sync

Make the documentation tell the truth about what was built. The code is evidence of
what exists; the spec is the agreement. Where they differ, find out which one is right
— never paper over a deviation by quietly rewriting the spec.

Input: `$ARGUMENTS` (slug, base) and the conversation so far.

## Hard rules

- **Docs only.** Edit only documentation: the spec, existing `*.md` docs, hand-written
  OpenAPI/Swagger files, request collections (`.http`, Postman/Insomnia/Bruno exports),
  the CHANGELOG and ADR files. Never source code, tests, configuration or generated
  files.
- **Update only what already exists.** Do not create new docs, sections in docs that
  have no place for the change, or a CHANGELOG that the project does not keep.
- **No silent fixes.** A deviation without a deliberate reason is reported as pending,
  not absorbed into the spec.

## 1. Gather

1. Slug: from the arguments, the task folder (`.code-suite/<slug>/`) or the branch name.
2. Spec: `docs/specs/<slug>.md`, or the project's own specs directory if it uses
   another one. With no spec file, use the spec from the conversation or the task
   folder, and say the spec file was not found; skip step 4's spec edits.
3. Base: the one given; otherwise the first that exists of `origin/HEAD`,
   `origin/main`, `origin/master`, `main`, `master`.
4. Diff: `git diff --stat <base>...HEAD`, then the full diff and
   `git log --format='%h %s%n%b' <base>..HEAD` for stated intent.
5. Evidence of deliberate decisions: ADRs, the plan, the task journal
   (`.code-suite/<slug>/journal.md`), commit messages, review results, and decisions the
   user made in the conversation.

## 2. Compare

Extract from the spec and from the code, side by side, every externally visible item:

- **Routes / entry points** — HTTP paths and methods, CLI commands, events, jobs.
- **Fields** — request/response/payload fields: name, type, required, defaults.
- **Errors** — status or error codes, error messages the spec fixes.
- **Rules** — validations, limits, permissions, business rules.
- **Flows** — state transitions, sequences, side effects (writes, notifications).

Classify each difference:

- **Deliberate** — the code differs because of a decision you can point to (ADR, plan
  change, commit message with the reason, user decision, accepted review finding).
- **Unexplained** — no such evidence. This includes "probably fine" differences.
- **Missing** — something the spec requires that the code does not do, or vice versa.

## 3. Resolve

- **Deliberate** → update the spec to match the code, and add one line in the spec
  saying what changed and why (link the evidence).
- **Unexplained** or **Missing** → do **not** edit the spec. Record it as pending with
  `path:line` in the code, the spec section, and what differs. It goes back to
  `implement` (code is wrong) or to the user (spec may be wrong).

## 4. Refresh existing docs

Only for behavior that is final (deliberate or matching the spec), and only in docs
that already cover the area:

- **README / user docs** — usage, examples, options, env vars that changed.
- **OpenAPI / Swagger** — hand-written files only. If it is generated from code, do not
  edit it; list "regenerate with `<command>`" as pending.
- **Request collections** — add or adjust the requests for changed endpoints, with
  placeholder values, never real credentials.
- **CHANGELOG** — only the unreleased section (e.g. `## [Unreleased]`), in the file's
  existing style. Never edit a released version's entry. No unreleased section → leave
  it and mention it.
- **ADRs** — for each ADR this change implements as written and still marked
  Proposed, set the status to Accepted. If the implementation departs from the ADR's
  decision, leave the status and report it as pending.

## 5. Report

```markdown
**Docs alterados:**
- `path` — <what changed>

**Divergências corrigidas** (spec atualizada para o código, por decisão consciente):
- <spec section> ← `path:line` — <what differs> — motivo: <evidence link>

**Divergências pendentes** (não corrigidas):
- <spec section> vs `path:line` — <what differs> — <implement | decisão do usuário>
```

Write "nenhum" / "nenhuma" for empty sections. With pending divergences, the work is
not ready to deliver as matching its spec; say so in one line.
