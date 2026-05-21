param(
    [string]$VcsRoot
)

$allowedBranch = $VcsRoot
$messageWrongFormat = "Invalid Tag Format"

# Parse Tag_Build_Map into a hashtable
# Format: "API=YourProject_APIBuild;Service=YourProject_ServiceBuild;WEB=YourProject_WebBuild"
$BUILD_MAP = @{}
$env:Tag_Build_Map.Split(';') | ForEach-Object {
    $PAIR = $_.Split('=')
    $BUILD_MAP[$PAIR[0].Trim()] = $PAIR[1].Trim()
}

# --- Tag Validation ---
$TAG = $env:TAG_NAME  # e.g. "1.0.9-API"

# Rule: tag must start with digits (three dot-separated numeric sections)
if ($TAG -notmatch '^\d+\.\d+\.\d+') {
    Write-Error "Invalid tag '$TAG': must start with a version number in the format X.Y.Z (e.g. 1.0.9)."    
    Write-Host "##teamcity[buildStatus text='$messageWrongFormat']"
    Write-Host "##teamcity[buildProblem description='$messageWrongFormat']"
    exit 1
}

# Rule: a divider '-' must be present (rejects plain "1.0.9" or "1.0.9-")
if ($TAG -notmatch '^\d+\.\d+\.\d+-\S+$') {
    Write-Error "Invalid tag '$TAG': must contain a '-' divider followed by a non-empty suffix (e.g. 1.0.9-API)."
    Write-Host "##teamcity[buildStatus text='$messageWrongFormat']"
    Write-Host "##teamcity[buildProblem description='$messageWrongFormat']"
    exit 1
}

# Split into version and suffix
$PARTS   = $TAG -split '-', 2
$VERSION = $PARTS[0]   # "1.0.9"
$SUFFIX  = $PARTS[1]   # "API"

# Rule: version part must be strictly X.Y.Z with only digits in each section
if ($VERSION -notmatch '^\d+\.\d+\.\d+$') {
    Write-Error "Invalid tag '$TAG': version part '$VERSION' must be exactly X.Y.Z with numeric sections only."
    Write-Host "##teamcity[buildStatus text='$messageWrongFormat']"
    Write-Host "##teamcity[buildProblem description='$messageWrongFormat']"
    exit 1
}

# Rule: suffix must be one of the keys defined in Tag_Build_Map
if (-not $BUILD_MAP.ContainsKey($SUFFIX)) {
    $VALID_SUFFIXES = $BUILD_MAP.Keys -join ', '
    Write-Error "Invalid tag '$TAG': suffix '$SUFFIX' is not recognized. Accepted suffixes: $VALID_SUFFIXES."
    Write-Host "##teamcity[buildStatus text='$messageWrongFormat']"
    Write-Host "##teamcity[buildProblem description='$messageWrongFormat']"
    exit 1
}

Write-Host "Tag Format ($TAG) is valid. Version: $VERSION | Suffix: $SUFFIX | Build config: $($BUILD_MAP[$SUFFIX])"

# --- BRANCH VALIDATION ---
Write-Host "Validating tag against checked out branch..."

# Resolve commit hash for the tag
$tagCommit = git rev-parse $tag 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Tag '$tag' not found in repository"

    $messageTagNotFound = "Tag Not Found"
    Write-Host "##teamcity[buildStatus text='$messageTagNotFound']"
    Write-Host "##teamcity[buildProblem description='$messageTagNotFound']"

    exit 1
}

Write-Host "Tag commit hash: $tagCommit"
Write-Host "Checking if tag commit exists in '$allowedBranch' history..."

$isInBranch = git merge-base --is-ancestor $tagCommit $allowedBranch 2>$null
if ($LASTEXITCODE -eq 0) {
    Write-Host "OK: Tag '$tag' commit is in '$allowedBranch' branch history."
    exit 0
} else {
    Write-Host "ERROR: Tag '$tag' commit is NOT in '$allowedBranch' branch history"
    Write-Host "Tag commit: $tagCommit"
    Write-Host "Branch HEAD: $branchCommit"
    Write-Host "Please create Production tags only from commits in '$allowedBranch' branch."

    $messageWrongBranch = "Tag on a Wrong Branch"
    Write-Host "##teamcity[buildStatus text='$messageWrongBranch']"
    Write-Host "##teamcity[buildProblem description='$messageWrongBranch']"

    exit 1
}