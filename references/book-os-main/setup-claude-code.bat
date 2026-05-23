@echo off
setlocal enabledelayedexpansion

REM Novel-OS Claude Code Setup Script for Windows
REM This script installs Novel-OS commands for Claude Code

echo [INFO] Novel-OS Claude Code Setup for Windows
echo ==========================================
echo.

REM Check if Novel-OS base installation is present
if not exist "%USERPROFILE%\.novel-os\instructions" goto missing_installation
if not exist "%USERPROFILE%\.novel-os\standards" goto missing_installation
goto continue_setup

:missing_installation
echo [WARN]  Novel-OS base installation not found!
echo.
echo Please install the Novel-OS base installation first:
echo.
echo Option 1 - Run the Windows batch file:
echo   setup.bat
echo.
echo Option 2 - Manual installation:
echo   Follow instructions in the Novel-OS README
echo.
exit /b 1

:continue_setup
REM Base URL for raw GitHub content
set BASE_URL=https://raw.githubusercontent.com/forsonny/book-os/main

REM Create directories
echo [INFO] Creating directories...
if not exist "%USERPROFILE%\.claude\commands" mkdir "%USERPROFILE%\.claude\commands"
if not exist "%USERPROFILE%\.claude\agents" mkdir "%USERPROFILE%\.claude\agents"
if not exist "%USERPROFILE%\.claude\output-styles" mkdir "%USERPROFILE%\.claude\output-styles"

REM Function to detect Agent-OS installation
:detect_agent_os
set AGENT_OS_PATH=%USERPROFILE%\.agent-os
set AGENT_OS_COMMANDS=%USERPROFILE%\.agent-os\commands
set AGENT_OS_INSTRUCTIONS=%USERPROFILE%\.agent-os\instructions\core
set AGENT_OS_FOUND=0

if exist "%AGENT_OS_PATH%" (
    if exist "%AGENT_OS_COMMANDS%" (
        if exist "%AGENT_OS_INSTRUCTIONS%" (
            REM Check for key Agent-OS files
            set /a FOUND_COMMANDS=0
            if exist "%AGENT_OS_COMMANDS%\plan-product.md" set /a FOUND_COMMANDS+=1
            if exist "%AGENT_OS_COMMANDS%\create-spec.md" set /a FOUND_COMMANDS+=1
            if exist "%AGENT_OS_COMMANDS%\execute-tasks.md" set /a FOUND_COMMANDS+=1
            if exist "%AGENT_OS_COMMANDS%\analyze-product.md" set /a FOUND_COMMANDS+=1
            
            REM Consider Agent-OS installed if at least 2 core commands are found
            if !FOUND_COMMANDS! GEQ 2 set AGENT_OS_FOUND=1
        )
    )
)
goto :eof

REM Configure CLAUDE.md for Novel-OS
echo.
echo [INFO] Configuring Claude Code for Novel-OS...
set CLAUDE_CONFIG=%USERPROFILE%\.claude\CLAUDE.md

REM Check if CLAUDE.md already exists
if exist "%CLAUDE_CONFIG%" (
    REM Backup existing file
    set BACKUP_FILE=%CLAUDE_CONFIG%.backup-%DATE:~10,4%%DATE:~4,2%%DATE:~7,2%-%TIME:~0,2%%TIME:~3,2%%TIME:~6,2%
    copy "%CLAUDE_CONFIG%" "%BACKUP_FILE%" >nul 2>&1
    echo   [WARN]  Backed up existing CLAUDE.md to !BACKUP_FILE!
    
    REM Check if it already contains Novel-OS configuration
    findstr /C:"Novel-OS.*Creative Writing" "%CLAUDE_CONFIG%" >nul 2>&1
    if !ERRORLEVEL! == 0 (
        findstr /C:"/plan-novel.*novel planning" "%CLAUDE_CONFIG%" >nul 2>&1
        if !ERRORLEVEL! == 0 (
            echo   [OK] CLAUDE.md already contains Novel-OS configuration - skipping
            goto skip_config
        )
    )
)

REM Detect if Agent-OS is installed
call :detect_agent_os

if !AGENT_OS_FOUND! == 1 (
    echo   [INFO] Agent-OS detected - using combined Novel-OS + Agent-OS template
    set TEMPLATE_URL=%BASE_URL%/claude-code/CLAUDE.md.template
) else (
    echo   [INFO] No Agent-OS found - using Novel-OS-only template
    set TEMPLATE_URL=%BASE_URL%/claude-code/CLAUDE-novel-only.md.template
)

REM Download the appropriate CLAUDE.md template
curl -s -o "%CLAUDE_CONFIG%" "!TEMPLATE_URL!"
if !ERRORLEVEL! == 0 (
    echo   [OK] CLAUDE.md configured successfully
) else (
    echo   [WARN] Failed to download CLAUDE.md template
)

:skip_config

REM Download command files for Claude Code
echo.
echo [INFO] Downloading Claude Code command files to %USERPROFILE%\.claude\commands\

REM Commands
set commands=plan-novel create-outline write-scenes analyze-manuscript

for %%c in (%commands%) do (
    if exist "%USERPROFILE%\.claude\commands\%%c.md" (
        echo   [WARN]  %USERPROFILE%\.claude\commands\%%c.md already exists - skipping
    ) else (
        curl -s -o "%USERPROFILE%\.claude\commands\%%c.md" "%BASE_URL%/commands/%%c.md"
        echo   [OK] %USERPROFILE%\.claude\commands\%%c.md
    )
)

REM Download Claude Code agents
echo.
echo [INFO] Downloading Claude Code subagents to %USERPROFILE%\.claude\agents\

