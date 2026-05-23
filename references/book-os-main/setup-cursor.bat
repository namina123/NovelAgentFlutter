@echo off
setlocal enabledelayedexpansion

REM Novel-OS Cursor Setup Script for Windows
REM This script installs Novel-OS commands for Cursor in the current project

echo [INFO] Novel-OS Cursor Setup for Windows
echo =====================================
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
echo.
echo [INFO] Creating .cursor\rules directory...
if not exist ".cursor\rules" mkdir ".cursor\rules"

REM Base URL for raw GitHub content
set BASE_URL=https://raw.githubusercontent.com/forsonny/book-os/main

echo.
echo [INFO] Downloading and setting up Cursor command files...

REM Process each command file
set commands=plan-novel create-outline write-scenes analyze-manuscript

for %%c in (%commands%) do (
    call :process_command_file %%c
)

echo.
echo [OK] Novel-OS Cursor setup complete!
echo.
echo [INFO] Files installed to:
echo    .cursor\rules\             - Cursor novel writing command rules
echo.
echo Next steps:
echo.
echo Use Novel-OS commands in Cursor with @ prefix:
echo   @plan-novel        - Start a new novel project with Novel-OS
echo   @analyze-manuscript - Add Novel-OS to an existing manuscript
echo   @create-outline    - Create a story outline ^(or simply ask 'what's next?'^)
echo   @write-scenes      - Write scenes and chapters
echo.
echo Happy novel writing with AI assistance! [INFO]echo.
goto :eof

:process_command_file
set cmd=%1
set temp_file=%TEMP%\%cmd%.md
set target_file=.cursor\rules\%cmd%.mdc

REM Download the file
curl -s -o "%temp_file%" "%BASE_URL%/commands/%cmd%.md"
if %errorlevel% neq 0 (
    echo   [ERROR] Failed to download %cmd%.md
    exit /b 1
)

REM Create the front-matter and content
(
echo ---
echo alwaysApply: false
echo ---
echo.
type "%temp_file%"
) > "%target_file%"

REM Clean up temp file
del "%temp_file%" >nul 2>&1

echo   [OK] .cursor\rules\%cmd%.mdc
goto :eof