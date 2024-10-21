param (
    [switch]$ResetToSource = $false
)
# Set exit on error
$ErrorActionPreference = 'Stop'; $DebugPreference = 'Continue'

############## SRCRIPT VARIABLES #################
# Remove all files and folders in the current directory except the scripts folder and its contents
$RESET_EXCLUSIONS = @('scripts', 'README.md')
$TEMPLATE_URL = 'https://github.com/onwidget/astrowind/archive/refs/heads/main.zip'
$SUBMODULES = @{
    'astro'     = 'https://github.com/withastro/astro.git'
    'astrowind' = 'https://github.com/onwidget/astrowind.git'
}
$PROJECT_PATH = $MyInvocation.MyCommand.Path | Split-Path -Parent | Split-Path -Parent
Write-Debug "PROJECT_PATH: $PROJECT_PATH"
$RUN_TIMESTAMP = Get-Date -Format 'yyyyMMddHHmmss'
###################################################


####################### RESET ######################
function Reset-ProjectToSource {
    # Warn user and get confirmation
    $confirmation = Read-Host 'This will remove all files and folders in the current directory except the scripts folder and its contents. Are you sure you want to continue? (y/n)'
    if ($confirmation -ne 'y') {
        Write-Output 'Aborted...'
        exit
    }
    else {
        Write-Output 'Removing all files and folders in the current directory except: '
        $RESET_EXCLUSIONS | ForEach-Object { Write-Output " - $_" }
        # Get another confirmation
        $confirmation = Read-Host 'Are you sure you want to continue? (y/n)'
        if ($confirmation -ne 'y') {
            Write-Output 'Aborted...'
            exit
        }
        else {
            # Get all files and folders in the current directory
            $items = Get-ChildItem -Path '.\' -Force
            # Remove all files and folders except the exclusions
            $items | Where-Object { $_.Name -notin $RESET_EXCLUSIONS } | ForEach-Object {
                if ($_.PSIsContainer) {
                    Write-Output "Removing folder: $($_.FullName)"
                    Remove-Item -Path $_.FullName -Recurse -Force
                }
                else {
                    Write-Output "Removing file: $($_.FullName)"
                    Remove-Item -Path $_.FullName -Force
                }
            }
            Write-Output 'All files and folders removed.'
        }
    }
}
###################################################

################## GIT REPO SETUP ##################

function Initialize-SubModules {
    if (Initialize-GitRepo) {
        # Ensure .gitmodules file does n=not exist
        Write-Debug "Initializing submodules...in $PWD"
        try {
            foreach ($Name in $SUBMODULES.Keys) {
                Write-Debug "Initializing submodule: $Name"
                $URL = $SUBMODULES[$Name]
                Write-Debug "git submodule add $URL $Name"
                & git submodule add $URL $Name
            }
            Write-Debug 'Submodules initialized.'
        }
        catch {
            Write-Warning 'Failed to add Astro submodule.'
            Write-Debug 'This can often occur due to MS Defender blocking'
            Write-Debug 'You may consider something like (in admin prived PS): '
            Write-Debug 'Get-ChildItem -Recurse -Path ((Get-Command -Name git).Source | Split-Path) | ForEach-Object -Process { Write-Debug "Stopping ASLR for: $($_.Name)"; Set-ProcessMitigation -Name $_.Name -Disable ForceRelocateImages }'
            Write-Debug 'Then try running the script again.'
            Write-Debug 'And to re-enable ASLR, you can run (in admin prived PS): '
            Write-Debug 'Get-ChildItem -Recurse -Path ((Get-Command -Name git).Source | Split-Path) | ForEach-Object -Process { Write-Debug "Enabling ASLR for: $($_.Name)"; Set-ProcessMitigation -Name $_.Name -Enable ForceRelocateImages }'
            Write-Error 'Failed to add Astro submodule.'
            # exit with error
            return $false
        }
    }
    else {
        Write-Error 'Git repository not initialized - check the error above.'
        return $false
    }
    return $true
}

function Initialize-GitRepo {
    # Check if the current directory is a git repository
    if (-not (Test-Path -Path '.\.git')) {
        Write-Debug 'Initializing git repository...'
        git init
        git add -A
        git commit -m 'Initial commit'
        Write-Debug 'Git repository initialized, add remote with: '
        Write-Debug '   git remote add origin <url>'
    }
    else {
        Write-Debug 'Git repository already exists.'
        try {
            # Write any out to null (except errors)
            git remote -v > $null
        }
        catch {
            Write-Debug 'git remote -v failed.'
            Write-Warning "Git failed with error: $_.Exception.Message"
            Write-Warning 'You should reinitialize the git repository after this script completes.'
        }
    }
    return $true
}

###################################################


