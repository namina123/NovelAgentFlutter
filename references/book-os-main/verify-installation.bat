@echo off
setlocal enabledelayedexpansion

REM Novel-OS Installation Verification Script for Windows (Batch Wrapper)
REM This batch file provides a simple interface to the PowerShell verification script

echo [INFO] Novel-OS Installation Verification
echo ====================================
echo.

REM Check if PowerShell is available
powershell -Command "Get-Host" >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] PowerShell is not available on this system.
    echo.
    echo The verification script requires PowerShell 5.1 or higher.
    echo Please install PowerShell or use the basic verification below.
    echo.
    goto basic_check
)

REM Check PowerShell version
for /f "tokens=*" %%i in ('powershell -Command "$PSVersionTable.PSVersion.Major"') do set PS_MAJOR=%%i
if %PS_MAJOR% LSS 5 (
    echo [WARN]  PowerShell version %PS_MAJOR% detected. Version 5.1+ recommended.
    echo.
    echo Would you like to continue with basic verification? ^(Y/N^)
    set /p CONTINUE=
    if /i "!CONTINUE!" neq "Y" goto end
    goto basic_check
)

REM Parse command line arguments for PowerShell script
set PS_ARGS=
if "%~1"=="-all" set PS_ARGS=-CheckAll
if "%~1"=="--all" set PS_ARGS=-CheckAll
if "%~1"=="-base" set PS_ARGS=-CheckBase
if "%~1"=="--base" set PS_ARGS=-CheckBase
if "%~1"=="-claude" set PS_ARGS=-CheckClaude
if "%~1"=="--claude" set PS_ARGS=-CheckClaude
if "%~1"=="-cursor" set PS_ARGS=-CheckCursor
if "%~1"=="--cursor" set PS_ARGS=-CheckCursor
if "%~1"=="-detailed" set PS_ARGS=%PS_ARGS% -Detailed
if "%~1"=="--detailed" set PS_ARGS=%PS_ARGS% -Detailed
if "%~1"=="-h" goto show_help
if "%~1"=="--help" goto show_help

REM Run the PowerShell verification script
echo Running comprehensive verification with PowerShell...
echo.

if exist verify-installation.ps1 (
    powershell -ExecutionPolicy Bypass -File "verify-installation.ps1" %PS_ARGS%
) else (
    echo [ERROR] PowerShell verification script not found: verify-installation.ps1
    echo.
    echo Falling back to basic verification...
    goto basic_check
)

goto end

:show_help
echo Usage: %~nx0 [OPTIONS]
echo.
echo Options:
echo   -all, --all        Check all installations ^(base, Claude Code, Cursor^)
echo   -base, --base      Check only base Novel-OS installation
echo   -claude, --claude  Check only Claude Code installation  
echo   -cursor, --cursor  Check only Cursor installation
echo   -detailed          Show detailed information
echo   -h, --help         Show this help message
echo.
echo Examples:
echo   %~nx0              ^(Check all installations^)
echo   %~nx0 -base        ^(Check base installation only^)
echo   %~nx0 -detailed    ^(Detailed verification^)
echo.
goto end

:basic_check
echo Running basic verification...
echo.

REM Check base Novel-OS installation
echo [INFO] Checking base Novel-OS installation...

if exist "%USERPROFILE%\.novel-os" (
    echo [OK] Novel-OS directory found: %USERPROFILE%\.novel-os
    
    REM Check key directories
    if exist "%USERPROFILE%\.novel-os\standards" (
        echo [OK] Standards directory found
    ) else (
        echo [ERROR] Standards directory missing
    )
    
    if exist "%USERPROFILE%\.novel-os\instructions" (
        echo [OK] Instructions directory found
    ) else (
        echo [ERROR] Instructions directory missing
    )
    
    REM Check key files
    if exist "%USERPROFILE%\.novel-os\standards\writing-style.md" (
        echo [OK] Writing style standards found
    ) else (
        echo [ERROR] Writing style standards missing
    )
    
    if exist "%USERPROFILE%\.novel-os\instructions\core\plan-novel.md" (
        echo [OK] Plan novel instructions found
    ) else (
        echo [ERROR] Plan novel instructions missing
    )
    
) else (
    echo [ERROR] Novel-OS directory not found: %USERPROFILE%\.novel-os
    echo.
    echo To install Novel-OS, run: setup.bat
)

