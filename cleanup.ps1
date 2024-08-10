param (
    [string]$RabbitMQName
)

$resourceGroup = $Env:RESOURCE_GROUP_OVERRIDE ?? "GitHubActions-RG"
$runnerOs = $Env:RUNNER_OS ?? "Linux"

if ($runnerOs -eq "Linux") {
    Write-Output "Killing Docker container $RabbitMQName"
    docker kill $RabbitMQName

    Write-Output "Removing Docker container $RabbitMQName"
    docker rm $RabbitMQName
}
elseif ($runnerOs -eq "Windows") {
    Write-Output "Deleting Azure container $RabbitMQName"
    az container delete --resource-group $resourceGroup --name $RabbitMQName --yes | Out-Null
}
else {
    Write-Output "$runnerOs not supported"
    exit 1
}