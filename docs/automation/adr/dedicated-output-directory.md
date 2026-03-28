# ADR: Dedicated output directory

## Context

Automation functions produce files — reports, exports, generated configs, build artifacts, test results.
When each function chooses its own output location, the repository accumulates files in unpredictable places:
a CSV in the repo root, a JSON next to the script that created it, an HTML report three folders deep.

This creates three problems:

1. **Dirty working tree.** Random output files show up in `git status`. Contributors either commit them by accident,
   add one-off `.gitignore` entries, or manually delete them. All three are ceremony that should not exist.

2. **No single place to clean.** Without a convention, there is no safe `Remove-Item` target.
   You cannot delete all generated files without knowing where each function put them.
   CI pipelines that need a clean workspace must enumerate locations or start from a fresh checkout.

3. **Confusion between source and output.** When generated files sit next to source files,
   it is not immediately clear which files are checked in and which are transient.
   Code review becomes harder — reviewers must distinguish authored content from generated artifacts.

### Scratch vs. output

Not every temporary file is output. Functions that need scratch space for intermediate processing — partial downloads,
temp files for atomic writes, decompression buffers — should use the system temp directory (`[IO.Path]::GetTempPath()`).
Scratch files are transient and disposable. Nobody needs to find them after the function returns.

Output files are different. They are the *result* of an operation — something a human or downstream process will consume.
These need a predictable, findable, and cleanable location inside the repository.

## Decision

All output files are written to `out/` at the repository root. Scratch files use the system temp directory.

### Rules

- **Write all output to `$env:RepositoryRoot/out/`.** Reports, exports, generated configs, build artifacts, test results —
  anything a function produces for consumption by a human or another process goes here.

  ```powershell
  $outDir = Join-Path $env:RepositoryRoot 'out'
  $reportPath = Join-Path $outDir 'test-results.xml'
  ```

- **Use subdirectories for organization.** Functions that produce multiple files or recurring output should create
  a subdirectory under `out/`:

  ```powershell
  $exportDir = Join-Path $env:RepositoryRoot 'out' 'exports'
  New-Item -ItemType Directory -Path $exportDir -Force | Out-Null
  ```

- **Use `[IO.Path]::GetTempPath()` for scratch files.** Intermediate files that are consumed and discarded within
  the same function call belong in the system temp directory, not in the repository.

- **Never write output files to the repository root, script directory, or any source folder.**
  Output does not belong next to source. If a function writes to `$PSScriptRoot`, it is wrong.

- **`out/` is gitignored.** The directory exists in the repository (via `.gitkeep`) but its contents are never committed.
  This prevents generated files from appearing in `git status` or being committed by accident.

- **Cleaning is one command.** To remove all output:

  ```powershell
  Remove-Item (Join-Path $env:RepositoryRoot 'out' '*') -Recurse -Force
  ```

  CI pipelines and developers use the same path. No hunting for scattered files.

## Consequences

- `git status` stays clean. Generated files never appear as untracked changes.
- There is exactly one place to look for output — `out/`. No searching, no guessing.
- Cleaning up is trivial — delete the contents of one directory.
- The distinction between source (committed) and output (transient) is structural, not by convention.
- Functions that previously wrote to ad-hoc locations must be updated to write to `out/`.
