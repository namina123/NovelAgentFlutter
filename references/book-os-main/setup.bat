@echo off
setlocal enabledelayedexpansion

REM Novel-OS Setup Script for Windows
REM This script installs Novel-OS files to your system

REM Initialize flags
set OVERWRITE_INSTRUCTIONS=false
set OVERWRITE_STANDARDS=false

REM Parse command line arguments
:parse_args
if "%~1"=="" goto start_setup
if "%~1"=="--overwrite-instructions" (
    set OVERWRITE_INSTRUCTIONS=true
    shift
    goto parse_args
)
if "%~1"=="--overwrite-standards" (
    set OVERWRITE_STANDARDS=true
    shift
    goto parse_args
)
if "%~1"=="-h" goto show_help
if "%~1"=="--help" goto show_help
echo Unknown option: %~1
echo Use --help for usage information
exit /b 1

:show_help
echo Usage: %~nx0 [OPTIONS]
echo.
echo Options:
echo   --overwrite-instructions    Overwrite existing instruction files
echo   --overwrite-standards       Overwrite existing standards files
echo   -h, --help                  Show this help message
echo.
exit /b 0

:start_setup
echo [INFO] Novel-OS Setup Script for Windows
echo ====================================
echo.

REM Base URL for raw GitHub content
set BASE_URL=https://raw.githubusercontent.com/forsonny/book-os/main

REM Create directories
echo [INFO] Creating directories...
if not exist "%USERPROFILE%\.novel-os\standards" mkdir "%USERPROFILE%\.novel-os\standards"
if not exist "%USERPROFILE%\.novel-os\standards\writing-style" mkdir "%USERPROFILE%\.novel-os\standards\writing-style"
if not exist "%USERPROFILE%\.novel-os\standards\genre-guides" mkdir "%USERPROFILE%\.novel-os\standards\genre-guides"
if not exist "%USERPROFILE%\.novel-os\instructions" mkdir "%USERPROFILE%\.novel-os\instructions"
if not exist "%USERPROFILE%\.novel-os\instructions\core" mkdir "%USERPROFILE%\.novel-os\instructions\core"
if not exist "%USERPROFILE%\.novel-os\instructions\meta" mkdir "%USERPROFILE%\.novel-os\instructions\meta"

REM Download standards files
echo.
echo [INFO] Downloading writing standards files to %USERPROFILE%\.novel-os\standards\

REM writing-style.md
if exist "%USERPROFILE%\.novel-os\standards\writing-style.md" if "%OVERWRITE_STANDARDS%"=="false" (
    echo   [WARN]  %USERPROFILE%\.novel-os\standards\writing-style.md already exists - skipping
) else (
    curl -s -o "%USERPROFILE%\.novel-os\standards\writing-style.md" "%BASE_URL%/standards/writing-style.md"
    if "%OVERWRITE_STANDARDS%"=="true" (
        echo   [OK] %USERPROFILE%\.novel-os\standards\writing-style.md ^(overwritten^)
    ) else (
        echo   [OK] %USERPROFILE%\.novel-os\standards\writing-style.md
    )
)

REM narrative-techniques.md
if exist "%USERPROFILE%\.novel-os\standards\narrative-techniques.md" if "%OVERWRITE_STANDARDS%"=="false" (
    echo   [WARN]  %USERPROFILE%\.novel-os\standards\narrative-techniques.md already exists - skipping
) else (
    curl -s -o "%USERPROFILE%\.novel-os\standards\narrative-techniques.md" "%BASE_URL%/standards/narrative-techniques.md"
    if "%OVERWRITE_STANDARDS%"=="true" (
        echo   [OK] %USERPROFILE%\.novel-os\standards\narrative-techniques.md ^(overwritten^)
    ) else (
        echo   [OK] %USERPROFILE%\.novel-os\standards\narrative-techniques.md
    )
)

REM Download writing-style subdirectory files
echo.
echo [INFO] Downloading writing style files to %USERPROFILE%\.novel-os\standards\writing-style\

REM description-style.md
if exist "%USERPROFILE%\.novel-os\standards\writing-style\description-style.md" if "%OVERWRITE_STANDARDS%"=="false" (
    echo   [WARN]  %USERPROFILE%\.novel-os\standards\writing-style\description-style.md already exists - skipping
) else (
    curl -s -o "%USERPROFILE%\.novel-os\standards\writing-style\description-style.md" "%BASE_URL%/standards/writing-style/description-style.md"
    if "%OVERWRITE_STANDARDS%"=="true" (
        echo   [OK] %USERPROFILE%\.novel-os\standards\writing-style\description-style.md ^(overwritten^)
    ) else (
        echo   [OK] %USERPROFILE%\.novel-os\standards\writing-style\description-style.md
    )
)