echo.

REM Check Claude Code installation  
echo [INFO] Checking Claude Code installation...

if exist "%USERPROFILE%\.claude" (
    echo [OK] Claude directory found
    
    if exist "%USERPROFILE%\.claude\commands" (
        echo [OK] Claude commands directory found
        
        REM Check for command files
        set CLAUDE_COMMANDS=0
        if exist "%USERPROFILE%\.claude\commands\plan-novel.md" set /a CLAUDE_COMMANDS+=1
        if exist "%USERPROFILE%\.claude\commands\create-outline.md" set /a CLAUDE_COMMANDS+=1
        if exist "%USERPROFILE%\.claude\commands\write-scenes.md" set /a CLAUDE_COMMANDS+=1
        if exist "%USERPROFILE%\.claude\commands\analyze-manuscript.md" set /a CLAUDE_COMMANDS+=1
        
        echo [OK] Found !CLAUDE_COMMANDS!/4 Claude command files
    ) else (
        echo [ERROR] Claude commands directory missing
    )
    
    if exist "%USERPROFILE%\.claude\agents" (
        echo [OK] Claude agents directory found
        
        REM Check for agent files
        set CLAUDE_AGENTS=0
        if exist "%USERPROFILE%\.claude\agents\prose-reviewer.md" set /a CLAUDE_AGENTS+=1
        if exist "%USERPROFILE%\.claude\agents\context-researcher.md" set /a CLAUDE_AGENTS+=1
        if exist "%USERPROFILE%\.claude\agents\writing-workflow.md" set /a CLAUDE_AGENTS+=1
        if exist "%USERPROFILE%\.claude\agents\manuscript-creator.md" set /a CLAUDE_AGENTS+=1
        if exist "%USERPROFILE%\.claude\agents\date-checker.md" set /a CLAUDE_AGENTS+=1
        if exist "%USERPROFILE%\.claude\agents\continuity-checker.md" set /a CLAUDE_AGENTS+=1
        
        echo [OK] Found !CLAUDE_AGENTS!/6 Claude agent files
    ) else (
        echo [ERROR] Claude agents directory missing
    )
    
) else (
    echo [WARN]  Claude directory not found ^(Claude Code not installed^)
    echo    To install: setup-claude-code.bat
)

echo.

REM Check Cursor installation in current directory
echo [INFO] Checking Cursor installation in current directory...

if exist ".cursor\rules" (
    echo [OK] Cursor rules directory found
    
    REM Check for Cursor command files
    set CURSOR_COMMANDS=0
    if exist ".cursor\rules\plan-novel.mdc" set /a CURSOR_COMMANDS+=1
    if exist ".cursor\rules\create-outline.mdc" set /a CURSOR_COMMANDS+=1
    if exist ".cursor\rules\write-scenes.mdc" set /a CURSOR_COMMANDS+=1
    if exist ".cursor\rules\analyze-manuscript.mdc" set /a CURSOR_COMMANDS+=1
    
    echo [OK] Found !CURSOR_COMMANDS!/4 Cursor command files
    
) else (
    echo [WARN]  Cursor rules directory not found ^(Cursor not installed in this project^)
    echo    To install: setup-cursor.bat
)

echo.

REM Summary
echo [INFO] Basic Verification Complete
echo.
echo For detailed verification and troubleshooting, please:
echo 1. Install PowerShell 5.1+ if available
echo 2. Run: verify-installation.ps1
echo.
echo For installation issues:
echo - Base Novel-OS: setup.bat
echo - Claude Code: setup-claude-code.bat  
echo - Cursor: setup-cursor.bat
echo.

:end
pause