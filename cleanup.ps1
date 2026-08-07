param (
    [string]$RabbitMQName
)

$runnerOs = $Env:RUNNER_OS ?? "Linux"

if (-not $Env:WSL_TOOLS_MODULE_PATH) {
    throw "This action requires Particular/setup-wsl-action to run first — it provisions WSL/Docker and exports the WslTools module at WSL_TOOLS_MODULE_PATH."
}
Import-Module $Env:WSL_TOOLS_MODULE_PATH -Force

if ($runnerOs -eq "Linux") {
    Write-Output "Killing Docker container $RabbitMQName"
    docker kill $RabbitMQName

    Write-Output "Removing Docker container $RabbitMQName"
    docker rm $RabbitMQName
}
elseif ($runnerOs -eq "Windows") {
    Write-Output "Removing WSL Docker container $RabbitMQName"
    Invoke-Wsl -Command "docker rm --force ${RabbitMQName} 2>/dev/null || true"
}
else {
    Write-Output "$runnerOs not supported"
    exit 1
}
