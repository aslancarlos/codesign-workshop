# Contributing

Thanks for your interest in improving the Code Signing Workshop!

## Ground rules

- Be respectful — see the [Code of Conduct](CODE_OF_CONDUCT.md).
- **Never** include real secrets, identities, tenant names, UUIDs, or customer
  data in code, issues, or pull requests. Everything must stay configurable via
  environment variables.
- Keep the script **portable**: POSIX-friendly `bash`, no hard dependency that
  isn't already optional and degraded gracefully.

## Project layout

The workshop is **developed as modules** under `src/` but **distributed as one
self-contained file** (`codesign-workshop.sh`) so it can be copied to a target
machine and run with no extra files.

```
src/
  00-header.sh      shebang-less header comment + `set -o pipefail`
  10-config.sh      configurable environment variables
  20-style.sh       colors, the t() i18n helper, output helpers
  30-lib.sh         API/helpers (get_tok, gql, ensure_*, log_signing, ...)
  40-diagrams.sh    ASCII flow diagrams
  50-bootstrap.sh   require_bin, choose_lang
  60-steps.sh       all step_* functions + step_guided
  70-menu.sh        the menu renderer
  90-main.sh        entry point (the run loop)
build.sh            concatenates src/*.sh -> codesign-workshop.sh
codesign-workshop.sh  GENERATED — do not edit by hand
```

Modules are numeric-prefixed so they concatenate in dependency order.

## Development setup

**Edit the modules under `src/`, never the generated file.** Then rebuild and
validate:

```bash
./build.sh            # regenerate codesign-workshop.sh from src/
bash -n codesign-workshop.sh
shellcheck codesign-workshop.sh build.sh   # lint the generated file + builder
./build.sh --check    # what CI runs: fails if the committed file is stale
```

Commit **both** the changed `src/` modules **and** the regenerated
`codesign-workshop.sh`. CI rejects a PR whose distributable is out of sync.

> ShellCheck runs on the **generated** file, not on individual modules (they are
> fragments and are not valid standalone scripts).

Fully exercising the workshop requires a real Code Sign Manager client and a
tenant you are authorized to use; most contributions can be validated with
`./build.sh --check` + `shellcheck` plus a manual run of the menu rendering.

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

1. In `src/60-steps.sh`, write a `step_x()` function with a `title`, explanation
   `note`s, and the commands (use `show` to print a command, then run it).
2. Register it in `src/70-menu.sh` (menu line) and `src/90-main.sh` (dispatch
   `case`); if it is part of the narrative, add it to `step_guided` in
   `src/60-steps.sh`.
3. If it signs something, call `log_signing <key> <tool> <artifact-path> <algo>
   <result> [pre-hash]` so it appears in the signatures log.
4. Run `./build.sh`, then `shellcheck codesign-workshop.sh`, and commit both the
   modules and the regenerated file.
