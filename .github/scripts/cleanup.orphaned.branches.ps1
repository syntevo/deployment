<#
.SYNOPSIS
    This script cleans the orphaned branches.

.DESCRIPTION
    This PowerShell script is designed to automate the cleanup of orphaned branches.

.EXAMPLE
    cleanup.orphaned.branches.ps1

.NOTES
    This script need to run on a public linux worker

#>

Set-Location -Path ./build

Write-Host "Fetching all branches"
git fetch --all
if (-not $?) {
    exit -1
}

Write-Host "Deleting orphaned branches"
$today = Get-Date
git branch -r --format="%(committerdate:iso8601), %(committerdate:relative) @ %(refname:short)" |
Select-String -Pattern .*/deploy/.* |
ForEach-Object {
    $date = [DateTime]::Parse($_.Line.Trim().Split(",")[0].Trim())
    $ref = $_.Line.Trim().Split("@")[1].Trim()
    $remote = $ref.Split("/")[0].Trim()
    $branch = $ref.Substring($remote.Length + 1)
    [PSCustomObject]@{
        date = $date
        days = ($date - $today).Days
        ref = $ref
        remote = $remote
        branch = $branch
    }
} |
Where-Object { $_.days -lt -1 } |
ForEach-Object {
    git push $_.remote --delete $_.branch
}
