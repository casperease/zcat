# ADR: Fail fast with inline assertions

## Context

PowerShell automation code is fundamentally about side effects — creating
resources, calling APIs, installing tools, writing files. This makes it
hard to test with traditional unit testing approaches:

- **Mocking is fragile and misleading.** You can mock `Invoke-CliCommand`
  to return a canned string, but that tells you nothing about whether the
  real CLI will behave the same way. Mock-heavy tests pass in CI and fail
  in production because the mock did not replicate the real tool's exit
  codes, stderr behavior, or edge cases. We learned this the hard way.

- **Integration tests are slow and environment-dependent.** A real test
  that installs Python, runs poetry, and deploys to Azure takes minutes,
  requires credentials, and breaks when the network is flaky. You cannot
  run these on every save.

- **Coverage is deceptive.** You can hit 90% line coverage and still miss
  the bug, because the bug is not in the logic — it is in the assumption
  that a variable is non-null, a path exists, a command returned the
  expected format, or an exit code was zero. These are the actual failure
  modes of automation code.

Traditional testing works best for pure functions with inputs and outputs.
Automation code is mostly impure — it orchestrates external systems. We
need a strategy that matches this reality.

### The inline assertion pattern

Instead of relying solely on after-the-fact testing, we build quality
*into* the code itself with inline assertions. The principle: **assert
every assumption at the point where it is made.** On average, roughly
every fifth line of code should be an assertion.

This is not a replacement for Pester tests — it is a complementary
strategy. Pester tests verify behavior in controlled conditions. Inline
assertions verify assumptions in *every* execution, including production,
including the edge cases no test anticipated.

### What this looks like in practice

```powershell
function Invoke-Poetry {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string] $Arguments
    )

    Assert-NotNullOrWhitespace $Arguments           # validate input
    Assert-Command poetry                           # tool exists
    Assert-ToolVersion -Tool 'Poetry'               # correct version

    $result = Invoke-CliCommand "poetry $Arguments" -PassThru
    Assert-NotNullOrWhitespace $result              # got output

    $result
}
```

Five functional lines, four assertions. This is not excessive — it is the
minimum needed to produce a clear error for every failure mode:

- Caller passed empty arguments → immediate throw with parameter name
- Poetry not installed → immediate throw naming the missing tool
- Poetry is the wrong version → immediate throw with expected vs actual
- Command produced no output → immediate throw at the source

Without the assertions, all four failures eventually surface as something
unhelpful: `Cannot index into a null array` three functions down the call
stack, or a silent empty result that corrupts downstream state.

### Why every fifth line

The ratio is a guideline, not a rigid rule. The point is that assertions
should be *pervasive*, not sprinkled in as an afterthought. Code that goes
20 lines without an assertion is almost certainly making unchecked
assumptions. Common assertion points:

- **Function entry.** Validate parameters beyond what `[Parameter]`
  attributes can express. Check that paths exist, strings are non-empty,
  objects have expected properties.

- **After external calls.** CLI tools, APIs, and file operations can fail
  in ways that do not throw — non-zero exit codes, empty responses, partial
  writes. Assert the result is what you expected.

- **Before using a value.** If a variable could be null, empty, or the
  wrong type, assert before using it. Do not trust upstream code to have
  validated it — the upstream code might change.

- **State transitions.** After modifying state (environment variables,
  files, registry), assert the state is what you set it to. External
  processes, group policies, or concurrent scripts can interfere.

## Decision

Use inline assertions pervasively throughout all automation code. Every
assumption about inputs, state, and external results must be asserted at
the point where the assumption is made.

### Rules

- **Assert inputs at function entry.** Use `Assert-NotNullOrWhitespace`,
  `Assert-True`, `Assert-PathExist`, `Assert-TypeIs`, and other `Assert-*`
  functions to validate everything that `[Parameter]` attributes cannot
  express.

- **Assert after every external call.** After `Invoke-CliCommand`,
  `Get-Content`, API calls, or any operation that talks to the outside
  world, assert the result meets expectations before passing it downstream.

- **Assert preconditions, not just inputs.** `Assert-Command` and
  `Assert-ToolVersion` verify that the environment is in the expected state
  before doing work. This is a precondition assertion, not input
  validation.

- **Use the `Assert-*` library, do not inline `if/throw`.** The `Assert-*`
  functions provide consistent error messages, are greppable, and make
  the assertion intent visible in code review. Bare `if (-not $x) { throw }`
  obscures the intent.

- **Never catch assertion failures.** Assertions indicate a bug or an
  unmet precondition — not a recoverable error. They should propagate
  to the caller. If you find yourself wrapping an assertion in
  `try`/`catch`, either the assertion is wrong or the code should handle
  the condition differently.

- **Assertions are documentation.** `Assert-PathExist $configPath` tells
  the reader that the path must exist at this point. It is both a runtime
  check and a specification of the function's expectations. This is more
  reliable than a comment, because it executes.

## Consequences

- Errors surface immediately at the point of failure with a clear message
  naming the exact assumption that was violated.
- Stack traces are short — typically one or two frames — because the
  assertion fires before the bad value propagates.
- Debugging is rarely needed. The error message from the assertion usually
  contains everything needed to diagnose the problem.
- Code is self-documenting: reading the assertions tells you the function's
  preconditions, postconditions, and invariants.
- Performance cost is negligible — assertions are simple boolean checks.
  The cost of *not* asserting (silent corruption, misleading errors, hours
  of debugging) is orders of magnitude higher.
- Pester tests focus on behavior and integration, not on re-checking
  assumptions that the code already asserts on every execution.