REM List of agent files to download
set agents=prose-reviewer context-researcher writing-workflow manuscript-creator date-checker continuity-checker

for %%a in (%agents%) do (
    if exist "%USERPROFILE%\.claude\agents\%%a.md" (
        echo   [WARN]  %USERPROFILE%\.claude\agents\%%a.md already exists - skipping
    ) else (
        curl -s -o "%USERPROFILE%\.claude\agents\%%a.md" "%BASE_URL%/claude-code/agents/%%a.md"
        echo   [OK] %USERPROFILE%\.claude\agents\%%a.md
    )
)

REM Install Novel-OS output style
echo.
echo [INFO] Installing Novel-OS output style to %USERPROFILE%\.claude\output-styles\

if exist "%USERPROFILE%\.claude\output-styles\novel-os-assistant.md" (
    echo   [WARN]  %USERPROFILE%\.claude\output-styles\novel-os-assistant.md already exists - skipping
) else (
    curl -s -o "%USERPROFILE%\.claude\output-styles\novel-os-assistant.md" "%BASE_URL%/claude-code/output-styles/novel-os-assistant.md"
    echo   [OK] %USERPROFILE%\.claude\output-styles\novel-os-assistant.md
)

REM Function to verify installation
:verify_installation
echo.
echo [INFO] Verifying installation...

set MISSING_FILES=0
set CLAUDE_CONFIG=%USERPROFILE%\.claude\CLAUDE.md

REM Check CLAUDE.md configuration
if not exist "%CLAUDE_CONFIG%" (
    echo   [WARN] Missing: CLAUDE.md configuration
    set /a MISSING_FILES+=1
) else (
    REM Verify it contains Novel-OS configuration
    findstr /C:"Novel-OS.*Creative Writing" "%CLAUDE_CONFIG%" >nul 2>&1
    if !ERRORLEVEL! NEQ 0 (
        echo   [WARN] Missing: CLAUDE.md ^(missing Novel-OS configuration^)
        set /a MISSING_FILES+=1
    ) else (
        findstr /C:"/plan-novel.*novel" "%CLAUDE_CONFIG%" >nul 2>&1
        if !ERRORLEVEL! NEQ 0 (
            echo   [WARN] Missing: CLAUDE.md ^(missing Novel-OS configuration^)
            set /a MISSING_FILES+=1
        ) else (
            REM Check if Agent-OS is present and verify template type matches
            call :detect_agent_os
            
            findstr /C:"Agent-OS.*Software Development" "%CLAUDE_CONFIG%" >nul 2>&1
            if !ERRORLEVEL! == 0 (
                findstr /C:"/create-spec.*feature" "%CLAUDE_CONFIG%" >nul 2>&1
                if !ERRORLEVEL! == 0 (
                    set HAS_AGENT_OS_CONFIG=1
                ) else (
                    set HAS_AGENT_OS_CONFIG=0
                )
            ) else (
                set HAS_AGENT_OS_CONFIG=0
            )
            
            if !AGENT_OS_FOUND! == 1 (
                if !HAS_AGENT_OS_CONFIG! == 0 (
                    echo   [WARN] Agent-OS detected but CLAUDE.md uses Novel-OS-only template
                    echo   [INFO] Consider re-running setup to upgrade to combined template
                )
            ) else (
                if !HAS_AGENT_OS_CONFIG! == 1 (
                    echo   [INFO] CLAUDE.md includes Agent-OS configuration but Agent-OS not installed
                )
            )
        )
    )
)

REM Check command files
set commands=plan-novel create-outline write-scenes analyze-manuscript
for %%c in (%commands%) do (
    if not exist "%USERPROFILE%\.claude\commands\%%c.md" (
        echo   [WARN] Missing: commands\%%c.md
        set /a MISSING_FILES+=1
    )
)

REM Check agent files
set agents=prose-reviewer context-researcher writing-workflow manuscript-creator date-checker continuity-checker
for %%a in (%agents%) do (
    if not exist "%USERPROFILE%\.claude\agents\%%a.md" (
        echo   [WARN] Missing: agents\%%a.md
        set /a MISSING_FILES+=1
    )
)

REM Check output style files
set output_styles=novel-os-assistant
for %%s in (%output_styles%) do (
    if not exist "%USERPROFILE%\.claude\output-styles\%%s.md" (
        echo   [WARN] Missing: output-styles\%%s.md
        set /a MISSING_FILES+=1
    )
)

if !MISSING_FILES! == 0 (
    echo   [OK] All Claude Code files verified successfully!
) else (
    echo   [WARN] Found !MISSING_FILES! missing file^(s^)
)

goto :eof

REM Verify installation
call :verify_installation

echo.
echo [OK] Novel-OS Claude Code installation complete!
echo.
echo [INFO] Files installed to:
echo    %USERPROFILE%\.claude\CLAUDE.md        - Claude Code configuration (Novel-OS + Agent-OS)
echo    %USERPROFILE%\.claude\commands\        - Claude Code novel writing commands
echo    %USERPROFILE%\.claude\agents\          - Claude Code specialized writing subagents
echo    %USERPROFILE%\.claude\output-styles\   - Claude Code Novel-OS output style
echo.
echo Next steps:
echo.
echo For the best Novel-OS experience, switch to the writing-optimized output style:
echo   /output-style novel-os-assistant
echo.
echo Start a new novel project with:
echo   /plan-novel
echo.
echo Add Novel-OS to an existing manuscript with:
echo   /analyze-manuscript
echo.
echo Create a story outline with:
echo   /create-outline ^(or simply ask 'what's next?'^)
echo.
echo Write scenes and chapters with:
echo   /write-scenes
echo.
echo Happy novel writing with AI assistance! [INFO]echo.