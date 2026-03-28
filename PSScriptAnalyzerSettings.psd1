@{
    Severity = @('Error', 'Warning', 'Information')

    CustomRulePath = @(
        'automation/.scriptanalyzer/VariableCasing.psm1'
        'automation/.scriptanalyzer/NeverDependOnPwd.psm1'
        'automation/.scriptanalyzer/FunctionLength.psm1'
        'automation/.scriptanalyzer/NoWriteErrorOrWarning.psm1'
        'automation/.scriptanalyzer/NoAzModuleNaming.psm1'
    )

    ExcludeRules = @(
        # We use UTF-8 without BOM — BOM causes issues with many tools
        'PSUseBOMForUnicodeEncodedFile'
        # Too many false positives on lightweight functions (Reset-, New-, etc.)
        'PSUseShouldProcessForStateChangingFunctions'
        # Plural nouns are often more natural (Import-AllModules, Get-Items, etc.)
        'PSUseSingularNouns'
        # False positive on Get-ChildItem with -Filter/-File/-Directory parameter sets
        'PSUseCmdletCorrectly'
        # Runtime return types rarely match declared OutputType (e.g. @() returns System.Array)
        'PSUseOutputTypeCorrectly'
    )

    Rules = @{
        # ── Enabled by default ──────────────────────────────────────

        # Requires comment-based help (.SYNOPSIS etc.) on exported functions.
        # ExportedOnly limits this to public functions only.
        PSProvideCommentHelp = @{
            Enable                  = $true
            ExportedOnly            = $true
            BlockComment            = $true
            VSCodeSnippetCorrection = $false
            Placement               = 'before'
        }

        # Flags function parameters that are declared but never used in the body.
        # CommandsToTraverse lists cmdlets whose scriptblock params should be checked too.
        PSReviewUnusedParameter = @{
            Enable             = $true
            CommandsToTraverse = @()
        }

        # Warns when a function shadows a built-in cmdlet name.
        # PowerShellVersion scopes which built-ins to check against.
        PSAvoidOverwritingBuiltInCmdlets = @{
            Enable            = $true
            PowerShellVersion = @('core-6.1.0-windows', 'core-6.1.0-linux', 'core-6.1.0-macos')
        }

        # Flags use of aliases (like % instead of ForEach-Object) in scripts.
        # allowlist permits specific aliases you want to keep.
        PSAvoidUsingCmdletAliases = @{
            Enable    = $true
            allowlist = @()
        }

        # Checks that cmdlets used in your code exist in the target PowerShell version.
        # compatibility lists platform profiles to validate against.
        PSUseCompatibleCmdlets = @{
            Enable        = $true
            compatibility = @(
                'win-4_x64_10.0.18362.0_7.0.0_x64_3.1.2_core'
                'ubuntu_x64_18.04_7.0.0_x64_3.1.2_core'
            )
        }

        # ── Disabled by default (opt-in) ────────────────────────────
        # Uncomment and set Enable = $true to activate.

        # Aligns assignment operators (=) vertically in consecutive assignments
        # and hashtable entries for visual consistency.
        PSAlignAssignmentStatement = @{
            Enable                                  = $true
            CheckHashtable                          = $true
            AlignHashtableKvpWithInterveningComment = $true
            CheckEnum                               = $true
            AlignEnumMemberWithInterveningComment   = $true
            IncludeValuelessEnumMembers             = $true
        }

        # Flags use of the ! operator — prefers -not for readability.
        PSAvoidExclaimOperator = @{
            Enable = $true
        }

        # Warns when a line exceeds MaximumLineLength characters.
        # PSAvoidLongLines = @{
        #     Enable            = $true
        #     MaximumLineLength = 120
        # }

        # Flags semicolons used as line terminators — PowerShell doesn't need them.
        PSAvoidSemicolonsAsLineTerminators = @{
            Enable = $true
        }

        # Flags double-quoted strings that contain no variable expansion or escapes,
        # suggesting single quotes instead.
        PSAvoidUsingDoubleQuotesForConstantString = @{
            Enable = $true
        }

        # Enforces consistent placement of closing braces (}).
        PSPlaceCloseBrace = @{
            Enable             = $true
            NoEmptyLineBefore  = $false
            IgnoreOneLineBlock = $true
            NewLineAfter       = $true
        }

        # Enforces consistent placement of opening braces ({).
        # OnSameLine = K&R style, $false = Allman style.
        PSPlaceOpenBrace = @{
            Enable             = $true
            OnSameLine         = $true
            NewLineAfter       = $true
            IgnoreOneLineBlock = $true
        }

        # Checks that commands used in your code exist in target PowerShell profiles.
        # TargetProfiles lists platform/version profiles to validate against.
        # PSUseCompatibleCommands = @{
        #     Enable         = $true
        #     TargetProfiles = @()
        #     IgnoreCommands = @()
        # }

        # Checks that syntax used is valid in older PowerShell versions.
        # TargetVersions lists the versions to validate against.
        # PSUseCompatibleSyntax = @{
        #     Enable         = $true
        #     TargetVersions = @()
        # }

        # Checks that .NET types used exist in target PowerShell profiles.
        PSUseCompatibleTypes = @{
            Enable         = $true
            TargetProfiles = @(
                'win-4_x64_10.0.18362.0_7.0.0_x64_3.1.2_core'
                'ubuntu_x64_18.04_7.0.0_x64_3.1.2_core'
            )
            IgnoreTypes    = @()
        }

        # Enforces consistent indentation (spaces vs tabs, indent size).
        # PipelineIndentation controls how continuation lines in pipelines indent.
        PSUseConsistentIndentation = @{
            Enable              = $true
            IndentationSize     = 4
            PipelineIndentation = 'IncreaseIndentationForFirstPipeline'
            Kind                = 'space'
        }

        # Warns when the same parameter set name appears in multiple functions,
        # which can cause confusion.
        # PSUseConsistentParameterSetName = @{
        #     Enable = $true
        # }

        # Enforces that all parameters use either param() blocks or function(args)
        # style consistently.
        PSUseConsistentParametersKind = @{
            Enable         = $true
            ParametersKind = 'ParamBlock'
        }

        # Enforces consistent whitespace around braces, parens, operators, pipes,
        # and separators.
        PSUseConsistentWhitespace = @{
            Enable                                  = $true
            CheckInnerBrace                         = $true
            CheckOpenBrace                          = $true
            CheckOpenParen                          = $true
            CheckOperator                           = $true
            CheckPipe                               = $true
            CheckPipeForRedundantWhitespace         = $false
            CheckSeparator                          = $true
            CheckParameter                          = $false
            IgnoreAssignmentOperatorInsideHashTable  = $false
        }

        # Warns when code doesn't run under Constrained Language Mode (CLM),
        # used in locked-down environments like AppLocker/WDAC.
        # PSUseConstrainedLanguageMode = @{
        #     Enable           = $true
        #     IgnoreSignatures = $false
        # }

        # Fixes casing of commands, keywords, and operators to match their
        # canonical definitions (e.g., ForEach-Object not foreach-object).
        PSUseCorrectCasing = @{
            Enable        = $true
            CheckCommands = $true
            CheckKeyword  = $true
            CheckOperator = $true
        }

        # Warns when a pipeline parameter accepts an array — suggests accepting
        # single values and using the pipeline for collections instead.
        PSUseSingleValueFromPipelineParameter = @{
            Enable = $true
        }
    }
}
