#Requires -Version 5.1

<#
.SYNOPSIS
    Novel-OS Installation Verification Script for Windows (PowerShell)
    
.DESCRIPTION
    This script verifies your Novel-OS installation, checks file integrity,
    validates directory structure, and provides troubleshooting guidance.
    
.PARAMETER CheckAll
    Check all installations (base, Claude Code, and Cursor)
    
.PARAMETER CheckBase
    Check only the base Novel-OS installation
    
.PARAMETER CheckClaude
    Check only the Claude Code installation
    
.PARAMETER CheckCursor
    Check only the Cursor installation (in current directory)
    
.PARAMETER Fix
    Attempt to fix common issues automatically
    
.PARAMETER Detailed
    Show detailed information about each file
    
.PARAMETER Help
    Show this help message
    
.EXAMPLE
    .\verify-installation.ps1
    
.EXAMPLE
    .\verify-installation.ps1 -CheckAll -Detailed
    
.EXAMPLE
    .\verify-installation.ps1 -CheckBase -Fix
#>

param(
    [switch]$CheckAll,
    [switch]$CheckBase,
    [switch]$CheckClaude,
    [switch]$CheckCursor,
    [switch]$Fix,
    [switch]$Detailed,
    [switch]$Help
)

# Show help if requested
if ($Help) {
    Get-Help $MyInvocation.MyCommand.Path -Full
    exit 0
}

# Set strict mode and error action
Set-StrictMode -Version Latest
$ErrorActionPreference = "Continue"  # Continue on errors for verification

# Configuration
$NovelOSPath = Join-Path $env:USERPROFILE ".novel-os"
$ClaudeCommandsPath = Join-Path $env:USERPROFILE ".claude\commands"
$ClaudeAgentsPath = Join-Path $env:USERPROFILE ".claude\agents"
$CursorRulesPath = ".cursor\rules"

# Default to CheckAll if no specific check is requested
if (-not ($CheckBase -or $CheckClaude -or $CheckCursor)) {
    $CheckAll = $true
}

# Enhanced logging function
function Write-CheckLog {
    param(
        [string]$Message,
        [ValidateSet("Info", "Success", "Warning", "Error", "Header")]$Level = "Info"
    )
    
    $colors = @{
        "Info" = "White"
        "Success" = "Green" 
        "Warning" = "Yellow"
        "Error" = "Red"
        "Header" = "Cyan"
    }
    
    $icons = @{
        "Info" = "[INFO]"
        "Success" = "[OK]"
        "Warning" = "[WARN]"
        "Error" = "[ERROR]"
        "Header" = "[CHECK]"
    }
    
    Write-Host "$($icons[$Level]) $Message" -ForegroundColor $colors[$Level]
}

# File verification function
function Test-FileIntegrity {
    param(
        [string]$FilePath,
        [string]$Description,
        [int]$MinSize = 100
    )
    
    $result = @{
        Path = $FilePath
        Exists = $false
        Size = 0
        Valid = $false
        Description = $Description
    }
    
    if (Test-Path $FilePath) {
        $result.Exists = $true
        $fileInfo = Get-Item $FilePath
        $result.Size = $fileInfo.Length
        
        # Basic validation - check if file has content and basic structure
        if ($result.Size -gt $MinSize) {
            try {
                $content = Get-Content $FilePath -Raw -ErrorAction Stop
                if ($content -match "Novel-OS|novel|writing|AI" -or $content.Length -gt $MinSize) {
                    $result.Valid = $true
                }
            }
            catch {
                # File might be locked or corrupted
                $result.Valid = $false
            }
        }
    }
    
    return $result
}

# Directory structure verification
function Test-DirectoryStructure {
    param(
        [string]$BasePath,
        [string[]]$RequiredDirectories
    )
    
    $results = @()
    
    foreach ($dir in $RequiredDirectories) {
        $fullPath = Join-Path $BasePath $dir
        $exists = Test-Path $fullPath
        
        $results += @{
            Path = $fullPath
            Exists = $exists
            Name = $dir
        }
    }
    
    return $results
}

