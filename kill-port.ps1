param(
    [Parameter(Mandatory = $true)]
    [int]$Port
)

$connections = Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue |
    Select-Object -ExpandProperty OwningProcess -Unique

if (-not $connections) {
    Write-Host "No hay procesos escuchando en el puerto $Port."
    exit 0
}

foreach ($pid in $connections) {
    try {
        $process = Get-Process -Id $pid -ErrorAction Stop
        Write-Host "Deteniendo PID $pid ($($process.ProcessName)) en puerto $Port..."
        Stop-Process -Id $pid -Force -ErrorAction Stop
    }
    catch {
        Write-Host "No se pudo detener el PID ${pid}: $($_.Exception.Message)"
    }
}

Write-Host "Limpieza del puerto $Port completada."
