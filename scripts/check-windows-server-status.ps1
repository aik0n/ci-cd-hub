$serviceName  = $OctopusParameters['servicenamewin']
$desiredState = $OctopusParameters['servicewinstatus']

if ([string]::IsNullOrWhiteSpace($serviceName)) {
    Write-Error "Octopus variable 'servicenamewin' is not defined"
    exit 1
}

if ([string]::IsNullOrWhiteSpace($desiredState)) {
    Write-Error "Octopus variable 'servicewinstatus' is not defined"
    exit 1
}

$service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue

if ($null -eq $service) {
    Write-Error "Service '$serviceName' was not found."
    exit 1
}

if ($service.Status -ne $desiredState) {
    Write-Error "The service $serviceName is NOT $desiredState. Current status: $($service.Status)"
    exit 1
}

Write-Host "The service $serviceName is $desiredState."
exit 0