$ErrorActionPreference = "Stop"

$backendRoot = Split-Path -Parent $PSScriptRoot
$repos = @(
    "microservicios-futfem-competitions",
    "microservicios-futfem-competitions-temp",
    "microservicios-futfem-players",
    "microservicios-futfem-players-temp",
    "microservicios-futfem-referees",
    "microservicios-futfem-referees-temp",
    "microservicios-futfem-squads",
    "microservicios-futfem-squads-temp",
    "microservicios-futfem-teams",
    "microservicios-futfem-teams-temp",
    "scripts"
)

foreach ($repo in $repos) {
    $repoPath = Join-Path $backendRoot $repo

    if (-not (Test-Path -LiteralPath $repoPath)) {
        throw "No existe el repositorio: $repoPath"
    }

    Write-Host ""
    Write-Host "==> Push de $repo" -ForegroundColor Cyan
    git -C $repoPath push origin HEAD

    if ($LASTEXITCODE -ne 0) {
        throw "Fallo el push en $repo"
    }
}

Write-Host ""
Write-Host "Push multiple completado." -ForegroundColor Green
