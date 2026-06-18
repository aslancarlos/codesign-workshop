# Contributing

Thanks for your interest in improving the Code Signing Workshop!

## Ground rules

- Be respectful — see the [Code of Conduct](CODE_OF_CONDUCT.md).
- **Never** include real secrets, identities, tenant names, UUIDs, or customer
  data in code, issues, or pull requests. Everything must stay configurable via
  environment variables.
- Keep the script **portable**: POSIX-friendly `bash`, no hard dependency that
  isn't already optional and degraded gracefully.

## Development setup

There is no build step. Edit `codesign-workshop.sh` and validate locally.

```bash
# Syntax check (no execution)
bash -n codesign-workshop.sh

# Lint (recommended)
shellcheck codesign-workshop.sh
```

Fully exercising the workshop requires a real Code Sign Manager client and a
tenant you are authorized to use; most contributions can be validated with
`bash -n` + `shellcheck` plus a manual run of the menu rendering.

## Style

- Match the existing structure: one `step_*` function per menu entry, a `title`
  at the top of each step, helper functions (`note`, `ok`, `err`, `fail`,
  `show`, `run`, `pause`) for output.
- **Bilingual strings.** All user-facing text goes through the `t 'pt' 'es'`
  helper. Add both languages. Keep ASCII boxes free of translated text so they
  stay aligned; put translated labels in legends below the diagram.
- No hardcoded identities/keys/labels — add a configurable variable with a
  generic default instead.

## Commit messages & PRs

- Use clear, imperative commit messages (e.g. `Add timestamp authority option`).
- Describe what changed and how you validated it (e.g. `bash -n`, `shellcheck`,
  manual run).
- One logical change per PR where possible.

## Adding a new step

1. Write a `step_x()` function with a `title`, explanation `note`s, and the
   commands (use `show` to print a command, then run it).
2. Add it to the menu, the dispatch `case`, and (if part of the narrative) the
   guided run `step_guided`.
3. If it signs something, call `log_signing <key> <tool> <artifact-path> <algo>
   <result> [pre-hash]` so it appears in the signatures log.
