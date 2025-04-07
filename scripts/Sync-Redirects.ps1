<#
.SYNOPSIS
Synchronizes redirects between JSON and YAML files.

.DESCRIPTION
This function compares the contents of a JSON file and a YAML file, determines which file is newer, and updates the other file with any missing entries.

.PARAMETER GitRoot
The root directory of the Git repository containing the JSON and YAML files.

.PARAMETER jsonFile
The path to the JSON file containing redirects.

.PARAMETER yamlFile
The path to the YAML file containing redirects.

.EXAMPLE
Sync-Redirects.ps1

This example synchronizes the redirects between the default JSON and YAML files in the script's directory.

.EXAMPLE
Sync-Redirects.ps1 `
    -jsonFile "C:\path\to\redirects.json" `
    -yamlFile "C:\path\to\redirects.yml"

Synchronizes the redirects between the specified JSON and YAML files.

.EXAMPLE
Sync-Redirects.ps1 `
    -GitRoot "C:\path\to\git\repository" `
    -jsonFile "C:\path\to\redirects.json" `
    -yamlFile "C:\path\to\redirects.yml"

Synchronizes the redirects between the specified JSON and YAML files in the specified Git repository.

.LINK
https://github.com/kjanat/url-shortener/blob/master/docs/Sync-Redirects.md

.EXTERNALHELP .externalhelpfiles/en-US/Sync-Redirects-help.xml
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param (
    [Parameter(Mandatory = $false, ValueFromPipeline, ValueFromPipelineByPropertyName, HelpMessage = 'The root directory of the Git repository. Defaults to the parent directory of the script.')]
    [ValidateScript({ Test-Path $_ -PathType Container })]
    [string]$GitRoot = ($PSScriptRoot -match '^\s*$') ? (Get-Item "$env:USERPROFILE\Projects\url-shortener\") : (Get-Item $PSScriptRoot).Parent,

    [Parameter(Mandatory = $false, ValueFromPipeline, ValueFromPipelineByPropertyName, HelpMessage = 'The path to the JSON file containing redirects.')]
    [ValidateScript({ Test-Path $_ -PathType Leaf })]
    [string]$jsonFile = (Join-Path -Path $GitRoot -ChildPath 'redirects.json'),

    [Parameter(Mandatory = $false, ValueFromPipeline, ValueFromPipelineByPropertyName, HelpMessage = 'The path to the YAML file containing redirects.')]
    [ValidateScript({ Test-Path $_ -PathType Leaf })]
    [string]$yamlFile = (Join-Path -Path $GitRoot -ChildPath 'redirects.yml')
)

Write-Verbose 'Starting redirects synchronization process'

# Write debug the variables from parameters
$PSBoundParameters.GetEnumerator() | ForEach-Object {
    Write-Debug "$($_.Key):`t`t$($_.Value)"
}
Write-Debug "GitRoot: `t$GitRoot"
Write-Debug "jsonFile:`t$jsonFile"
Write-Debug "yamlFile:`t$yamlFile"

# Load required module
Write-Verbose 'Checking for required module: powershell-yaml'
if (-not (Get-Module -ListAvailable -Name powershell-yaml)) {
    Write-Error "The 'powershell-yaml' module is required. Please install it using 'Install-Module powershell-yaml'."
    exit 1
}
Write-Debug "Module 'powershell-yaml' is available"

# Get file modification times
Write-Verbose 'Getting file modification times'
$jsonLastModified = (Get-Item $jsonFile).LastWriteTime
$yamlLastModified = (Get-Item $yamlFile).LastWriteTime
Write-Debug "JSON last modified: $(Get-Date $jsonLastModified -UFormat '%c')"
Write-Debug "YAML last modified: $(Get-Date $yamlLastModified -UFormat '%c')"

# Load file contents
Write-Verbose 'Loading file contents'
$jsonData = Get-Content $jsonFile | ConvertFrom-Json -AsHashtable
$yamlData = Get-Content $yamlFile | ConvertFrom-Yaml
Write-Debug "JSON entries count: $($jsonData.Count)"
Write-Debug "YAML entries count: $($yamlData.Count)"

