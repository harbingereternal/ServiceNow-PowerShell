

#Requires -Version 3.0
[cmdletbinding()]
param()

Write-Verbose $PSScriptRoot

Write-Verbose 'Import everything in subfolders'
foreach ($Folder in @('Private','Public')) {

$Root = Join-Path -Path $PSScriptRoot -ChildPath $Folder
    if (Test-Path -Path $Root) {
        Write-Verbose "Processing folder $Root"
        $Files = Get-ChildItem -Path $Root -Filter *.ps1 -Recurse

        $Files | Where-Object{ $_.Name -notlike '*.Tests.ps1' } |
            ForEach-Object { Write-Verbose $_.BaseName; . $PSItem.FullName }
    }

}

Export-ModuleMember -Function (Get-ChildItem -Path "$PSScriptRoot\Public\*.ps1").BaseName