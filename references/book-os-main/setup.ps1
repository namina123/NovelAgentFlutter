#Requires -Version 5.1

<#
.SYNOPSIS
    Novel-OS Setup Script for Windows (PowerShell)
    
.DESCRIPTION
    This script installs Novel-OS files to your system using PowerShell with enhanced 
    error handling, progress indicators, and verification capabilities.
    
.PARAMETER OverwriteInstructions
    Overwrite existing instruction files
    
.PARAMETER OverwriteStandards
    Overwrite existing standards files
    
.PARAMETER Verify
    Verify installation after completion
    
.PARAMETER Help
    Show this help message
    
.EXAMPLE
    .\setup.ps1
    
.EXAMPLE
    .\setup.ps1 -OverwriteStandards -Verify
    
.EXAMPLE
    .\setup.ps1 -OverwriteInstructions -OverwriteStandards
#>

param(
    [switch]$OverwriteInstructions,
    [switch]$OverwriteStandards,
    [switch]$Verify,
    [switch]$Help
)

# Show help if requested
if ($Help) {
    Get-Help $MyInvocation.MyCommand.Path -Full
    exit 0
}

# Set strict mode and error action
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Configuration
$BaseUrl = "https://raw.githubusercontent.com/forsonny/book-os/main"
$InstallPath = Join-Path $env:USERPROFILE ".novel-os"

# Enhanced logging function
function Write-StepLog {
    param(
        [string]$Message,
        [ValidateSet("Info", "Success", "Warning", "Error")]$Level = "Info"
    )
    
    $colors = @{
        "Info" = "White"
        "Success" = "Green" 
        "Warning" = "Yellow"
        "Error" = "Red"
    }
    
    $icons = @{
        "Info" = "[INFO]"
        "Success" = "[OK]"
        "Warning" = "[WARN]"
        "Error" = "[ERROR]"
    }
    
    Write-Host "$($icons[$Level]) $Message" -ForegroundColor $colors[$Level]
}

# Progress tracking
$script:totalSteps = 14
$script:currentStep = 0

function Update-Progress {
    param([string]$Activity)
    $script:currentStep++
    $percentComplete = ($script:currentStep / $script:totalSteps) * 100
    Write-Progress -Activity "Installing Novel-OS" -Status $Activity -PercentComplete $percentComplete
}

# Enhanced file download function
function Download-FileWithRetry {
    param(
        [string]$Url,
        [string]$OutputPath,
        [int]$MaxRetries = 3
    )
    
    for ($attempt = 1; $attempt -le $MaxRetries; $attempt++) {
        try {
            Invoke-WebRequest -Uri $Url -OutFile $OutputPath -UseBasicParsing
            return $true
        }
        catch {
            if ($attempt -eq $MaxRetries) {
                Write-StepLog "Failed to download $(Split-Path $OutputPath -Leaf) after $MaxRetries attempts: $($_.Exception.Message)" -Level "Error"
                return $false
            }
            Write-StepLog "Download attempt $attempt failed, retrying..." -Level "Warning"
            Start-Sleep -Seconds 2
        }
    }
}

# File processing function
function Install-NovelOSFile {
    param(
        [string]$RelativePath,
        [string]$Description,
        [bool]$OverwriteAllowed
    )
    
    $outputPath = Join-Path $InstallPath $RelativePath
    $url = "$BaseUrl/$RelativePath"
    
    if ((Test-Path $outputPath) -and -not $OverwriteAllowed) {
        Write-StepLog "$outputPath already exists - skipping" -Level "Warning"
        return $true
    }
    
    if (Download-FileWithRetry -Url $url -OutputPath $outputPath) {
        $status = if ((Test-Path $outputPath) -and $OverwriteAllowed) { " (overwritten)" } else { "" }
        Write-StepLog "$outputPath$status" -Level "Success"
        return $true
    }
    
    return $false
}

# Verification function
function Test-Installation {
    Write-StepLog "Verifying Novel-OS installation..." -Level "Info"
    
    $requiredPaths = @(
        "standards\writing-style.md",
        "standards\narrative-techniques.md", 
        "standards\writing-style\description-style.md",
        "standards\genre-guides\literary-fiction.md",
        "standards\genre-guides\mystery-thriller.md",
        "standards\genre-guides\fantasy-sci-fi.md",
        "instructions\core\plan-novel.md",
        "instructions\core\create-outline.md",
        "instructions\core\write-scenes.md",
        "instructions\core\write-scene.md",
        "instructions\core\analyze-manuscript.md",
        "instructions\meta\pre-flight.md"
    )
    
    $missingFiles = @()
    foreach ($path in $requiredPaths) {
        $fullPath = Join-Path $InstallPath $path
        if (-not (Test-Path $fullPath)) {
            $missingFiles += $path
        }
    }
    
    if ($missingFiles.Count -eq 0) {
        Write-StepLog "All files verified successfully!" -Level "Success"
        return $true
    } else {
        Write-StepLog "Missing files detected:" -Level "Error"
        foreach ($file in $missingFiles) {
            Write-StepLog "   Missing: $file" -Level "Error"
        }
        return $false
    }
}

