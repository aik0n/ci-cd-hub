param(
    [string]$VcsNumber,
    [ValidateSet("Production", "Stage")]
    [string]$Environment,
    [string]$BuildCounter
)

Write-Host "Starting Get Version Number script..."

# Only for cases triggered by Dispatcher
if ($env:TAG_EXTERNAL) {
    Write-Host "TAG_EXTERNAL is: ['$env:TAG_EXTERNAL'], using it as the version number."
    Write-Host "##teamcity[setParameter name='BUILD_VERSION_NUMBER' value='$env:TAG_EXTERNAL']"
    exit 0
}
# Only for cases triggered by Dispatcher

if (-not $Environment) {
    $messageEnvironmentMissed = "ERROR: -Environment parameter is required"
    Write-Host $messageEnvironmentMissed
    Write-Host "##teamcity[buildStatus text='$messageEnvironmentMissed']"
    Write-Host "##teamcity[buildProblem description='$messageEnvironmentMissed']"
    exit 1
}

if (-not $VcsNumber) {
    $messageVcsMissed = "ERROR: -VcsNumber parameter is required"
    Write-Host $messageVcsMissed
    Write-Host "##teamcity[buildStatus text='$messageVcsMissed']"
    Write-Host "##teamcity[buildProblem description='$messageVcsMissed']"
    exit 1
}

if (-not $BuildCounter) {
    $messageBuildCounterMissed = "ERROR: -BuildCounter parameter is required"
    Write-Host $messageBuildCounterMissed
    Write-Host "##teamcity[buildStatus text='$messageBuildCounterMissed']"
    Write-Host "##teamcity[buildProblem description='$messageBuildCounterMissed']"
    exit 1
}

Write-Host "Environment detected: $Environment"

if ($Environment -eq "Production") {
    $tag = git describe --tags $VcsNumber
    
    # Ensure git describe succeeded before proceeding
    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERROR: git describe failed for ref: $VcsNumber"
        exit 1
    }

    Write-Host "Using Detected Git Tag: $tag"
    Write-Host "##teamcity[setParameter name='BUILD_VERSION_NUMBER' value='$tag']"
    exit 0
}

if ($Environment -eq "Stage") {
    $buildNumber = "$BuildCounter-build-number"
    Write-Host "Using TeamCity Build Number: $buildNumber"
    Write-Host "##teamcity[setParameter name='BUILD_VERSION_NUMBER' value='$buildNumber']"
    exit 0
}