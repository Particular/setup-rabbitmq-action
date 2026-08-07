param (
    [string]$hostname,
    [string]$connectionStringName,
    [string]$tagName,
    [string]$hostEnvVarName,
    [string]$imageTag,
    [string]$registryLoginServer,
    [string]$registryUser,
    [string]$registryPass
)

$dockerImage = "rabbitmq:$imageTag"
$runnerOs = $Env:RUNNER_OS ?? "Linux"
$ipAddress = "127.0.0.1"

if (-not $Env:WSL_TOOLS_MODULE_PATH) {
    throw "This action requires Particular/setup-wsl-action to run first — it provisions WSL/Docker and exports the WslTools module at WSL_TOOLS_MODULE_PATH."
}
Import-Module $Env:WSL_TOOLS_MODULE_PATH -Force

if ($runnerOs -eq "Linux") {
    Write-Output "Running Rabbit in container $($hostname) using Docker"

    docker run --name "$($hostname)" -d -p "5672:5672" -p "15672:15672" $dockerImage
}
elseif ($runnerOs -eq "Windows") {
    Write-Output "Running Rabbit in container $($hostname) using WSL"

    $wslDistribution = $Env:WSL_DISTRIBUTION
    $ipAddress = $Env:WSL_IP

    if (-not $ipAddress) {
        throw "WSL_IP is not set. Run Particular/setup-wsl-action before this action."
    }
    Write-Output "WSL address: $ipAddress"

    if ($registryUser -and $registryPass) {
        Write-Output "::add-mask::$registryPass"
        Write-Output "Logging in to $registryLoginServer inside WSL"
        $loginCommand = "docker login --username '$registryUser' --password-stdin '$registryLoginServer'"
        $registryPass | wsl.exe --distribution $wslDistribution --user root -- bash -c $loginCommand
        if ($LASTEXITCODE -ne 0) {
            throw "Docker registry login inside WSL failed with exit code $LASTEXITCODE"
        }
    }
    else {
        Write-Output "Using anonymous credentials"
    }

    Write-Output "::group::Starting RabbitMQ container"
    Invoke-Wsl -Distribution $wslDistribution -CheckExitCode -Command "docker run --name $hostname --detach --restart unless-stopped --publish 5672:5672 --publish 15672:15672 $dockerImage"
    Invoke-Wsl -Distribution $wslDistribution -Command "docker ps --filter name=$hostname"
    Write-Output "::endgroup::"
}
else {
    Write-Output "$runnerOs not supported"
    exit 1
}

Write-Output "hostname=$hostname" | Out-File -FilePath $Env:GITHUB_OUTPUT -Encoding utf-8 -Append
Write-Output "$connectionStringName=host=$ipAddress" | Out-File -FilePath $Env:GITHUB_ENV -Encoding utf-8 -Append
if (-not [string]::IsNullOrWhiteSpace($hostEnvVarName)) {
    Write-Output "$hostEnvVarName=$ipAddress" | Out-File -FilePath $Env:GITHUB_ENV -Encoding utf-8 -Append
}

Write-Output "::group::Testing connection"

$uri = "http://" + $ipAddress + ":15672/api/health/checks/virtual-hosts"
$tries = 0

do {
    $response = curl $uri -u guest:guest | ConvertFrom-Json
    $tries++
    if (!$response.status) {
        Write-Output "No response, retrying..."
        Start-Sleep -m 5000
    }
} until (($response.status) -or ($tries -ge 50))

if ($response.status -ne "ok") {
    Write-Output "Failed to connect after 50 attempts";
    exit 1
}
Write-Output "::endgroup::"
