$TAG = $env:TAG_NAME
$SUFFIX = $TAG.Split('-')[-1]

Write-Host "Tag received: $TAG"
Write-Host "Routing to: $SUFFIX"

$TC_URL = $env:Tag_URL
$TC_USER = $env:Tag_USER
$TC_PASSWORD = $env:Tag_PASSWORD
$BRANCH = $TAG

# Build Basic Auth header
$CREDENTIALS = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${TC_USER}:${TC_PASSWORD}"))
$HEADERS = @{
    "Authorization" = "Basic $CREDENTIALS"
    "Content-Type"  = "application/xml"
}

function Trigger-Build {
    param([string]$BuildConfigId)

    $BODY = "<build branchName=`"$BRANCH`"><buildType id=`"$BuildConfigId`"/></build>"

    try {
        $RESPONSE = Invoke-RestMethod `
            -Uri "$TC_URL/app/rest/buildQueue" `
            -Method POST `
            -Headers $HEADERS `
            -Body $BODY

        Write-Host "Triggered: $BuildConfigId (build id: $($RESPONSE.id))"
    }
    catch {
        Write-Error "Failed to trigger ${BuildConfigId}: $($_.Exception.Message)"
        exit 1
    }
}

# Parse env.TAG_BUILD_MAP into a hashtable
# Format: "API=YourProject_APIBuild;Service=YourProject_ServiceBuild;WEB=YourProject_WebBuild"
$BUILD_MAP = @{}
$env:Tag_Build_Map.Split(';') | ForEach-Object {
    $PAIR = $_.Split('=')
    $BUILD_MAP[$PAIR[0].Trim()] = $PAIR[1].Trim()
}

# Look up suffix in the map and trigger
if ($BUILD_MAP.ContainsKey($SUFFIX)) {
    Trigger-Build $BUILD_MAP[$SUFFIX]
} else {
    Write-Error "Unknown tag suffix: '$SUFFIX' - not found in TAG_BUILD_MAP. No build triggered."
    Write-Host "Available suffixes: $($BUILD_MAP.Keys -join ', ')"
    exit 1
}