# Determine the newer file
if ($jsonLastModified -gt $yamlLastModified) {
    Write-Verbose 'JSON file is newer than YAML file'
    $hasChanges = $false
    if ($yamlData.Count -lt $jsonData.Count) {
        Write-Information 'JSON file has more entries than YAML file' -InformationAction Continue
        $hasChanges = $true
    } elseif ($yamlData.Count -gt $jsonData.Count) {
        Write-Information 'YAML file has more entries than JSON file' -InformationAction Continue
        $hasChanges = $true
    } else {
        Write-Information 'JSON file has the same number of entries as YAML file' -InformationAction Continue
        foreach ($key in $yamlData.Keys) {
            if (-not $jsonData.ContainsKey($key)) {
                Write-Debug "Found key in YAML missing from JSON: $key"
                $jsonData[$key] = $yamlData[$key]
                $hasChanges = $true
            }
        }
    }

    if ($hasChanges) {
        Write-Information 'Found entries in YAML that need to be added to JSON' -InformationAction Continue
        if ($PSCmdlet.ShouldProcess($jsonFile, 'Update JSON file with missing entries from YAML')) {
            Write-Verbose 'Updating JSON file with missing entries from YAML'
            $jsonData | 
                ConvertTo-Json -Depth 3 | 
                Set-Content $jsonFile -Force
        }
        if ($PSCmdlet.ShouldProcess($yamlFile, 'Update YAML file from JSON data')) {
            Write-Verbose 'Updating YAML file from JSON data for consistency'
            $jsonData | ConvertTo-Yaml `
                -OutFile $yamlFile `
                -Force
        }
        if (-not $WhatIfPreference) {
            Write-Information 'Synchronized YAML to JSON.' -InformationAction Continue
        }
    } else {
        Write-Information 'No changes needed for synchronization.' -InformationAction Continue
    }
} elseif ($yamlLastModified -gt $jsonLastModified) {
    Write-Verbose 'YAML file is newer than JSON file'
    $hasChanges = $false
    if ($jsonData.Count -lt $yamlData.Count) {
        Write-Information 'YAML file has more entries than JSON file' -InformationAction Continue
        $hasChanges = $true
    } elseif ($jsonData.Count -gt $yamlData.Count) {
        Write-Information 'JSON file has more entries than YAML file' -InformationAction Continue
        $hasChanges = $true
    } else {
        Write-Information 'YAML file has the same number of entries as JSON file' -InformationAction Continue
        foreach ($key in $jsonData.Keys) {
            if (-not $yamlData.ContainsKey($key)) {
                Write-Debug "Found key in JSON missing from YAML: $key"
                $yamlData[$key] = $jsonData[$key]
                $hasChanges = $true
            }
        }
    }

    if ($hasChanges) {
        Write-Information 'Found entries in JSON that need to be added to YAML' -InformationAction Continue
        if ($PSCmdlet.ShouldProcess($yamlFile, 'Update YAML file with missing entries from JSON')) {
            Write-Verbose 'Updating YAML file with missing entries from JSON'
            $yamlData | ConvertTo-Yaml -OutFile $yamlFile -Force
        }
        if ($PSCmdlet.ShouldProcess($jsonFile, 'Update JSON file from YAML data')) {
            Write-Verbose 'Updating JSON file from YAML data for consistency'
            $yamlData | ConvertTo-Yaml `
                -JsonCompatible `
                -OutFile $jsonFile `
                -Force
        }
        if (-not $WhatIfPreference) {
            Write-Information 'Synchronized JSON to YAML.' -InformationAction Continue
        }
    } else {
        Write-Information 'No changes needed for synchronization.' -InformationAction Continue
    }
} else {
    Write-Information 'Both files are already synchronized.' -InformationAction Continue
    Write-Debug "JSON and YAML timestamps are identical: $jsonLastModified"
}

Write-Verbose 'Redirects synchronization process completed'
