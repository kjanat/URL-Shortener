[CmdletBinding(SupportsShouldProcess = $true)]
param (
    [Parameter(Mandatory = $false, ValueFromPipeline, ValueFromPipelineByPropertyName, HelpMessage = 'The root directory of the Git repository. Defaults to the parent directory of the script.')]
    [ValidateScript({ Test-Path $_ -PathType Container })]
    $GitRoot = [System.String]::IsNullOrWhiteSpace($PSScriptRoot) ?
        [System.IO.Directory]::GetParent("$env:USERPROFILE\Projects\url-shortener\scripts\make-psdocs.ps1").Parent :
        [System.IO.Directory]::GetParent($PSScriptRoot)
)

Write-Verbose "Starting script execution with GitRoot: $GitRoot"
Write-Debug "Script parameters: GitRoot=$GitRoot"

# If module is not installed, install it
if (-not (Get-Module -Name platyPS -ListAvailable)) {
    Write-Verbose 'platyPS module is not installed. Installing it now...'
    Write-Debug "Installing platyPS module... Command: 'Install-Module -Name platyPS -Force -Scope CurrentUser'"
    Install-Module -Name platyPS -Force -Scope CurrentUser
    Write-Verbose "platyPS module installation completed"
} else {
    Write-Verbose 'platyPS module is already installed.'
    Write-Debug "Found platyPS module version: $((Get-Module -Name platyPS -ListAvailable).Version)"
}

# If module is not loaded, import it
if (-not (Get-Module -Name platyPS)) {
    Write-Verbose 'Importing platyPS module...'
    Write-Debug "Importing platyPS module with Import-Module cmdlet"
    Import-Module -Name platyPS
    Write-Verbose "platyPS module import completed"
} else {
    Write-Verbose 'platyPS module is already loaded.'
    Write-Debug "platyPS module already loaded with version: $((Get-Module -Name platyPS).Version)"
}

$powershellFiles = @(
    'Sync-Redirects' #, ''
)

# Add these to path, during the script execution
$originalPath = $env:Path
$env:Path += ";$GitRoot\scripts;$GitRoot\scripts\external-help-files"

Write-Verbose "Processing $($powershellFiles.Count) PowerShell files"
Write-Debug "Files to process:`t$($powershellFiles -join ', ')"

$powershellFiles | ForEach-Object {
    # If the file exists in the docs folder, run Update-MarkdownHelp, else run New-MarkdownHelp
    $psFunction = $_
    $psFile = "${_}.ps1"
    $psFilePath = Join-Path -Path $GitRoot -ChildPath 'scripts' -AdditionalChildPath $psFile
    $psDocsFolder = Join-Path -Path $GitRoot -ChildPath 'docs'
    $psDocsFilePath = Join-Path -Path $psDocsFolder -ChildPath "$($psFunction).md"
    $psScriptsFolder = Join-Path -Path $GitRoot -ChildPath 'scripts'
    $psScriptsExternalHelpFilePath = Join-Path -Path $psScriptsFolder -ChildPath ".externalhelpfiles" -AdditionalChildPath 'en-US'

    # Get the maximum module name length for proper alignment
    $maxNameLength = ($powershellFiles | Measure-Object -Property Length -Maximum).Maximum
    $formatString = "{0,-$maxNameLength} {1}`t{2}"
    
    Write-Verbose ($formatString -f $psFile, '->', $psDocsFilePath)
    Write-Debug "Processing file: `t${psFile}"
    Write-Debug "Function name: `t`t${psFunction}"
    Write-Debug "Resolved file path: `t${psFilePath}"
    Write-Debug "Documentation folder: `t${psDocsFolder}"
    Write-Debug "Expected docs file path:`t${psDocsFilePath}"
    Write-Debug "Scripts folder: `t`t${psScriptsFolder}"
    Write-Debug "External help file path:`t${psScriptsExternalHelpFilePath}"

    if ([System.IO.File]::Exists($psDocsFilePath)) {
        Write-Verbose "Documentation file already exists for ${psFile}, updating..."
        try {
            # Now update the markdown
            New-ExternalHelp `
                -Path $psDocsFolder `
                -OutputPath $psScriptsExternalHelpFilePath <# `
                -Force `
                -ShowProgress #>
            Write-Verbose "Created external help for ${psFile}"

            Write-Debug "Calling Update-MarkdownHelp with Path=${psDocsFolder}"
            Update-MarkdownHelp -Path $psDocsFolder
            Write-Verbose "Updated Markdown help for $psFile"
        }
        catch {
            Write-Error "Error loading commands from ${psFile}: $_"
            Write-Debug "Stack trace: $($_.ScriptStackTrace)"
        }
        finally {
            # Clean up the environment variables
            $env:Path = $originalPath
            Write-Verbose "Restoring original PATH environment variable"
        }
    } else {
        Write-Verbose "Documentation file does not exist for ${psFile}, creating new..."
        Write-Debug "Calling New-MarkdownHelp with Command=${psFilePath}, OutputFolder=${psDocsFolder}"
        
        try {
            # external help file: sync-redirects-help.xml
            # Module Name: ../scripts/Sync-Redirects.ps1

            # Generate the markdown help
            New-MarkdownHelp `
                <# -Command $psFilePath #> `
                -Command $psFunction `
                -OutputFolder $psDocsFolder `
                -OnlineVersionUrl "http://github.com/kjanat/url-shortener/blob/master/docs/${psFunction}.md" `
                -ExcludeDontShow `
                -UseFullTypeName `
                -Metadata @{
                    "ModuleVersion" = '1.0.1'
                } `
                -Force
            Write-Verbose "Created Markdown help for ${psFunction}"

            Write-Verbose "Documentation generation completed for ${psFile}"
        }
        catch {
            Write-Error "Error creating markdown help for ${psFile}: $_"
            throw
        }
        finally {
            # Clean up the environment variables
            $env:Path = $originalPath
            Write-Verbose "Restoring original PATH environment variable"
        }
    }
}

# Clean up the environment variables
$env:Path = $originalPath
Write-Verbose "Restoring original PATH environment variable"

Write-Verbose "Script execution completed successfully"
