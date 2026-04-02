# ADR: Pipeline runner pattern — how pipelines invoke automation

## Context

Azure DevOps pipelines execute YAML steps. PowerShell automation lives in modules under `automation/`.
The bridge between them — how a YAML step invokes a PowerShell function — is a critical boundary.

### The naive approach

The tempting approach is to inline PowerShell directly in each YAML step:

```yaml
- pwsh: |
    . ./importer.ps1
    Install-DevBoxTools
    Test-Automation
```

This works but scales poorly. Every step reimports the module system from scratch, duplicates the importer invocation,
and scatters PowerShell logic across YAML files where it cannot be tested, linted, or reused.
When the import pattern changes, every pipeline must be updated.

### The runner pattern

A single `Run.ps1` script acts as the universal entry point for all pipeline steps.
It handles bootstrapping (importing modules, setting preferences) once, then executes whatever command the pipeline passes in.

The YAML layer becomes purely declarative — it names the command to run and any pipeline-specific concerns
(service connections, environment approvals, checkout depth). It never contains PowerShell logic.

### Why a dedicated runner script

**Single point of bootstrap.** The importer, error handling, and trap setup live in one place.
When the bootstrap pattern changes, one file changes — not every pipeline.

**Testable commands.** The `RunCommand` passed to the runner is the same command a developer types interactively.
You can reproduce any pipeline step by running the same command locally. No YAML-specific behavior to account for.

**Separation of concerns.** YAML handles pipeline orchestration (triggers, environments, approvals, artifacts).
PowerShell handles automation logic. The runner is the only seam between them.

## Decision

All pipeline steps invoke PowerShell through a runner script. YAML steps never contain inline PowerShell logic
beyond calling the runner.

### Structure

```
pipelines/
  Run.ps1                          universal pipeline entry point
  steps/
    invoke-automation.yaml         unified step template with Mode and security flags
```

### The runner

`Run.ps1` accepts a command string, bootstraps the module system, sanitizes YAML/ADO escaping
artifacts via `ConvertFrom-PipelineCommand`, and executes the command:

```powershell
param([Parameter(Mandatory)] [string] $Command)

. $PSScriptRoot/../importer.ps1
trap { Write-Exception $_; break }

$sanitized = ConvertFrom-PipelineCommand $Command
$block = [ScriptBlock]::Create($sanitized)
Invoke-Command -ScriptBlock $block -NoNewScope
```

The `-NoNewScope` flag ensures the command runs in the same scope as the importer,
so all imported functions are available without qualification.

`ConvertFrom-PipelineCommand` normalizes line endings, trims whitespace artifacts from YAML
indentation, and preserves intentional newlines for multiline command support.

### The step template

`invoke-automation.yaml` is a single template with flags for authentication mode and
credential exposure:

```yaml
parameters:
  - name: RunCommand        # The command to execute
  - name: Mode              # none | azcli | azps — selects the task type
  - name: ExposeAccessToken # Maps SYSTEM_ACCESSTOKEN when true
  - name: ServiceConnection # Required when Mode is azcli or azps
```

| Mode | Task | Credentials in env vars? |
|------|------|--------------------------|
| `none` | `PowerShell@2` | None |
| `azcli` | `AzureCLI@2` | None — az CLI auth is task-internal |
| `azps` | `AzurePowerShell@5` | None — Az module auth is task-internal |

`ExposeAccessToken` is orthogonal — adds `SYSTEM_ACCESSTOKEN` on any mode.

### Pipeline usage

```yaml
# Plain command — no auth
- template: /pipelines/steps/invoke-automation.yaml
  parameters:
    RunCommand: 'Test-Automation'

# Azure CLI + system token
- template: /pipelines/steps/invoke-automation.yaml
  parameters:
    RunCommand: 'Deploy-Infrastructure'
    Mode: azcli
    ExposeAccessToken: true
    ServiceConnection: 'sc-my-subscription'

# Multiline command (YAML pipe operator)
- template: /pipelines/steps/invoke-automation.yaml
  parameters:
    RunCommand: |
      $config = Get-MetaConfiguration
      Deploy-Infrastructure -Config $config
    Mode: azcli
    ServiceConnection: 'sc-my-subscription'
```

The `displayName` mirrors the command, so the ADO UI shows exactly what ran — no "Run PowerShell script" labels.

### Rules

- **YAML steps never contain inline PowerShell.** All PowerShell execution goes through the runner or a step template that calls it.

- **The runner imports once.** The module system is bootstrapped at the start of `Run.ps1`. The command runs in the same scope.

- **Step templates are thin wrappers.** They add pipeline concerns (service connections, token injection, display names) but never contain logic.

- **Commands are developer-reproducible.** Whatever string appears in `RunCommand` can be pasted into a local terminal after running `.\importer.ps1`.

## Consequences

- Pipeline YAML is declarative and reviewable by anyone — no PowerShell knowledge required to understand the flow.
- Bootstrap changes are a single-file edit, not a pipeline-wide search-and-replace.
- Every pipeline step is locally reproducible by running the same command after the importer.
- Step templates compose cleanly — add authentication, artifact handling, or diagnostics without touching the command.
- The runner is itself testable — import + execute is a pure pattern with no hidden state.
