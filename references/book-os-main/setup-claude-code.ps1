#Requires -Version 5.1

<#
.SYNOPSIS
    Novel-OS Claude Code Setup Script for Windows (PowerShell)
    
.DESCRIPTION
    This script installs Novel-OS commands and agents for Claude Code with enhanced 
    error handling, progress indicators, and verification capabilities.
    
.PARAMETER Verify
    Verify installation after completion
    
.PARAMETER Help
    Show this help message
    
.EXAMPLE
    .\setup-claude-code.ps1
    
.EXAMPLE
    .\setup-claude-code.ps1 -Verify
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
$ClaudeCommandsPath = Join-Path $env:USERPROFILE ".claude\commands"
$ClaudeAgentsPath = Join-Path $env:USERPROFILE ".claude\agents"
$ClaudeOutputStylesPath = Join-Path $env:USERPROFILE ".claude\output-styles"
$ClaudeConfigPath = Join-Path $env:USERPROFILE ".claude\CLAUDE.md"

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
$script:totalSteps = 15
$script:currentStep = 0

function Update-Progress {
    param([string]$Activity)
    $script:currentStep++
    $percentComplete = ($script:currentStep / $script:totalSteps) * 100
    Write-Progress -Activity "Installing Novel-OS for Claude Code" -Status $Activity -PercentComplete $percentComplete
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

# Agent-OS detection function
function Test-AgentOSInstalled {
    $AgentOSPath = Join-Path $env:USERPROFILE ".agent-os"
    $AgentOSCommandsPath = Join-Path $env:USERPROFILE ".agent-os\commands"
    $AgentOSInstructionsPath = Join-Path $env:USERPROFILE ".agent-os\instructions\core"
    
    # Check if Agent-OS directories exist
    if ((Test-Path $AgentOSPath) -and (Test-Path $AgentOSCommandsPath) -and (Test-Path $AgentOSInstructionsPath)) {
        # Check for key Agent-OS files
        $agentOSCommands = @("plan-product.md", "create-spec.md", "execute-tasks.md", "analyze-product.md")
        $foundCommands = 0
        
        foreach ($cmd in $agentOSCommands) {
            if (Test-Path (Join-Path $AgentOSCommandsPath $cmd)) {
                $foundCommands++
            }
        }
        
        # Consider Agent-OS installed if at least 2 core commands are found
        return ($foundCommands -ge 2)
    }
    
    return $false
}

# CLAUDE.md configuration function
function Install-ClaudeConfig {
    Write-StepLog "Configuring Claude Code for Novel-OS..." -Level "Info"
    
    # Check if CLAUDE.md already exists
    if (Test-Path $ClaudeConfigPath) {
        # Backup existing file
        $backupPath = "$ClaudeConfigPath.backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
        Copy-Item $ClaudeConfigPath $backupPath -Force
        Write-StepLog "Backed up existing CLAUDE.md to $(Split-Path $backupPath -Leaf)" -Level "Warning"
        
        # Check if it already contains Novel-OS configuration
        $existingContent = Get-Content $ClaudeConfigPath -Raw
        if ($existingContent -match "Novel-OS.*Creative Writing" -and $existingContent -match "/plan-novel.*novel planning") {
            Write-StepLog "CLAUDE.md already contains Novel-OS configuration - skipping" -Level "Success"
            return $true
        }
    }
    
    # Detect if Agent-OS is installed
    $hasAgentOS = Test-AgentOSInstalled
    
    if ($hasAgentOS) {
        Write-StepLog "Agent-OS detected - using combined Novel-OS + Agent-OS template" -Level "Info"
        $templateUrl = "$BaseUrl/claude-code/CLAUDE.md.template"
    } else {
        Write-StepLog "No Agent-OS found - using Novel-OS-only template" -Level "Info"
        $templateUrl = "$BaseUrl/claude-code/CLAUDE-novel-only.md.template"
    }
    
    try {
        if (Download-FileWithRetry -Url $templateUrl -OutputPath $ClaudeConfigPath) {
            Write-StepLog "CLAUDE.md configured successfully" -Level "Success"
            return $true
        } else {
            Write-StepLog "Failed to download CLAUDE.md template" -Level "Error"
            return $false
        }
    }
    catch {
        Write-StepLog "Error configuring CLAUDE.md: $($_.Exception.Message)" -Level "Error"
        return $false
    }
}

# File installation function
function Install-ClaudeFile {
    param(
        [string]$RelativePath,
        [string]$OutputPath,
        [string]$Description
    )
    
    $url = "$BaseUrl/$RelativePath"
    
    if (Test-Path $OutputPath) {
        Write-StepLog "$OutputPath already exists - skipping" -Level "Warning"
        return $true
    }
    
    if (Download-FileWithRetry -Url $url -OutputPath $OutputPath) {
        Write-StepLog "$OutputPath" -Level "Success"
        return $true
    }
    
    return $false
}

# Verification function
function Test-ClaudeInstallation {
    Write-StepLog "Verifying Claude Code installation..." -Level "Info"
    
    $commands = @("plan-novel", "create-outline", "write-scenes", "analyze-manuscript")
    $agents = @("prose-reviewer", "context-researcher", "writing-workflow", "manuscript-creator", "date-checker", "continuity-checker")
    $outputStyles = @("novel-os-assistant")
    
    $missingFiles = @()
    
    # Check CLAUDE.md configuration
    if (-not (Test-Path $ClaudeConfigPath)) {
        $missingFiles += "CLAUDE.md configuration"
    } else {
        # Verify it contains Novel-OS configuration
        $configContent = Get-Content $ClaudeConfigPath -Raw
        if (-not ($configContent -match "Novel-OS.*Creative Writing" -and $configContent -match "/plan-novel.*novel")) {
            $missingFiles += "CLAUDE.md (missing Novel-OS configuration)"
        } else {
            # Check if Agent-OS is present and verify template type matches
            $hasAgentOS = Test-AgentOSInstalled
            $hasAgentOSConfig = $configContent -match "Agent-OS.*Software Development" -and $configContent -match "/create-spec.*feature"
            
            if ($hasAgentOS -and -not $hasAgentOSConfig) {
                Write-StepLog "Agent-OS detected but CLAUDE.md uses Novel-OS-only template" -Level "Warning"
                Write-StepLog "Consider re-running setup to upgrade to combined template" -Level "Info"
            } elseif (-not $hasAgentOS -and $hasAgentOSConfig) {
                Write-StepLog "CLAUDE.md includes Agent-OS configuration but Agent-OS not installed" -Level "Info"
            }
        }
    }
    
    # Check commands
    foreach ($cmd in $commands) {
        $path = Join-Path $ClaudeCommandsPath "$cmd.md"
        if (-not (Test-Path $path)) {
            $missingFiles += "commands\$cmd.md"
        }
    }
    
    # Check agents
    foreach ($agent in $agents) {
        $path = Join-Path $ClaudeAgentsPath "$agent.md"
        if (-not (Test-Path $path)) {
            $missingFiles += "agents\$agent.md"
        }
    }
    
    # Check output styles
    foreach ($style in $outputStyles) {
        $path = Join-Path $ClaudeOutputStylesPath "$style.md"
        if (-not (Test-Path $path)) {
            $missingFiles += "output-styles\$style.md"
        }
    }
    
    if ($missingFiles.Count -eq 0) {
        Write-StepLog "All Claude Code files verified successfully!" -Level "Success"
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
    Write-Host "Novel-OS Claude Code Setup for Windows (PowerShell)" -ForegroundColor Cyan
    Write-Host "====================================================" -ForegroundColor Cyan
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

    # Create directories
    Update-Progress "Creating directories"
    Write-StepLog "Creating directories..." -Level "Info"
    
    if (-not (Test-Path $ClaudeCommandsPath)) {
        New-Item -Path $ClaudeCommandsPath -ItemType Directory -Force | Out-Null
    }
    
    if (-not (Test-Path $ClaudeAgentsPath)) {
        New-Item -Path $ClaudeAgentsPath -ItemType Directory -Force | Out-Null
    }
    
    if (-not (Test-Path $ClaudeOutputStylesPath)) {
        New-Item -Path $ClaudeOutputStylesPath -ItemType Directory -Force | Out-Null
    }

    # Configure CLAUDE.md for Novel-OS
    Update-Progress "Configuring Claude Code"
    Install-ClaudeConfig | Out-Null

    # Download command files for Claude Code
    Write-Host ""
    Write-StepLog "Downloading Claude Code command files..." -Level "Info"
    
    $commands = @("plan-novel", "create-outline", "write-scenes", "analyze-manuscript")
    foreach ($cmd in $commands) {
        Update-Progress "Downloading $cmd.md"
        $outputPath = Join-Path $ClaudeCommandsPath "$cmd.md"
        Install-ClaudeFile "commands/$cmd.md" $outputPath "command file" | Out-Null
    }

    # Download Claude Code agents
    Write-Host ""
    Write-StepLog "Downloading Claude Code subagents..." -Level "Info"
    
    $agents = @("prose-reviewer", "context-researcher", "writing-workflow", "manuscript-creator", "date-checker", "continuity-checker")
    foreach ($agent in $agents) {
        Update-Progress "Downloading $agent.md"
        $outputPath = Join-Path $ClaudeAgentsPath "$agent.md"
        Install-ClaudeFile "claude-code/agents/$agent.md" $outputPath "agent file" | Out-Null
    }

    # Install Novel-OS output style
    Write-Host ""
    Write-StepLog "Installing Novel-OS output style..." -Level "Info"
    Update-Progress "Installing novel-os-assistant.md"
    $outputStylePath = Join-Path $ClaudeOutputStylesPath "novel-os-assistant.md"
    Install-ClaudeFile "claude-code/output-styles/novel-os-assistant.md" $outputStylePath "output style" | Out-Null
    
    # Verification
    if ($Verify) {
        Write-Host ""
        Update-Progress "Verifying installation"
        Test-ClaudeInstallation | Out-Null
    }
    
    # Complete progress
    Write-Progress -Activity "Installing Novel-OS for Claude Code" -Completed
    
    # Success message
    Write-Host ""
    Write-StepLog "Novel-OS Claude Code installation complete!" -Level "Success"
    Write-Host ""
    Write-StepLog "Files installed to:" -Level "Info"
    Write-StepLog "   $ClaudeConfigPath    - Claude Code configuration (Novel-OS + Agent-OS)" -Level "Info"
    Write-StepLog "   $ClaudeCommandsPath        - Claude Code novel writing commands" -Level "Info"
    Write-StepLog "   $ClaudeAgentsPath          - Claude Code specialized writing subagents" -Level "Info"
    Write-StepLog "   $ClaudeOutputStylesPath     - Claude Code Novel-OS output style" -Level "Info"
    Write-Host ""
    Write-StepLog "Next steps:" -Level "Info"
    Write-Host ""
    Write-StepLog "For the best Novel-OS experience, switch to the writing-optimized output style:" -Level "Info"
    Write-StepLog "  /output-style novel-os-assistant" -Level "Success"
    Write-Host ""
    Write-StepLog "Start a new novel project with:" -Level "Info"
    Write-StepLog "  /plan-novel" -Level "Success"
    Write-Host ""
    Write-StepLog "Add Novel-OS to an existing manuscript with:" -Level "Info"
    Write-StepLog "  /analyze-manuscript" -Level "Success"
    Write-Host ""
    Write-StepLog "Create a story outline with:" -Level "Info"
    Write-StepLog "  /create-outline (or simply ask 'what's next?')" -Level "Success"
    Write-Host ""
    Write-StepLog "Write scenes and chapters with:" -Level "Info"
    Write-StepLog "  /write-scenes" -Level "Success"
    Write-Host ""
    Write-StepLog "Happy novel writing with AI assistance!" -Level "Success"
    Write-Host ""
}
catch {
    Write-Progress -Activity "Installing Novel-OS for Claude Code" -Completed
    Write-StepLog "Installation failed: $($_.Exception.Message)" -Level "Error"
    Write-StepLog "Please check your internet connection and try again." -Level "Info"
    exit 1
}