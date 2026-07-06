# Open SSH tunnel to Vast.ai Signal World (fill in your instance details)
param(
    [Parameter(Mandatory = $true)]
    [string]$SshHost,

    [Parameter(Mandatory = $true)]
    [int]$SshPort
)

$cmd = "ssh -p $SshPort root@$SshHost -L 5099:localhost:5099 -L 8888:localhost:8888 -L 11434:localhost:11434"
Write-Host $cmd -ForegroundColor Cyan
Start-Process powershell -ArgumentList "-NoExit", "-Command", $cmd
Start-Sleep -Seconds 3
Start-Process "http://127.0.0.1:5099/"