# Environment validation
function Test-Environment {
    Write-CheckLog "Environment Validation" -Level "Header"
    
    # Check PowerShell version
    $psVersion = $PSVersionTable.PSVersion
    if ($psVersion.Major -ge 5) {
        Write-CheckLog "PowerShell Version: $psVersion" -Level "Success"
    } else {
        Write-CheckLog "PowerShell Version: $psVersion (Minimum 5.1 recommended)" -Level "Warning"
    }
    
    # Check Internet connectivity
    try {
        $null = Invoke-WebRequest -Uri "https://raw.githubusercontent.com" -UseBasicParsing -TimeoutSec 10
        Write-CheckLog "Internet connectivity" -Level "Success"
    }
    catch {
        Write-CheckLog "Internet connectivity issue detected" -Level "Warning"
    }
    
    # Check user profile path
    if (Test-Path $env:USERPROFILE) {
        Write-CheckLog "User profile path: $env:USERPROFILE" -Level "Success"
    } else {
        Write-CheckLog "User profile path issue" -Level "Error"
    }
    
    Write-Host ""
}

# Base Novel-OS verification
function Test-BaseInstallation {
    Write-CheckLog "Base Novel-OS Installation" -Level "Header"
    
    $issuesFound = @()
    
    # Check main directory
    if (-not (Test-Path $NovelOSPath)) {
        Write-CheckLog "Novel-OS directory not found: $NovelOSPath" -Level "Error"
        $issuesFound += "Missing base directory"
        return $issuesFound
    }
    
    Write-CheckLog "Base directory found: $NovelOSPath" -Level "Success"
    
    # Check directory structure
    $requiredDirs = @(
        "standards",
        "standards\writing-style", 
        "standards\genre-guides",
        "instructions",
        "instructions\core",
        "instructions\meta"
    )
    
    $dirResults = Test-DirectoryStructure -BasePath $NovelOSPath -RequiredDirectories $requiredDirs
    foreach ($dirResult in $dirResults) {
        if ($dirResult.Exists) {
            if ($Detailed) {
                Write-CheckLog "Directory: $($dirResult.Name)" -Level "Success"
            }
        } else {
            Write-CheckLog "Missing directory: $($dirResult.Name)" -Level "Error"
            $issuesFound += "Missing directory: $($dirResult.Name)"
        }
    }
    
    # Check required files
    $requiredFiles = @(
        @{Path = "standards\writing-style.md"; Name = "Writing Style Standards"}
        @{Path = "standards\narrative-techniques.md"; Name = "Narrative Techniques"}
        @{Path = "standards\writing-style\description-style.md"; Name = "Description Style Guide"}
        @{Path = "standards\genre-guides\literary-fiction.md"; Name = "Literary Fiction Guide"}
        @{Path = "standards\genre-guides\mystery-thriller.md"; Name = "Mystery Thriller Guide"}
        @{Path = "standards\genre-guides\fantasy-sci-fi.md"; Name = "Fantasy Sci-Fi Guide"}
        @{Path = "instructions\core\plan-novel.md"; Name = "Plan Novel Instructions"}
        @{Path = "instructions\core\create-outline.md"; Name = "Create Outline Instructions"}
        @{Path = "instructions\core\write-scenes.md"; Name = "Write Scenes Instructions"}
        @{Path = "instructions\core\write-scene.md"; Name = "Write Scene Instructions"}
        @{Path = "instructions\core\analyze-manuscript.md"; Name = "Analyze Manuscript Instructions"}
        @{Path = "instructions\meta\pre-flight.md"; Name = "Pre-flight Instructions"}
    )
    
    foreach ($file in $requiredFiles) {
        $fullPath = Join-Path $NovelOSPath $file.Path
        $result = Test-FileIntegrity -FilePath $fullPath -Description $file.Name
        
        if ($result.Valid) {
            if ($Detailed) {
                Write-CheckLog "$($file.Name) - $($result.Size) bytes" -Level "Success"
            }
        } elseif ($result.Exists) {
            Write-CheckLog "$($file.Name): File exists but may be corrupted (Size: $($result.Size) bytes)" -Level "Warning"
            $issuesFound += "Potentially corrupted: $($file.Name)"
        } else {
            Write-CheckLog "$($file.Name): File missing" -Level "Error"
            $issuesFound += "Missing file: $($file.Name)"
        }
    }
    
    if ($issuesFound.Count -eq 0) {
        Write-CheckLog "Base installation verification passed!" -Level "Success"
    } else {
        Write-CheckLog "Base installation has $($issuesFound.Count) issue(s)" -Level "Error"
    }
    
    Write-Host ""
    return $issuesFound
}

