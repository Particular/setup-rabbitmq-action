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

$hostInfo = curl -H Metadata:true "169.254.169.254/metadata/instance?api-version=2017-08-01" | ConvertFrom-Json
$region = $hostInfo.compute.location
$runnerOsTag = "RunnerOS=$($Env:RUNNER_OS)"
$packageTag = "Package=$tagName"

echo "hostname=$hostname" | Out-File -FilePath $Env:GITHUB_OUTPUT -Encoding utf-8 -Append
echo "Creating RabbitMQ container $hostname in $region (This can take a while.)"

$jsonResult = $null

if ($registryUser -and $registryPass) {
    echo "Creating container with login to $registryLoginServer"
    $jsonResult = az container create --image rabbitmq:$imageTag --name $hostname --location $region --dns-name-label $hostname --resource-group GitHubActions-RG --cpu 4 --memory 16 --ports 5672 15672 --ip-address public --registry-login-server $registryLoginServer --registry-username $registryUser --registry-password $registryPass
} else {
    echo "Creating container with anonymous credentials"
    $jsonResult = az container create --image rabbitmq:$imageTag --name $hostname --location $region --dns-name-label $hostname --resource-group GitHubActions-RG --cpu 4 --memory 16 --ports 5672 15672 --ip-address public
}

if (!$jsonResult) {
    Write-Output "Failed to create RabbitMQ container"
    exit 1;
}

$details = $jsonResult | ConvertFrom-Json

if (!$details.ipAddress) {
    Write-Output "Failed to create RabbitMQ container $hostname in $region"
    Write-Output $jsonResult
    exit 1;
}

$ip=$details.ipAddress.ip

echo "::add-mask::$ip"
echo "Tagging container image"

$dateTag = "Created=$(Get-Date -Format "yyyy-MM-dd")"
$ignore = az tag create --resource-id $details.id --tags $packageTag $runnerOsTag $dateTag

echo "$connectionStringName=host=$ip" | Out-File -FilePath $Env:GITHUB_ENV -Encoding utf-8 -Append
if (-not [string]::IsNullOrWhiteSpace($hostEnvVarName)) {
    echo "$hostEnvVarName=$ip" | Out-File -FilePath $Env:GITHUB_ENV -Encoding utf-8 -Append
}

$uri = "http://" + $ip + ":15672/api/health/checks/virtual-hosts"
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