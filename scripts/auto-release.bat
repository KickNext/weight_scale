@echo off
setlocal enabledelayedexpansion

echo 🚀 Automatic Version Bump ^& Release
echo ======================================

REM Check if we're in the right directory
if not exist "pubspec.yaml" (
    echo ❌ Error: Not in plugin root directory
    exit /b 1
)

REM Check if git is clean
git diff-index --quiet HEAD >nul 2>&1
if errorlevel 1 (
    echo ⚠️  Error: You have uncommitted changes. Please commit them first.
    git status --porcelain
    exit /b 1
)

REM Get current version from pubspec.yaml
for /f "tokens=2" %%a in ('findstr "^version:" pubspec.yaml') do set CURRENT_VERSION=%%a
for /f "tokens=1 delims=+" %%a in ("!CURRENT_VERSION!") do set CURRENT_VERSION=%%a

echo 📋 Current version: !CURRENT_VERSION!

REM Parse version parts
for /f "tokens=1,2,3 delims=." %%a in ("!CURRENT_VERSION!") do (
    set MAJOR=%%a
    set MINOR=%%b
    set PATCH=%%c
)

set /a PATCH_NEW=!PATCH!+1
set /a MINOR_NEW=!MINOR!+1
set /a MAJOR_NEW=!MAJOR!+1

echo.
echo What type of release do you want to create?
echo 1^) 🐛 Patch ^(bug fixes^): !CURRENT_VERSION! → !MAJOR!.!MINOR!.!PATCH_NEW!
echo 2^) ✨ Minor ^(new features^): !CURRENT_VERSION! → !MAJOR!.!MINOR_NEW!.0
echo 3^) 💥 Major ^(breaking changes^): !CURRENT_VERSION! → !MAJOR_NEW!.0.0
echo 4^) 📝 Custom version
echo.

set /p choice="Enter your choice (1-4): "

if "!choice!"=="1" (
    set NEW_VERSION=!MAJOR!.!MINOR!.!PATCH_NEW!
    set RELEASE_TYPE=patch
) else if "!choice!"=="2" (
    set NEW_VERSION=!MAJOR!.!MINOR_NEW!.0
    set RELEASE_TYPE=minor
) else if "!choice!"=="3" (
    set NEW_VERSION=!MAJOR_NEW!.0.0
    set RELEASE_TYPE=major
) else if "!choice!"=="4" (
    set /p NEW_VERSION="Enter custom version (e.g., 1.2.3): "
    set RELEASE_TYPE=custom
) else (
    echo ❌ Invalid choice
    exit /b 1
)

echo 📦 New version will be: !NEW_VERSION!

echo.
echo 🔍 Generating changelog from recent commits...

REM Generate changelog entry
for /f %%i in ('git describe --tags --abbrev=0 2^>nul') do set LAST_TAG=%%i
if "!LAST_TAG!"=="" (
    echo 📝 This appears to be the first release
    git log --oneline --pretty=format:"- %%s" HEAD~10..HEAD > temp_commits.txt
) else (
    echo 📋 Changes since !LAST_TAG!:
    git log --oneline --pretty=format:"- %%s" !LAST_TAG!..HEAD > temp_commits.txt
)

REM Create changelog entry
for /f "tokens=1-3 delims=/ " %%a in ('date /t') do set CURRENT_DATE=%%c-%%a-%%b
for /f "tokens=1-3 delims=." %%a in ("!CURRENT_DATE!") do set CURRENT_DATE=%%c-%%a-%%b

echo ## [!NEW_VERSION!] - !CURRENT_DATE! > temp_changelog.txt
echo. >> temp_changelog.txt
echo ### Changes >> temp_changelog.txt
type temp_commits.txt >> temp_changelog.txt
echo. >> temp_changelog.txt

echo 📝 Generated changelog entry:
echo ==================================
type temp_changelog.txt
echo ==================================

set /p proceed="🤔 Do you want to proceed with this changelog? (y/N): "
if /i not "!proceed!"=="y" (
    echo 👍 Cancelled. You can edit CHANGELOG.md manually and run the regular publish script.
    del temp_commits.txt temp_changelog.txt
    exit /b 0
)

REM Update pubspec.yaml
echo 📦 Updating pubspec.yaml...
powershell -Command "(Get-Content pubspec.yaml) -replace '^version: .*', 'version: !NEW_VERSION!' | Set-Content pubspec.yaml"

REM Update CHANGELOG.md
echo 📝 Updating CHANGELOG.md...
if exist "CHANGELOG.md" (
    copy CHANGELOG.md CHANGELOG.md.bak >nul
    echo # Changelog > CHANGELOG.md.new
    echo. >> CHANGELOG.md.new
    type temp_changelog.txt >> CHANGELOG.md.new
    more +2 CHANGELOG.md >> CHANGELOG.md.new 2>nul
    move CHANGELOG.md.new CHANGELOG.md >nul
) else (
    echo # Changelog > CHANGELOG.md
    echo. >> CHANGELOG.md
    type temp_changelog.txt >> CHANGELOG.md
)

REM Clean up
del temp_commits.txt temp_changelog.txt

REM Commit changes
echo 📤 Committing changes...
git add pubspec.yaml CHANGELOG.md
git commit -m "chore: bump version to !NEW_VERSION!" -m "Auto-generated !RELEASE_TYPE! release with changelog"

REM Create and push tag
echo 🏷️  Creating tag v!NEW_VERSION!...
git tag "v!NEW_VERSION!"

echo 📤 Pushing changes and tag...
git push origin main
git push origin "v!NEW_VERSION!"

echo.
echo 🎉 Success!
echo ==================================
echo ✅ Version updated: !CURRENT_VERSION! → !NEW_VERSION!
echo ✅ Changelog updated automatically
echo ✅ Tag v!NEW_VERSION! created and pushed
echo 🚀 GitHub Actions will now create the release and publish to pub.dev
echo.
echo 📋 Next steps:
echo    - Monitor GitHub Actions: https://github.com/nikitiser/weight_scale/actions
echo    - Check release: https://github.com/nikitiser/weight_scale/releases
echo    - Verify pub.dev: https://pub.dev/packages/weight_scale

pause
