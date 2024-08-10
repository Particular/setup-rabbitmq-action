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
$resourceGroup = $Env:RESOURCE_GROUP_OVERRIDE ?? "GitHubActions-RG"
$ipAddress = "127.0.0.1"

if ($runnerOs -eq "Linux") {
    Write-Output "Running Rabbit in container $($containerName) using Docker"

    docker run --name "$($hostname)" -d -p "5672:5672" -p "15672:15672" $dockerImage
}
elseif ($runnerOs -eq "Windows") {

    if ($Env:REGION_OVERRIDE) {
        $region = $Env:REGION_OVERRIDE
    }
    else {
        $hostInfo = curl -H Metadata:true "169.254.169.254/metadata/instance?api-version=2017-08-01" | ConvertFrom-Json
        $region = $hostInfo.compute.location
    }

    $runnerOsTag = "RunnerOS=$($Env:RUNNER_OS)"
    $packageTag = "Package=$tagName"
    $dateTag = "Created=$(Get-Date -Format "yyyy-MM-dd")"

    $azureContainerCreate = "az container create --image $dockerImage --name $hostname --location $region --dns-name-label $hostname --resource-group $resourceGroup --cpu 4 --memory 16 --ports 5672 15672 --ip-address public"

    if ($registryUser -and $registryPass) {
        Write-Output "Creating container with login to $registryLoginServer"
        $azureContainerCreate =  "$azureContainerCreate --registry-login-server $registryLoginServer --registry-username $registryUser --registry-password $registryPass"
    } else {
        Write-Output "Creating container with anonymous credentials"
    }

    Write-Output "Creating RabbitMQ container $hostname in $region (This can take a while.)"

    $jsonResult = Invoke-Expression $azureContainerCreate
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

    $ipAddress=$details.ipAddress.ip

    Write-Output "::add-mask::$ipAddress"
    Write-Output "Tagging container image"
    az tag create --resource-id $details.id --tags $packageTag $runnerOsTag $dateTag | Out-Null

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