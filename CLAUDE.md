# code-suite repository

This repo is a Claude Code plugin marketplace. Its content (skills, agents, hooks, docs)
is written in English and must stay stack-agnostic: nothing may assume a specific
language, framework or project layout.

- The orchestrator lives in `plugins/code-suite/skills/orchestrator/`. Routes name
  capabilities; `references/capabilities.md` maps capabilities to components.
- When adding a skill or agent, register it in `capabilities.md` and the README
  components table, and keep the inline fallback.
- Bump `version` in both `plugins/code-suite/.claude-plugin/plugin.json` and the
  marketplace entry in `.claude-plugin/marketplace.json` together.
- Validate before committing: `claude plugin validate --strict .` and
  `claude plugin validate --strict plugins/code-suite`.