################# INITIALIZE SITE #################
function Initialize-Website {
    # Get path of script
    Set-Location -Path "$PROJECT_PATH"
    # Write current full path to user
    Write-Debug "Current directory: $PWD"
    Write-Debug "Path of script: $PROJECT_PATH\scripts\Install-AstroDependencies.ps1"
    Write-Debug 'assuming your site project root is: '
    Write-Debug "$PWD"
    # As user to confirm they are running the script from the correct location
    $confirmation = Read-Host 'Confirm the above is your site project root? (y/n)'
    if ($confirmation -ne 'y') {
        Write-Debug 'Ok - run again once you are ready :)'
        exit
    }
    # in some scenarios: npm cache clean
    # Update npm
    Write-Debug 'Updating npm...'
    npm install -g npm
    Write-Debug 'npm updated.'
    Write-Debug '##############################################'
    Write-Debug 'Downloading AstroWind template from GitHub...(not cloning or fetching)'
    Write-Debug "Template URL: $TEMPLATE_URL"
    try {
        Invoke-WebRequest -Uri $TEMPLATE_URL -OutFile "astrowind_$RUN_TIMESTAMP.zip"
    }
    catch {
        Write-Debug "Failed to download AstroWind template from: $TEMPLATE_URL"
        Write-Debug "Check the Repo at: $($($TEMPLATE_URL -split '/archive')[0])"
        Write-Debug 'Please check your internet connection and try again.'
        exit
    }
    Write-Debug 'AstroWind template downloaded... Extracting...'
    Expand-Archive -Path "astrowind_$RUN_TIMESTAMP.zip" -DestinationPath '.\'
    # Move the extracted template to the current directory, include all files and folders even if empty or hidden
    Move-Item -Path '.\astrowind-main\*' -Destination '.\' -Verbose -Exclude $RESET_EXCLUSIONS
    Move-Item -Path '.\astrowind-main\README.md' -Destination '.\ASTROWIND_README.md' -Verbose
    # Confirm the template dir is now empty
    if ((Get-ChildItem -Path '.\astrowind-main\').Count -eq 0) {
        Write-Debug "astrowind_$RUN_TIMESTAMP.zip template extracted to $PWD"
    }
    else {
        Get-ChildItem -Path '.\astrowind-main\' -Recurse | ForEach-Object { Write-Debug $_.FullName }
        Write-Debug 'There are still files in the extracted template directory. Something went wrong.'
        Write-Error 'Failed to extract the AstroWind template.'
        exit
    }
    Remove-Item -Path '.\astrowind-main' -Recurse -Force
    Write-Debug '##############################################'
    Write-Debug 'Installing dependencies... with npm install'
    try {
        npm install
    }
    catch {
        Write-Debug 'npm install Failed with error:'
        Write-Debug $_.Exception.Message
        Write-Error 'npm install failed.'
    }
    finally {
        Remove-Item -Path "astrowind_$RUN_TIMESTAMP.zip" -Force
    }
    Write-Debug 'npm install completed.'
    Write-Debug '##############################################'
    return $true
}
###################################################

################# DISPLAY MESSAGE #################
function Show-SuccessMessage {
    Write-Output ''; Write-Output ''
    Write-Output '##############################################'
    Write-Output ''; Write-Output ''
    Write-Output 'Astro looks for .astro or .md files in the src/pages/ directory. Each page is exposed as a route based on its file name.'
    Write-Output "There's nothing special about src/components/, but that's where we like to put any Astro/React/Vue/Svelte/Preact components."
    Write-Output 'Any static assets, like images, can be placed in the public/ directory if they do not require any transformation or in the assets/ directory if they are imported directly.'
    Write-Output ''; Write-Output ''
    Write-Output '##############################################'
    Write-Output 'Astro has a few commands to help you build and run your site:'
    Write-Output "'npm install': Install dependencies for your site."
    Write-Output "'npm run dev': Start a development server for your site."
    Write-Output "'npm run build': Build your site for production to the .\dist\ directory."
    Write-Output "'npm run preview': Serve your site locally after building it."
    Write-Output "'npm run check': Run type-checking on your project."
    Write-Output "'npm run lint': Run linting on your project."
    Write-Output "'npm run astro ...': Run any Astro command. For example, 'npm run astro add node'."
    Write-Output ''; Write-Output ''
    Write-Output '##############################################'
        
    Write-Output '##############################################'
    Write-Output 'Astro has been installed and the submodules have been added.'
    Write-Output 'To start a dev instance of your site, run: '
    Write-Output ''
    Write-Output '##############################################'
    Write-Output 'npm run dev'
    Write-Output '##############################################'
}
###################################################


################### MAIN SCRIPT ###################
if ($ResetToSource) {
    Reset-ProjectToSource
    Write-Output 'Project reset, try running the script again to install Astro.'
    Write-Output '##############################################'
    return $True
}
if (Initialize-Website) {
    Write-Output 'Astro and template installed.'
    if (Initialize-GitRepo) {
        Write-Output "Git repo in $PWD repository initialized."
        $confirmation = Read-Host 'Would you like to add the submodules? [this is recommended] (y/n)'
        if ($confirmation -eq 'y') {
            if (Initialize-SubModules) {
                Write-Output 'Astro submodules added.'
            }
        }
    }
    Show-SuccessMessage
}
    
####################### END #######################