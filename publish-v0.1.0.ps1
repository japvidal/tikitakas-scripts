param(
    [string]$BackendRoot = "C:\programming\codex\tikitakas\backend",
    [string]$BranchName = "v0.1.0",
    [string]$CommitMessage = "Initial backend import",
    [switch]$InferMissingOrigin = $true,
    [switch]$SkipPush
)

$ErrorActionPreference = "Stop"

$requiredIgnoreEntries = @(
    "target/",
    "*.log",
    "*.out.log",
    "*.err.log",
    ".classpath",
    ".project",
    ".settings/",
    ".vscode/",
    ".idea/",
    "!.mvn/wrapper/maven-wrapper.jar"
)

function Ensure-GitIgnoreEntries {
    param(
        [string]$RepoPath
    )

    $gitIgnorePath = Join-Path $RepoPath ".gitignore"
    if (Test-Path $gitIgnorePath) {
        $existingLines = Get-Content $gitIgnorePath
    } else {
        $existingLines = @()
    }

    $missingEntries = @()
    foreach ($entry in $requiredIgnoreEntries) {
        if ($existingLines -notcontains $entry) {
            $missingEntries += $entry
        }
    }

    if ($missingEntries.Count -eq 0) {
        return
    }

    $content = @()
    if ($existingLines.Count -gt 0) {
        $content += $existingLines
        $content += ""
    }
    $content += "# Codex publish defaults"
    $content += $missingEntries
    Set-Content -Path $gitIgnorePath -Value $content
}

function Invoke-Git {
    param(
        [string]$RepoPath,
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Args
    )

    & git -C $RepoPath @Args
    if ($LASTEXITCODE -ne 0) {
        throw "git $($Args -join ' ') failed in $RepoPath"
    }
}

$repos = Get-ChildItem $BackendRoot -Directory | Where-Object {
    Test-Path (Join-Path $_.FullName ".git")
}

$results = New-Object System.Collections.Generic.List[object]

foreach ($repo in $repos) {
    $repoPath = $repo.FullName
    $repoName = $repo.Name
    $result = [ordered]@{
        Name = $repoName
        Branch = $BranchName
        Remote = ""
        Commit = ""
        Status = "Pending"
        Detail = ""
    }

    try {
        Ensure-GitIgnoreEntries -RepoPath $repoPath

        $remote = (& git -C $repoPath remote get-url origin 2>$null | Select-Object -First 1)
        if ([string]::IsNullOrWhiteSpace($remote) -and $InferMissingOrigin) {
            $remote = "https://github.com/japvidal/$repoName.git"
            & git -C $repoPath remote add origin $remote | Out-Null
            if ($LASTEXITCODE -ne 0) {
                throw "No se pudo crear origin para $repoName"
            }
        }

        if ([string]::IsNullOrWhiteSpace($remote)) {
            throw "El repositorio no tiene origin configurado"
        }

        $result.Remote = $remote

        $hasCommit = $true
        & git -C $repoPath rev-parse --verify HEAD *> $null
        if ($LASTEXITCODE -ne 0) {
            $hasCommit = $false
        }

        $branchLine = (& git -C $repoPath branch --list $BranchName | Select-Object -First 1)
        $localBranch = ""
        if ($branchLine) {
            $localBranch = $branchLine.Trim()
        }

        if ([string]::IsNullOrWhiteSpace($localBranch)) {
            Invoke-Git $repoPath checkout -b $BranchName
        } else {
            Invoke-Git $repoPath checkout $BranchName
        }

        Invoke-Git $repoPath add .

        & git -C $repoPath diff --cached --quiet
        $hasStagedChanges = ($LASTEXITCODE -ne 0)

        if ($hasStagedChanges -or -not $hasCommit) {
            Invoke-Git $repoPath commit -m $CommitMessage
        }

        $commitHash = (& git -C $repoPath rev-parse --short HEAD | Select-Object -First 1).Trim()
        $result.Commit = $commitHash

        if ($SkipPush) {
            $result.Status = "Committed"
            $result.Detail = "Commit local listo para push"
        } else {
            Invoke-Git $repoPath push -u origin $BranchName
            $result.Status = "Pushed"
            $result.Detail = "Push completado"
        }
    } catch {
        $result.Status = "Failed"
        $result.Detail = $_.Exception.Message
    }

    $results.Add([PSCustomObject]$result)
}

$results | Format-Table -AutoSize