# Main installation process
try {
    Write-Host "Novel-OS Setup Script for Windows (PowerShell)" -ForegroundColor Cyan
    Write-Host "=================================================" -ForegroundColor Cyan
    Write-Host ""

    # Check PowerShell version
    if ($PSVersionTable.PSVersion.Major -lt 5) {
        throw "PowerShell 5.1 or higher is required. Current version: $($PSVersionTable.PSVersion)"
    }

    # Create directory structure
    Update-Progress "Creating directory structure"
    Write-StepLog "Creating directories..." -Level "Info"
    
    $directories = @(
        "standards",
        "standards\writing-style", 
        "standards\genre-guides",
        "instructions",
        "instructions\core",
        "instructions\meta"
    )
    
    foreach ($dir in $directories) {
        $fullPath = Join-Path $InstallPath $dir
        if (-not (Test-Path $fullPath)) {
            New-Item -Path $fullPath -ItemType Directory -Force | Out-Null
        }
    }
    
    # Download standards files
    Write-Host ""
    Write-StepLog "Downloading writing standards files..." -Level "Info"
    
    Update-Progress "Downloading writing-style.md"
    Install-NovelOSFile "standards/writing-style.md" "writing style standards" $OverwriteStandards | Out-Null
    
    Update-Progress "Downloading narrative-techniques.md"
    Install-NovelOSFile "standards/narrative-techniques.md" "narrative techniques" $OverwriteStandards | Out-Null
    
    # Download writing-style subdirectory files
    Write-Host ""
    Write-StepLog "Downloading writing style files..." -Level "Info"
    
    Update-Progress "Downloading description-style.md"
    Install-NovelOSFile "standards/writing-style/description-style.md" "description style guide" $OverwriteStandards | Out-Null
    
    # Download genre guides
    Write-Host ""
    Write-StepLog "Downloading genre guide files..." -Level "Info"
    
    $genreGuides = @("literary-fiction", "mystery-thriller", "fantasy-sci-fi")
    foreach ($genre in $genreGuides) {
        Update-Progress "Downloading $genre.md"
        Install-NovelOSFile "standards/genre-guides/$genre.md" "$genre genre guide" $OverwriteStandards | Out-Null
    }
    
    # Download instruction files
    Write-Host ""
    Write-StepLog "Downloading instruction files..." -Level "Info"
    Write-StepLog "  Core instructions:" -Level "Info"
    
    $coreInstructions = @("plan-novel", "create-outline", "write-scenes", "write-scene", "analyze-manuscript")
    foreach ($instruction in $coreInstructions) {
        Update-Progress "Downloading $instruction.md"
        Install-NovelOSFile "instructions/core/$instruction.md" "$instruction instructions" $OverwriteInstructions | Out-Null
    }
    
    Write-Host ""
    Write-StepLog "  Meta instructions:" -Level "Info"
    
    Update-Progress "Downloading pre-flight.md"
    Install-NovelOSFile "instructions/meta/pre-flight.md" "pre-flight instructions" $OverwriteInstructions | Out-Null
    
    # Verification
    if ($Verify) {
        Write-Host ""
        Update-Progress "Verifying installation"
        Test-Installation | Out-Null
    }
    
    # Complete progress
    Write-Progress -Activity "Installing Novel-OS" -Completed
    
    # Success message
    Write-Host ""
    Write-StepLog "Novel-OS base installation complete!" -Level "Success"
    Write-Host ""
    Write-StepLog "Files installed to:" -Level "Info"
    Write-StepLog "   $InstallPath\standards\     - Your writing standards" -Level "Info"
    Write-StepLog "   $InstallPath\instructions\  - Novel-OS instructions" -Level "Info"
    Write-Host ""
    
    # Notes about preservation
    if (-not $OverwriteInstructions -and -not $OverwriteStandards) {
        Write-StepLog "Note: Existing files were skipped to preserve your customizations" -Level "Info"
        Write-StepLog "   Use -OverwriteInstructions or -OverwriteStandards to update specific files" -Level "Info"
    } else {
        Write-StepLog "Note: Some files were overwritten based on your parameters" -Level "Info"
        if (-not $OverwriteInstructions) {
            Write-StepLog "   Existing instruction files were preserved" -Level "Info"
        }
        if (-not $OverwriteStandards) {
            Write-StepLog "   Existing standards files were preserved" -Level "Info"
        }
    }
    
    Write-Host ""
    Write-StepLog "Next steps:" -Level "Info"
    Write-Host ""
    Write-StepLog "1. Customize your writing standards in $InstallPath\standards\" -Level "Info"
    Write-Host ""
    Write-StepLog "2. Install commands for your AI writing assistant(s):" -Level "Info"
    Write-Host ""
    Write-StepLog "   - Using Claude Code? Run the PowerShell setup:" -Level "Info"
    Write-StepLog "     .\setup-claude-code.ps1" -Level "Info"
    Write-Host ""
    Write-StepLog "   - Using Cursor? Run the PowerShell setup:" -Level "Info"
    Write-StepLog "     .\setup-cursor.ps1" -Level "Info"
    Write-Host ""
    Write-StepLog "   - Using something else? See instructions in the Novel-OS README" -Level "Info"
    Write-Host ""
    Write-StepLog "Learn more about Novel-OS for AI-assisted novel writing!" -Level "Success"
    Write-Host ""
}
catch {
    Write-Progress -Activity "Installing Novel-OS" -Completed
    Write-StepLog "Installation failed: $($_.Exception.Message)" -Level "Error"
    Write-StepLog "Please check your internet connection and try again." -Level "Info"
    exit 1
}