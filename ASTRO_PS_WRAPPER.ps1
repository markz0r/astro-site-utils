param (
    [switch]$npminstall = $false,
    [switch]$npmupdate = $false,
    [switch]$rundev = $false,
    [switch]$test = $false,
    [switch]$build = $false,
    [switch]$deploySite = $false,
    [switch]$deployAWSCloudFormation = $false,
    [switch]$post = $false,
    [switch]$push = $false,
    [switch]$pull = $false
)

$ErrorActionPreference = 'Stop'; $DebugPreference = 'Continue'

$PROJECT_PATH = $MyInvocation.MyCommand.Path | Split-Path -Parent
Set-Location $PROJECT_PATH
Write-Debug "PROJECT_PATH: $PROJECT_PATH, current location: $PWD"


if ($npminstall) {
    Write-Output 'Running npm install...'
    npm install
    Write-Output 'npm packages installed.'
}

if ($npmupdate) {
    Write-Output 'Running npm update...'
    npm update
    Write-Output 'npm packages updated.'
}

if ($rundev) {
    Write-Output 'Running npm run dev...'
    npm run dev
}

if ($test) {
    Write-Output 'Running npm test...'
    npm run check
}

if ($build) {
    Write-Output 'Running npm build...'
    npm run build
}

if ($deploySite) {
    Write-Output 'Running npm deploy...'
    npm run deploy
}

if ($post) {
    Write-Output 'Running npm post...'
    npm run post
}

if ($push) {
    Write-Output 'Running git push...'
    git push
}

if ($pull) {
    Write-Output 'Running git pull...'
    git pull
}
