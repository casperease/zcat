# ADR: Console output matters

## Context

The console is the user interface of a CLI automation platform. There is no GUI, no dashboard, no notification system.
What appears in the terminal is the entire user experience. Every line of output is a UX decision.

Most automation code gets this wrong in one of two ways:

**Too noisy.** Functions log every step, every variable, every decision. The user scrolls through pages of output to find the one line that matters.
In CI, log files become megabytes of noise where the actual error is buried. When everything is highlighted, nothing is.

**Too silent.** Functions produce no output at all. When something takes 30 seconds, the user does not know if it is working or hung.
When something fails, the error appears with no context about what was being attempted.
The user re-runs with `-Verbose` and hopes the information they need is behind that flag.

Both fail the same test: **can the user understand what happened by reading the output once, top to bottom, without re-running anything?**

### What good output looks like

Good output tells a story: what is happening, what happened, and what went wrong — in that order of priority, with nothing else.

```text
[importer.ps1] Loaded in 0.5 seconds
[Install-Poetry] poetry install --no-root
[Invoke-Executable] poetry install --no-root
Installing dependencies from lock file
[Invoke-Python] python deploy.py --env prod
Deployed 3 services
```

Each line earns its place:

- The importer reports load time (is the shell healthy?)
- Commands are logged before execution (what is about to happen?)
- Tool output flows through naturally (what did the tool say?)
- No decoration, no borders, no emoji, no "Step 1 of 5"

### The output hierarchy

PowerShell has built-in output streams and this toolset defines some more.

Use them correctly:

| Stream                     | When to use                                                                          | Visible by default |
| -------------------------- | ------------------------------------------------------------------------------------ | ------------------ |
| `Write-Message`            | One-liner status with caller prefix — command execution, completion, short results   | Yes                |
| `Write-Information`        | Multiline or headerless output — results, tables, formatted data. No colors          | Yes                |
| `Write-InformationColored` | Multiline or headerless output — results, tables, formatted data. With colors        | Yes                |
| `throw` / `Assert-*`       | Something is wrong — execution stops                                                 | Yes                |
| `Write-Verbose`            | Detail that helps debugging but clutters normal output — skip reasons, cache hits    | No (`-Verbose`)    |
| `Write-Debug`              | Internal state dumps for development — variable values, branch decisions             | No (`-Debug`)      |
| `Write-Output`             | Function return values. **Never** use for status messages — it pollutes the pipeline | Captured           |

`Write-Message` is built on `Write-InformationColored` — it adds a `[CallerName]` prefix and routes through the information stream, not directly to the console.
Use it for one-liners where the caller context matters.
Use `Write-Information` directly for multiline output, tables, or any content where the prefix would indent the first line differently from the rest.
Both write to the same stream.

**Do not use `Write-Warning` or `Write-Error`.** The importer sets both `$ErrorActionPreference` and `$WarningPreference` to `Stop`,
so both streams terminate execution. There is no middle ground between "everything is fine" and "stop."
See [error-handling](error-handling.md) for the full rationale and rules.

**`Write-Verbose` deserves the same care as `Write-Information`.** Verbose output is the user's window into what is happening underneath when something is not behaving as expected.
The best time to write a `Write-Verbose` line is during development and debugging — if you needed that information exposed to understand the code's behavior,
you will need it again next time. Leave it in.
Good verbose output turns a 30-minute debugging session into a 30-second `-Verbose` call.

```powershell
# GOOD — verbose captures the decisions the function made
Write-Verbose "Cache hit for tool '$Tool' — skipping version check"
Write-Verbose "Resolved config path: $configPath"
Write-Verbose "$Tool is already installed — skipping"

# BAD — verbose restates what the code obviously does
Write-Verbose "Entering function"
Write-Verbose "Setting variable"
Write-Verbose "Returning result"
```

The distinction between `Write-Message` and `Write-Verbose` is about audience, not importance.
`Write-Message` is for the user running the automation: what happened, what was executed.
`Write-Verbose` is for the user diagnosing the automation: why a decision was made, what was skipped, what path was resolved.
Both streams deserve thoughtful content.

### Rules for output

**Log commands, not commentary.** `Invoke-XyzCli` logs the exact command before every external invocation (see [log-before-invoke](log-before-invoke.md)).
This is the most valuable output: it tells the user what ran, and they can copy-paste it to reproduce.
Do not add "Now installing Poetry..." before the command — the command itself is more informative.

**Let tools speak for themselves.** When `poetry install` produces output, let it flow to the console. Do not capture and re-format it.
Do not prefix each line.
The user knows what poetry output looks like — wrapping it in your own formatting makes it harder to read and impossible to search for in documentation.

