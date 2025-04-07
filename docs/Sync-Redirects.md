---
external help file: Sync-Redirects-help.xml
ModuleVersion: 1.0.1
online version: https://github.com/kjanat/url-shortener/blob/master/docs/Sync-Redirects.md
schema: 2.0.0
---

# Sync-Redirects

## SYNOPSIS

Synchronizes redirects between JSON and YAML files.

## SYNTAX

```pwsh
Sync-Redirects `
    [[-GitRoot] <String>] `
    [[-jsonFile] <String>] `
    [[-yamlFile] <String>] `
    [-ProgressAction <ActionPreference>] `
    [-WhatIf] `
    [-Confirm] `
    [<CommonParameters>]
```

## DESCRIPTION

This function compares the contents of a JSON file and a YAML file, determines which file is newer, and updates the other file with any missing entries.

## EXAMPLES

### EXAMPLE 1

```pwsh
Sync-Redirects.ps1
```

This example synchronizes the redirects between the default JSON and YAML files in the script's directory.

### EXAMPLE 2

```pwsh
Sync-Redirects.ps1 `
    -jsonFile "C:\path\to\redirects.json" `
    -yamlFile "C:\path\to\redirects.yml"
```

Synchronizes the redirects between the specified JSON and YAML files.

### EXAMPLE 3

```pwsh
Sync-Redirects.ps1 `
    -GitRoot "C:\path\to\git\repository" `
    -jsonFile "C:\path\to\redirects.json" `
    -yamlFile "C:\path\to\redirects.yml"
```

Synchronizes the redirects between the specified JSON and YAML files in the specified Git repository.

## PARAMETERS

### -GitRoot

The root directory of the Git repository containing the JSON and YAML files.

```yaml
Type: System.Object
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: "($PSScriptRoot -match '^\s*$' ? (Get-Item 'C:\Users\kjana\Projects\url-shortener\') : (Get-Item $PSScriptRoot).Parent)"
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -jsonFile

The path to the JSON file containing redirects.

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: "(Join-Path -Path $GitRoot -ChildPath 'redirects.json')"
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -yamlFile

The path to the YAML file containing redirects.

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: "(Join-Path -Path $GitRoot -ChildPath 'redirects.yml')"
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -ProgressAction

The action to take when progress information is written. The default value is `Continue`, which displays the progress bar. Other options include `SilentlyContinue`, `Inquire`, `Ignore`, and `Stop`.

```yaml
Type: System.Management.Automation.ActionPreference
Parameter Sets: (All)
Aliases: proga

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -WhatIf

```yaml
Type: System.Management.Automation.SwitchParameter
Parameter Sets: (All)
Aliases: wi

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Confirm

```yaml
Type: System.Management.Automation.SwitchParameter
Parameter Sets: (All)
Aliases: cf

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters: `-Debug`, `-ErrorAction`, `-ErrorVariable`, `-InformationAction`, `-InformationVariable`, `-OutVariable`, `-OutBuffer`, `-PipelineVariable`, `-Verbose`, `-WarningAction`, and `-WarningVariable`.  
For more information, see [about_CommonParameters](https://go.microsoft.com/fwlink/?LinkID=113216).

## RELATED LINKS

[Sync-Redirects Documentation](https://github.com/kjanat/url-shortener/blob/master/docs/Sync-Redirects.md)
