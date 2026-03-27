# ADR: Log the exact command before every invocation

## Status

Accepted

## Context

When an external command fails, the first question is always: "What
exactly did it run?" If the answer requires reading source code, adding
`-Verbose`, or reproducing the issue with debug flags, you have already
lost minutes. In a CI pipeline where the environment is gone after the
run, those minutes turn into a full rebuild cycle.

PowerShell automation is fundamentally about orchestrating external tools
— `az`, `dotnet`, `winget`, `poetry`, `git`. Each of these has dozens of
flags, and the difference between success and failure is often a single
argument or a missing quote. If the exact invocation is not in the log,
you are guessing.

### Why this must be automatic, not opt-in

**Developers will not add logging.** If logging is a conscious choice per
call site, it will be missing from exactly the call that fails. The
function that "obviously works" and does not need logging is the one that
breaks at 3 AM in production.

**Verbose/Debug flags are off by default.** If the command is only logged
behind `-Verbose`, you will not have it when you need it. The log must be
there on every run, not just when someone remembered to enable diagnostics.

**Copy-paste debugging.** When the log shows the exact command, you can
copy it, paste it into a terminal, and run it manually. This is the
fastest debugging workflow — no reproduction steps, no guessing what the
automation actually did. If the command is paraphrased or partially
logged, this workflow breaks.

### Secrets are not a concern

Secrets never live in the codebase — they come from ADO pipeline
variables. ADO's agent automatically masks any value registered as a
secret variable, replacing it with `***` in all log output. Since secrets
always originate from ADO, they are always registered, and they are always
masked. The automation code logs freely.

On a developer's machine, the developer already has direct access to
every value the automation uses. Logging a connection string to your own
terminal is not a security event.

## Decision

Every function that invokes an external command must log the exact
command string immediately before execution.

### Rules

- **Log the full command string as the last step before invocation.**
  Use `Write-Message` (or equivalent) with the resolved command — all
  variables expanded, all arguments in place. The log entry must be
  copy-pasteable.

- **This is handled in `Invoke-CliCommand`.** The central invoker logs
  automatically. Functions that use `Invoke-CliCommand` get this for free.
  Functions that bypass it (direct `& $tool` calls) must add their own
  logging.

- **Do not paraphrase.** Do not log "Installing Python..." — log
  `winget install --id Python.Python.3.11 --silent`. The readable
  description is nice to have in addition, but it is not a substitute for
  the actual command.

- **Do not conditionally log.** The command is logged on every run, not
  behind `-Verbose` or `-Debug`. When you need it, it is already there.

- **`-Silent` is available as an escape hatch.** Every invoker
  (`Invoke-CliCommand`, `Invoke-Python`, `Invoke-Poetry`, `Invoke-Dotnet`)
  supports a `-Silent` switch that suppresses the command log line. Use
  this for plumbing calls where the log would be noise, or when a command
  contains a secret retrieved at runtime (e.g., fetched from a storage
  account or key vault) that ADO does not know about and cannot mask.

### How this is enforced

- **`Invoke-CliCommand`** — logs the full command string via
  `Write-Message` before execution. All `Invoke-*` tool wrappers
  (`Invoke-Python`, `Invoke-Poetry`, `Invoke-Dotnet`) delegate to
  `Invoke-CliCommand` and inherit this behavior automatically.

## Consequences

- Every CI log contains the exact commands that ran, in order. Debugging
  starts with the log, not with the source code.
- Failed commands can be copy-pasted and re-run manually for immediate
  reproduction.
- No one needs to re-run a pipeline with `-Verbose` to find out what
  happened — the information is already there.
- Secret masking is ADO's responsibility. The automation code logs
  freely and ADO redacts what needs redacting.