**Report outcomes, not steps.** "Poetry 2.1 installed successfully" is an outcome.
"Checking if poetry is installed... Poetry is installed... Checking version... Version matches... Running poetry install... Done" is step-by-step narration that nobody reads.
Report the end state, not the journey.

**Silence is acceptable.** A function that succeeds with nothing to report should produce no output.
`Assert-Command python` succeeds silently — the absence of an error _is_ the output. Do not add "Python found!" for reassurance.

**Errors must be self-contained.** When a function throws, the error message must contain everything needed to diagnose the problem without reading source code.
"'Python' is not installed" is good. "Assertion failed" is not. The `Assert-*` library provides structured error messages by convention.

**Use color sparingly and consistently.** Color draws the eye — use it only for information that deserves attention.
Both GitHub Actions and Azure DevOps render ANSI colors in their log viewers, so color choices matter everywhere, not just in local terminals.

| Color   | Meaning                                       |
| ------- | --------------------------------------------- |
| Red     | Errors — something failed                     |
| Yellow  | Warnings — something needs attention          |
| Green   | Success confirmations (use sparingly)         |
| Cyan    | Headers and section dividers                  |
| Default | Everything else — normal informational output |

Consistent color creates a visual language the human eye learns to scan. In a 200-line CI log, a single red line jumps out immediately.
If half the output is colorized for decoration, that signal is lost.
Do not colorize normal output for emphasis — the default color _is_ the signal that nothing is wrong.

**No side borders or box drawing.** Never wrap output in decorative frames:

```text
# WRONG — cannot copy-paste the content without editing out the borders
| Deploying to prod   |
| 3 services updated  |

# WRONG
+---------------------+
| Environment: prod   |
+---------------------+

# RIGHT — headers and footers are fine, content is plain
--- Deploying to prod ---
3 services updated
```

Side borders (`|`, `+--+`, `║`) break copy-paste.
The user has to manually strip decoration from every line to use the output.
Headers (`---`, `===`, `Write-Header`) and blank-line separators are fine — they frame the output vertically without touching the content itself.

**No progress bars.** `Write-Progress` does not play well with automation output. It overwrites previous lines, disappears from CI logs entirely,
clutters the terminal in interactive use, and adds significant complexity to the code (calculating percentages, estimating remaining time, managing activity IDs).
For long-running operations, print a dot (`.`) for each interval that passes:

```powershell
while (-not $done) {
    Start-Sleep -Seconds 1
    Write-Host '.' -NoNewline
}
Write-Host ''   # newline after dots
```

This tells the user the operation is alive without any of the overhead.
The dots appear in CI logs, in terminals, and in redirected output. No special handling needed.

**Timestamps are opt-in.** `Write-Message` includes a caller name prefix by default (`[Invoke-Executable] poetry install`).
Timestamps can be enabled via `$env:ZCAT_MESSAGE_TIMESTAMPS` for local debugging.
CI platforms (ADO, GitHub Actions) already timestamp every log line natively, so this is never needed there.

## Decision

Console output is a first-class UX concern. Every line must earn its place.
Functions use the correct output stream, log commands before execution, report outcomes not steps, and stay silent when there is nothing meaningful to say.

### How this is enforced

- **The Writer module** — provides all output functions: `Write-Message`, `Write-Object`, `Write-Header`, `Write-Exception`,
  and others. These are the building blocks for uniform console output. Use them instead of raw `Write-Host` or `Write-Information`.
- **`Write-Message`** — the principal communication tool. Every message includes the calling function name automatically (`[Invoke-Executable] poetry install`),
  so the user always knows which function produced the output.
  Timestamps can be enabled via `$env:ZCAT_MESSAGE_TIMESTAMPS` for local debugging — CI platforms (ADO, GitHub Actions) already timestamp every log line natively.
  Console output is suppressed during Pester runs so test output stays clean.
- **`Invoke-Executable`** — logs the exact command via `Write-Message` before execution. All `Invoke-*` wrappers inherit this.
- **Code review** — output quality is a review concern, same as logic correctness. A function that spams the console or swallows errors is a bug.

## Consequences

- Users can read CI logs top-to-bottom and understand what happened without re-running.
- Interactive sessions are clean — output is signal, not noise.
- Copy-paste debugging works — commands are logged exactly as executed.
- The output is the documentation. When a user runs `Install-DevBoxTools`,
  the console tells them what was installed, at what versions, and whether it succeeded. No README needed for the happy path.
