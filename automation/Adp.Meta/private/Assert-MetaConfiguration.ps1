<#
.SYNOPSIS
    Validates the meta configuration and throws on the first violation found.
#>
function Assert-MetaConfiguration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $Config
    )

    Assert-YmlNaming $Config

    $identifierPattern = '^[a-z][a-z0-9_]*$'
    $errors = [System.Collections.Generic.List[string]]::new()

    # --- Required top-level keys ---
    foreach ($key in 'subscription_types', 'environments', 'environment_types', 'environment_subtypes', 'customers') {
        if (-not $Config.Contains($key)) {
            $errors.Add("Missing required top-level key: '$key'")
        }
    }
    if ($errors.Count -gt 0) { throw ($errors -join "`n") }

    # --- Subscription types ---
    $subTypes = @($Config.subscription_types)
    if ($subTypes.Count -eq 0) {
        $errors.Add('subscription_types is empty')
    }
    $dupes = $subTypes | Group-Object | Where-Object Count -GT 1
    foreach ($d in $dupes) {
        $errors.Add("Duplicate subscription_type: '$($d.Name)'")
    }

    # --- Environment subtypes ---
    $envSubtypes = @($Config.environment_subtypes)
    if ($envSubtypes.Count -eq 0) {
        $errors.Add('environment_subtypes is empty')
    }
    foreach ($st in $envSubtypes) {
        if ($st -notmatch $identifierPattern) {
            $errors.Add("Environment subtype '$st' is not a valid identifier (must match $identifierPattern)")
        }
    }
    $dupes = $envSubtypes | Group-Object | Where-Object Count -GT 1
    foreach ($d in $dupes) {
        $errors.Add("Duplicate environment_subtype: '$($d.Name)'")
    }

    # --- Environments (dev, test, prod, ...) ---
    $envKeys = @($Config.environments.Keys)
    if ($envKeys.Count -eq 0) {
        $errors.Add('environments is empty')
    }
    foreach ($env in $envKeys) {
        if ($env -notmatch $identifierPattern) {
            $errors.Add("Environment shortname '$env' is not a valid identifier (must match $identifierPattern)")
        }
        $entry = $Config.environments[$env]
        if (-not $entry.Contains('details')) {
            $errors.Add("Environment '$env' is missing 'details'")
        }
        if (-not $entry.Contains('subscription_type')) {
            $errors.Add("Environment '$env' is missing 'subscription_type'")
        }
        elseif ($entry.subscription_type -notin $subTypes) {
            $errors.Add("Environment '$env' has invalid subscription_type '$($entry.subscription_type)' (valid: $($subTypes -join ', '))")
        }
    }

    # --- Environment types (customer + shared) ---
    if (-not $Config.environment_types.Contains('customer')) {
        $errors.Add("environment_types is missing 'customer' map")
    }
    if (-not $Config.environment_types.Contains('shared')) {
        $errors.Add("environment_types is missing 'shared' map")
    }

    $customerTypes = @($Config.environment_types.customer.Keys)
    $sharedTypes = @($Config.environment_types.shared.Keys)
    $allTypes = $customerTypes + $sharedTypes

    foreach ($t in $allTypes) {
        if ($t -notmatch $identifierPattern) {
            $errors.Add("Environment type '$t' is not a valid identifier (must match $identifierPattern)")
        }
    }

    # Validate subtypes references for each environment type
    foreach ($scope in 'customer', 'shared') {
        foreach ($t in @($Config.environment_types[$scope].Keys)) {
            $entry = $Config.environment_types[$scope][$t]
            if (-not $entry.Contains('subtypes')) {
                $errors.Add("Environment type '$t' ($scope) is missing 'subtypes'")
                continue
            }
            foreach ($st in @($entry.subtypes)) {
                if ($st -notin $envSubtypes) {
                    $errors.Add("Environment type '$t' ($scope) references unknown subtype '$st' (valid: $($envSubtypes -join ', '))")
                }
            }
            $dupes = @($entry.subtypes) | Group-Object | Where-Object Count -GT 1
            foreach ($d in $dupes) {
                $errors.Add("Environment type '$t' ($scope) has duplicate subtype: '$($d.Name)'")
            }
        }
    }

    $dupes = $customerTypes | Group-Object | Where-Object Count -GT 1
    foreach ($d in $dupes) {
        $errors.Add("Duplicate in environment_types.customer: '$($d.Name)'")
    }
    $dupes = $sharedTypes | Group-Object | Where-Object Count -GT 1
    foreach ($d in $dupes) {
        $errors.Add("Duplicate in environment_types.shared: '$($d.Name)'")
    }

    $overlap = $customerTypes | Where-Object { $_ -in $sharedTypes }
    foreach ($o in $overlap) {
        $errors.Add("Environment type '$o' appears in both customer and shared lists")
    }

    # --- Customers ---
    $customerKeys = @($Config.customers.Keys)
    if ($customerKeys.Count -eq 0) {
        $errors.Add('customers is empty')
    }
    foreach ($name in $customerKeys) {
        if ($name -notmatch $identifierPattern) {
            $errors.Add("Customer shortname '$name' is not a valid identifier (must match $identifierPattern)")
        }
        $cust = $Config.customers[$name]
        if (-not $cust.Contains('details')) {
            $errors.Add("Customer '$name' is missing 'details'")
        }
        if (-not $cust.Contains('environment_types')) {
            $errors.Add("Customer '$name' is missing 'environment_types'")
        }
        else {
            $custTypes = @($cust.environment_types)
            if ($custTypes.Count -eq 0) {
                $errors.Add("Customer '$name' has empty environment_types")
            }
            $dupes = $custTypes | Group-Object | Where-Object Count -GT 1
            foreach ($d in $dupes) {
                $errors.Add("Customer '$name' has duplicate environment_type: '$($d.Name)'")
            }
            foreach ($t in $custTypes) {
                if ($t -notin $customerTypes) {
                    $errors.Add("Customer '$name' references unknown environment_type '$t' (valid: $($customerTypes -join ', '))")
                }
            }
        }
    }

    if ($errors.Count -gt 0) {
        throw "Meta configuration validation failed:`n$($errors -join "`n")"
    }
}
