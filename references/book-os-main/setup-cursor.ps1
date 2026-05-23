#Requires -Version 5.1

<#
.SYNOPSIS
    Novel-OS Cursor Setup Script for Windows (PowerShell)
    
.DESCRIPTION
    This script installs Novel-OS commands for Cursor in the current project with enhanced 
    error handling, progress indicators, and verification capabilities.
    
.PARAMETER Verify
    Verify installation after completion
    
.PARAMETER Help
    Show this help message
    
.EXAMPLE
    .\setup-cursor.ps1
    
.EXAMPLE
    .\setup-cursor.ps1 -Verify
#>

param(
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
$NovelOSPath = Join-Path $env:USERPROFILE ".novel-os"
$CursorRulesPath = ".cursor\rules"

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
$script:totalSteps = 8
$script:currentStep = 0

function Update-Progress {
    param([string]$Activity)
    $script:currentStep++
    $percentComplete = ($script:currentStep / $script:totalSteps) * 100
    Write-Progress -Activity "Installing Novel-OS for Cursor" -Status $Activity -PercentComplete $percentComplete
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

# Process command file function
function Install-CursorCommandFile {
    param(
        [string]$CommandName
    )
    
    $tempFile = Join-Path $env:TEMP "$CommandName.md"
    $targetFile = Join-Path $CursorRulesPath "$CommandName.mdc"
    $url = "$BaseUrl/commands/$CommandName.md"
    
    # Download the file
    if (Download-FileWithRetry -Url $url -OutputPath $tempFile) {
        # Create the front-matter and append original content
        $frontMatter = @"
---
alwaysApply: false
---

"@
        
        # Combine front matter with original content
        $originalContent = Get-Content $tempFile -Raw
        $finalContent = $frontMatter + $originalContent
        
        # Write to target file
        Set-Content -Path $targetFile -Value $finalContent -Encoding UTF8
        
        # Clean up temp file
        Remove-Item $tempFile -Force
        
        Write-StepLog "$targetFile" -Level "Success"
        return $true
    } else {
        Write-StepLog "Failed to download $CommandName.md" -Level "Error"
        return $false
    }
}

# Verification function
function Test-CursorInstallation {
    Write-StepLog "Verifying Cursor installation..." -Level "Info"
    
    $commands = @("plan-novel", "create-outline", "write-scenes", "analyze-manuscript")
    $missingFiles = @()
    
    foreach ($cmd in $commands) {
        $path = Join-Path $CursorRulesPath "$cmd.mdc"
        if (-not (Test-Path $path)) {
            $missingFiles += "$cmd.mdc"
        }
    }
    
    if ($missingFiles.Count -eq 0) {
        Write-StepLog "All Cursor files verified successfully!" -Level "Success"
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
    Write-Host "Novel-OS Cursor Setup for Windows (PowerShell)" -ForegroundColor Cyan
    Write-Host "================================================" -ForegroundColor Cyan
    Write-Host ""

    # Check if Novel-OS base installation is present
    Update-Progress "Checking Novel-OS base installation"
    
    if (-not (Test-Path (Join-Path $NovelOSPath "instructions")) -or -not (Test-Path (Join-Path $NovelOSPath "standards"))) {
        Write-StepLog "Novel-OS base installation not found!" -Level "Error"
        Write-Host ""
        Write-StepLog "Please install the Novel-OS base installation first:" -Level "Info"
        Write-Host ""
        Write-StepLog "Option 1 - Run the PowerShell setup:" -Level "Info"
        Write-StepLog "  .\setup.ps1" -Level "Info"
        Write-Host ""
        Write-StepLog "Option 2 - Run the Windows batch file:" -Level "Info"
        Write-StepLog "  setup.bat" -Level "Info"
        Write-Host ""
        Write-StepLog "Option 3 - Manual installation:" -Level "Info"
        Write-StepLog "  Follow instructions in the Novel-OS README" -Level "Info"
        Write-Host ""
        exit 1
    }

    # Create .cursor/rules directory
    Write-Host ""
    Update-Progress "Creating .cursor\rules directory"
    Write-StepLog "Creating .cursor\rules directory..." -Level "Info"
    
    if (-not (Test-Path $CursorRulesPath)) {
        New-Item -Path $CursorRulesPath -ItemType Directory -Force | Out-Null
    }

    # Download and set up Cursor command files
    Write-Host ""
    Write-StepLog "Downloading and setting up Cursor command files..." -Level "Info"
    
    $commands = @("plan-novel", "create-outline", "write-scenes", "analyze-manuscript")
    foreach ($cmd in $commands) {
        Update-Progress "Processing $cmd"
        Install-CursorCommandFile $cmd | Out-Null
    }
    
    # Verification
    if ($Verify) {
        Write-Host ""
        Update-Progress "Verifying installation"
        Test-CursorInstallation | Out-Null
    }
    
    # Complete progress
    Write-Progress -Activity "Installing Novel-OS for Cursor" -Completed
    
    # Success message
    Write-Host ""
    Write-StepLog "Novel-OS Cursor setup complete!" -Level "Success"
    Write-Host ""
    Write-StepLog "Files installed to:" -Level "Info"
    Write-StepLog "   $CursorRulesPath             - Cursor novel writing command rules" -Level "Info"
    Write-Host ""
    Write-StepLog "Next steps:" -Level "Info"
    Write-Host ""
    Write-StepLog "Use Novel-OS commands in Cursor with @ prefix:" -Level "Info"
    Write-StepLog "  @plan-novel        - Start a new novel project with Novel-OS" -Level "Success"
    Write-StepLog "  @analyze-manuscript - Add Novel-OS to an existing manuscript" -Level "Success"  
    Write-StepLog "  @create-outline    - Create a story outline (or simply ask 'what's next?')" -Level "Success"
    Write-StepLog "  @write-scenes      - Write scenes and chapters" -Level "Success"
    Write-Host ""
    Write-StepLog "Happy novel writing with AI assistance!" -Level "Success"
    Write-Host ""
}
catch {
    Write-Progress -Activity "Installing Novel-OS for Cursor" -Completed
    Write-StepLog "Installation failed: $($_.Exception.Message)" -Level "Error"
    Write-StepLog "Please check your internet connection and try again." -Level "Info"
    exit 1
}