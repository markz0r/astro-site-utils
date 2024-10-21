$PROJECT_PATH = $MyInvocation.MyCommand.Path | Split-Path -Parent | Split-Path -Parent
Write-Debug "PROJECT_PATH: $PROJECT_PATH"
Set-Location $PROJECT_PATH
git pull --recurse-submodules