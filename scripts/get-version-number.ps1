param(
    [string]$VcsNumber,
    [string]$Environment,
    [string]$BuildCounter
)

Write-Host "Starting Get Version Number script..."

$envName = $environment

Write-Host "Environment detected: $envName"

if ($envName -eq "Production") {
    # Get version from git tag
    $tag = git describe --tags $VcsNumber
    Write-Host "Using Detected Git Tag: $tag"

    # Set TeamCity parameter
    Write-Host "##teamcity[setParameter name='BUILD_VERSION_NUMBER' value='$tag']"
}
elseif ($envName -eq "Stage") {
    # Use TeamCity's build number
    $buildNumber = "$BuildCounter-build-number"
    Write-Host "Using TeamCity Build Number: $buildNumber"

    # Set TeamCity parameter
    Write-Host "##teamcity[setParameter name='BUILD_VERSION_NUMBER' value='$buildNumber']"
}
else {
    Write-Host "ERROR: Unknown BUILD_ENVIRONMENT value: $envName"

    $messageEnvWrongName = "Wrong Environment Name"
    Write-Host "##teamcity[buildStatus text='$messageEnvWrongName']"
    Write-Host "##teamcity[buildProblem description='$messageEnvWrongName']"

    exit 1
}