# Claude Code installation verification
function Test-ClaudeInstallation {
    Write-CheckLog "Claude Code Installation" -Level "Header"
    
    $issuesFound = @()
    
    # Check directories
    if (-not (Test-Path $ClaudeCommandsPath)) {
        Write-CheckLog "Claude commands directory not found: $ClaudeCommandsPath" -Level "Error"
        $issuesFound += "Missing Claude commands directory"
    } else {
        Write-CheckLog "Claude commands directory found" -Level "Success"
    }
    
    if (-not (Test-Path $ClaudeAgentsPath)) {
        Write-CheckLog "Claude agents directory not found: $ClaudeAgentsPath" -Level "Error"
        $issuesFound += "Missing Claude agents directory"
    } else {
        Write-CheckLog "Claude agents directory found" -Level "Success"
    }
    
    # Check command files
    $commands = @("plan-novel", "create-outline", "write-scenes", "analyze-manuscript")
    foreach ($cmd in $commands) {
        $path = Join-Path $ClaudeCommandsPath "$cmd.md"
        $result = Test-FileIntegrity -FilePath $path -Description "Claude command: $cmd"
        
        if ($result.Valid) {
            if ($Detailed) {
                Write-CheckLog "Command $cmd - $($result.Size) bytes" -Level "Success"
            }
        } elseif ($result.Exists) {
            Write-CheckLog "Command $cmd - File exists but may be corrupted" -Level "Warning"
            $issuesFound += "Potentially corrupted command: $cmd"
        } else {
            Write-CheckLog "Command $cmd - File missing" -Level "Error"
            $issuesFound += "Missing command: $cmd"
        }
    }
    
    # Check agent files
    $agents = @("prose-reviewer", "context-researcher", "writing-workflow", "manuscript-creator", "date-checker", "continuity-checker")
    foreach ($agent in $agents) {
        $path = Join-Path $ClaudeAgentsPath "$agent.md"
        $result = Test-FileIntegrity -FilePath $path -Description "Claude agent: $agent"
        
        if ($result.Valid) {
            if ($Detailed) {
                Write-CheckLog "Agent $agent - $($result.Size) bytes" -Level "Success"
            }
        } elseif ($result.Exists) {
            Write-CheckLog "Agent $agent - File exists but may be corrupted" -Level "Warning"
            $issuesFound += "Potentially corrupted agent: $agent"
        } else {
            Write-CheckLog "Agent $agent - File missing" -Level "Error"
            $issuesFound += "Missing agent: $agent"
        }
    }
    
    if ($issuesFound.Count -eq 0) {
        Write-CheckLog "Claude Code installation verification passed!" -Level "Success"
    } else {
        Write-CheckLog "Claude Code installation has $($issuesFound.Count) issue(s)" -Level "Error"
    }
    
    Write-Host ""
    return $issuesFound
}

# Cursor installation verification
function Test-CursorInstallation {
    Write-CheckLog "Cursor Installation (Current Directory)" -Level "Header"
    
    $issuesFound = @()
    
    # Check if we're in a valid project directory
    $currentDir = Get-Location
    Write-CheckLog "Checking Cursor installation in: $currentDir" -Level "Info"
    
    # Check .cursor/rules directory
    if (-not (Test-Path $CursorRulesPath)) {
        Write-CheckLog "Cursor rules directory not found: $CursorRulesPath" -Level "Error"
        $issuesFound += "Missing Cursor rules directory"
    } else {
        Write-CheckLog "Cursor rules directory found" -Level "Success"
    }
    
    # Check command files
    $commands = @("plan-novel", "create-outline", "write-scenes", "analyze-manuscript")
    foreach ($cmd in $commands) {
        $path = Join-Path $CursorRulesPath "$cmd.mdc"
        $result = Test-FileIntegrity -FilePath $path -Description "Cursor command: $cmd"
        
        if ($result.Valid) {
            if ($Detailed) {
                Write-CheckLog "Command $cmd - $($result.Size) bytes" -Level "Success"
            }
        } elseif ($result.Exists) {
            Write-CheckLog "Command $cmd - File exists but may be corrupted" -Level "Warning"
            $issuesFound += "Potentially corrupted Cursor command: $cmd"
        } else {
            Write-CheckLog "Command $cmd - File missing" -Level "Error"
            $issuesFound += "Missing Cursor command: $cmd"
        }
    }
    
    if ($issuesFound.Count -eq 0) {
        Write-CheckLog "Cursor installation verification passed!" -Level "Success"
    } else {
        Write-CheckLog "Cursor installation has $($issuesFound.Count) issue(s)" -Level "Error"
    }
    
    Write-Host ""
    return $issuesFound
}

