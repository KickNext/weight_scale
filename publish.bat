@echo off
REM Publication script for weight_scale Flutter plugin (Windows)

echo 🚀 Weight Scale Plugin Publication Script
echo ========================================

REM Check if we're in the right directory
if not exist "pubspec.yaml" (
    echo ❌ Error: Not in plugin root directory
    exit /b 1
)

echo 📋 Running pre-publication checks...

REM 1. Format code
echo 🎨 Formatting code...
flutter format .

REM 2. Run analyzer
echo 🔍 Running analyzer...
flutter analyze

REM 3. Run tests
echo 🧪 Running tests...
flutter test

REM 4. Run integration tests
echo 🔗 Running integration tests...
cd example
flutter test integration_test/
cd ..

REM 5. Validate package
echo 📦 Validating package...
flutter packages pub publish --dry-run

echo.
echo ✅ All checks passed! Package is ready for publication.
echo.
echo 📋 Final checklist:
echo    - [ ] Version updated in pubspec.yaml
echo    - [ ] CHANGELOG.md updated
echo    - [ ] All tests passing
echo    - [ ] Documentation complete
echo    - [ ] Git repository clean
echo.

set /p "publish=🤔 Do you want to publish now? (y/N): "
if /I "%publish%"=="y" (
    echo 🚀 Publishing to pub.dev...
    flutter packages pub publish
    echo 🎉 Successfully published!
    echo.
    echo 📋 Post-publication tasks:
    echo    - [ ] Create GitHub release
    echo    - [ ] Update README badges
    echo    - [ ] Announce on social media
    echo    - [ ] Monitor pub.dev for issues
) else (
    echo 👍 Publication cancelled. Run this script again when ready.
)
