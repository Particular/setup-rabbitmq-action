param (
    [string]$RabbitMQName
)

$ignore = az container delete --resource-group GitHubActions-RG --name $RabbitMQName --yes