# Provide troubleshooting guidance
function Show-TroubleshootingGuide {
    param([string[]]$Issues)
    
    if ($Issues.Count -eq 0) {
        return
    }
    
    Write-CheckLog "Troubleshooting Guide" -Level "Header"
    
    if ($Issues -match "Missing base directory|Missing.*directory") {
        Write-CheckLog "Missing Directories:" -Level "Info"
        Write-CheckLog "   Run the setup script again: .\setup.ps1" -Level "Info"
        Write-Host ""
    }
    
    if ($Issues -match "Missing.*file") {
        Write-CheckLog "Missing Files:" -Level "Info"
        Write-CheckLog "   Re-run setup with overwrite flags:" -Level "Info"
        Write-CheckLog "   .\setup.ps1 -OverwriteInstructions -OverwriteStandards" -Level "Info"
        Write-Host ""
    }
    
    if ($Issues -match "Missing Claude") {
        Write-CheckLog "Claude Code Issues:" -Level "Info"
        Write-CheckLog "   Re-run Claude Code setup: .\setup-claude-code.ps1" -Level "Info"
        Write-Host ""
    }
    
    if ($Issues -match "Missing Cursor") {
        Write-CheckLog "Cursor Issues:" -Level "Info"
        Write-CheckLog "   Make sure you're in your novel project directory" -Level "Info"
        Write-CheckLog "   Re-run Cursor setup: .\setup-cursor.ps1" -Level "Info"
        Write-Host ""
    }
    
    if ($Issues -match "corrupted") {
        Write-CheckLog "Corrupted Files:" -Level "Info"
        Write-CheckLog "   Check your internet connection" -Level "Info"
        Write-CheckLog "   Re-run setup with overwrite flags" -Level "Info"
        Write-Host ""
    }
}

# Main verification process
try {
    Write-Host "Novel-OS Installation Verification for Windows (PowerShell)" -ForegroundColor Cyan
    Write-Host "==============================================================" -ForegroundColor Cyan
    Write-Host ""

    $allIssues = @()
    
    # Environment check
    Test-Environment
    
    # Base installation check
    if ($CheckAll -or $CheckBase) {
        $baseIssues = Test-BaseInstallation
        $allIssues += $baseIssues
    }
    
    # Claude Code check
    if ($CheckAll -or $CheckClaude) {
        $claudeIssues = Test-ClaudeInstallation
        $allIssues += $claudeIssues
    }
    
    # Cursor check
    if ($CheckAll -or $CheckCursor) {
        $cursorIssues = Test-CursorInstallation
        $allIssues += $cursorIssues
    }
    
    # Summary
    Write-CheckLog "Verification Summary" -Level "Header"
    
    if ($allIssues.Count -eq 0) {
        Write-CheckLog "All verifications passed! Your Novel-OS installation is working correctly." -Level "Success"
    } else {
        Write-CheckLog "Found $($allIssues.Count) issue(s) that need attention:" -Level "Warning"
        foreach ($issue in $allIssues | Select-Object -Unique) {
            Write-CheckLog "   • $issue" -Level "Warning"
        }
        Write-Host ""
        
        # Show troubleshooting guide
        Show-TroubleshootingGuide -Issues $allIssues
    }
    
    Write-Host ""
    Write-CheckLog "For more help, visit: https://github.com/forsonny/book-os" -Level "Info"
    Write-Host ""
}
catch {
    Write-CheckLog "Verification failed: $($_.Exception.Message)" -Level "Error"
    exit 1
}