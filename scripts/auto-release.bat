@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

echo [*] Weight Scale Plugin - Simple Release Tool
echo ==============================================

REM Check if we're in the right directory
if not exist "pubspec.yaml" (
    echo [ERROR] Not in plugin root directory
    exit /b 1
)

echo [INFO] For full automated release functionality, use Git Bash:
echo [INFO]   bash scripts/auto-release.sh
echo.
echo [INFO] This script provides basic release functionality:
echo.

REM Get current version from pubspec.yaml
for /f "tokens=2" %%a in ('findstr "^version:" pubspec.yaml') do set CURRENT_VERSION=%%a
for /f "tokens=1 delims=+" %%a in ("!CURRENT_VERSION!") do set CURRENT_VERSION=%%a

echo [INFO] Current version: !CURRENT_VERSION!
echo.

echo What would you like to do?
echo 1) Run tests and checks only
echo 2) Create a release tag (manual version)
echo 3) Open Git Bash for full auto-release
echo.

set /p choice="Enter your choice (1-3): "

if "!choice!"=="1" (
    echo [*] Running tests and checks...
    dart format .
    flutter analyze
    flutter test
    dart pub publish --dry-run
    echo [SUCCESS] All checks passed!
) else if "!choice!"=="2" (
    set /p NEW_VERSION="Enter new version (e.g., 1.0.1): "
    echo [*] You will need to manually update pubspec.yaml and CHANGELOG.md
    echo [*] Then run: git tag v!NEW_VERSION! && git push origin v!NEW_VERSION!
) else if "!choice!"=="3" (
    echo [*] Opening Git Bash...
    start "" "C:\Program Files\Git\bin\bash.exe" scripts/auto-release.sh
) else (
    echo [ERROR] Invalid choice
)

echo.
pause