REM Download genre-guides subdirectory files
echo.
echo [INFO] Downloading genre guide files to %USERPROFILE%\.novel-os\standards\genre-guides\

REM literary-fiction.md
if exist "%USERPROFILE%\.novel-os\standards\genre-guides\literary-fiction.md" if "%OVERWRITE_STANDARDS%"=="false" (
    echo   [WARN]  %USERPROFILE%\.novel-os\standards\genre-guides\literary-fiction.md already exists - skipping
) else (
    curl -s -o "%USERPROFILE%\.novel-os\standards\genre-guides\literary-fiction.md" "%BASE_URL%/standards/genre-guides/literary-fiction.md"
    if "%OVERWRITE_STANDARDS%"=="true" (
        echo   [OK] %USERPROFILE%\.novel-os\standards\genre-guides\literary-fiction.md ^(overwritten^)
    ) else (
        echo   [OK] %USERPROFILE%\.novel-os\standards\genre-guides\literary-fiction.md
    )
)

REM mystery-thriller.md
if exist "%USERPROFILE%\.novel-os\standards\genre-guides\mystery-thriller.md" if "%OVERWRITE_STANDARDS%"=="false" (
    echo   [WARN]  %USERPROFILE%\.novel-os\standards\genre-guides\mystery-thriller.md already exists - skipping
) else (
    curl -s -o "%USERPROFILE%\.novel-os\standards\genre-guides\mystery-thriller.md" "%BASE_URL%/standards/genre-guides/mystery-thriller.md"
    if "%OVERWRITE_STANDARDS%"=="true" (
        echo   [OK] %USERPROFILE%\.novel-os\standards\genre-guides\mystery-thriller.md ^(overwritten^)
    ) else (
        echo   [OK] %USERPROFILE%\.novel-os\standards\genre-guides\mystery-thriller.md
    )
)

REM fantasy-sci-fi.md
if exist "%USERPROFILE%\.novel-os\standards\genre-guides\fantasy-sci-fi.md" if "%OVERWRITE_STANDARDS%"=="false" (
    echo   [WARN]  %USERPROFILE%\.novel-os\standards\genre-guides\fantasy-sci-fi.md already exists - skipping
) else (
    curl -s -o "%USERPROFILE%\.novel-os\standards\genre-guides\fantasy-sci-fi.md" "%BASE_URL%/standards/genre-guides/fantasy-sci-fi.md"
    if "%OVERWRITE_STANDARDS%"=="true" (
        echo   [OK] %USERPROFILE%\.novel-os\standards\genre-guides\fantasy-sci-fi.md ^(overwritten^)
    ) else (
        echo   [OK] %USERPROFILE%\.novel-os\standards\genre-guides\fantasy-sci-fi.md
    )
)

REM Download instruction files
echo.
echo [INFO] Downloading instruction files to %USERPROFILE%\.novel-os\instructions\

REM Core instruction files
echo   [INFO] Core instructions:

REM plan-novel.md
if exist "%USERPROFILE%\.novel-os\instructions\core\plan-novel.md" if "%OVERWRITE_INSTRUCTIONS%"=="false" (
    echo     [WARN]  %USERPROFILE%\.novel-os\instructions\core\plan-novel.md already exists - skipping
) else (
    curl -s -o "%USERPROFILE%\.novel-os\instructions\core\plan-novel.md" "%BASE_URL%/instructions/core/plan-novel.md"
    if "%OVERWRITE_INSTRUCTIONS%"=="true" (
        echo     [OK] %USERPROFILE%\.novel-os\instructions\core\plan-novel.md ^(overwritten^)
    ) else (
        echo     [OK] %USERPROFILE%\.novel-os\instructions\core\plan-novel.md
    )
)

REM create-outline.md
if exist "%USERPROFILE%\.novel-os\instructions\core\create-outline.md" if "%OVERWRITE_INSTRUCTIONS%"=="false" (
    echo     [WARN]  %USERPROFILE%\.novel-os\instructions\core\create-outline.md already exists - skipping
) else (
    curl -s -o "%USERPROFILE%\.novel-os\instructions\core\create-outline.md" "%BASE_URL%/instructions/core/create-outline.md"
    if "%OVERWRITE_INSTRUCTIONS%"=="true" (
        echo     [OK] %USERPROFILE%\.novel-os\instructions\core\create-outline.md ^(overwritten^)
    ) else (
        echo     [OK] %USERPROFILE%\.novel-os\instructions\core\create-outline.md
    )
)

REM write-scenes.md
if exist "%USERPROFILE%\.novel-os\instructions\core\write-scenes.md" if "%OVERWRITE_INSTRUCTIONS%"=="false" (
    echo     [WARN]  %USERPROFILE%\.novel-os\instructions\core\write-scenes.md already exists - skipping
) else (
    curl -s -o "%USERPROFILE%\.novel-os\instructions\core\write-scenes.md" "%BASE_URL%/instructions/core/write-scenes.md"
    if "%OVERWRITE_INSTRUCTIONS%"=="true" (
        echo     [OK] %USERPROFILE%\.novel-os\instructions\core\write-scenes.md ^(overwritten^)
    ) else (
        echo     [OK] %USERPROFILE%\.novel-os\instructions\core\write-scenes.md
    )
)

REM write-scene.md
if exist "%USERPROFILE%\.novel-os\instructions\core\write-scene.md" if "%OVERWRITE_INSTRUCTIONS%"=="false" (
    echo     [WARN]  %USERPROFILE%\.novel-os\instructions\core\write-scene.md already exists - skipping
) else (
    curl -s -o "%USERPROFILE%\.novel-os\instructions\core\write-scene.md" "%BASE_URL%/instructions/core/write-scene.md"
    if "%OVERWRITE_INSTRUCTIONS%"=="true" (
        echo     [OK] %USERPROFILE%\.novel-os\instructions\core\write-scene.md ^(overwritten^)
    ) else (
        echo     [OK] %USERPROFILE%\.novel-os\instructions\core\write-scene.md
    )
)

REM analyze-manuscript.md
if exist "%USERPROFILE%\.novel-os\instructions\core\analyze-manuscript.md" if "%OVERWRITE_INSTRUCTIONS%"=="false" (
    echo     [WARN]  %USERPROFILE%\.novel-os\instructions\core\analyze-manuscript.md already exists - skipping
) else (
    curl -s -o "%USERPROFILE%\.novel-os\instructions\core\analyze-manuscript.md" "%BASE_URL%/instructions/core/analyze-manuscript.md"
    if "%OVERWRITE_INSTRUCTIONS%"=="true" (
        echo     [OK] %USERPROFILE%\.novel-os\instructions\core\analyze-manuscript.md ^(overwritten^)
    ) else (
        echo     [OK] %USERPROFILE%\.novel-os\instructions\core\analyze-manuscript.md
    )
)

REM Meta instruction files
echo.
echo   [INFO] Meta instructions:

REM pre-flight.md
if exist "%USERPROFILE%\.novel-os\instructions\meta\pre-flight.md" if "%OVERWRITE_INSTRUCTIONS%"=="false" (
    echo     [WARN]  %USERPROFILE%\.novel-os\instructions\meta\pre-flight.md already exists - skipping
) else (
    curl -s -o "%USERPROFILE%\.novel-os\instructions\meta\pre-flight.md" "%BASE_URL%/instructions/meta/pre-flight.md"
    if "%OVERWRITE_INSTRUCTIONS%"=="true" (
        echo     [OK] %USERPROFILE%\.novel-os\instructions\meta\pre-flight.md ^(overwritten^)
    ) else (
        echo     [OK] %USERPROFILE%\.novel-os\instructions\meta\pre-flight.md
    )
)

echo.
echo [OK] Novel-OS base installation complete!
echo.
echo [INFO] Files installed to:
echo    %USERPROFILE%\.novel-os\standards\     - Your writing standards
echo    %USERPROFILE%\.novel-os\instructions\  - Novel-OS instructions
echo.
if "%OVERWRITE_INSTRUCTIONS%"=="false" if "%OVERWRITE_STANDARDS%"=="false" (
    echo [INFO] Note: Existing files were skipped to preserve your customizations
    echo    Use --overwrite-instructions or --overwrite-standards to update specific files
) else (
    echo [INFO] Note: Some files were overwritten based on your flags
    if "%OVERWRITE_INSTRUCTIONS%"=="false" (
        echo    Existing instruction files were preserved
    )
    if "%OVERWRITE_STANDARDS%"=="false" (
        echo    Existing standards files were preserved
    )
)
echo.
echo Next steps:
echo.
echo 1. Customize your writing standards in %USERPROFILE%\.novel-os\standards\
echo.
echo 2. Install commands for your AI writing assistant^(s^):
echo.
echo    - Using Claude Code? Run the Windows setup batch file:
echo      setup-claude-code.bat
echo.
echo    - Using Cursor? Run the Windows setup batch file:
echo      setup-cursor.bat
echo.
echo    - Using something else? See instructions in the Novel-OS README
echo.
echo Learn more about Novel-OS for AI-assisted novel writing!
echo.