@echo off
REM 🚀 Weight Scale Plugin - Repository Setup Script (Windows)
REM This script helps set up the GitHub repository with optimal settings

echo 🚀 Weight Scale Plugin Repository Setup
echo ======================================

REM Check if we're in the right directory
if not exist "pubspec.yaml" (
    echo ❌ Error: Not in plugin root directory
    exit /b 1
)

echo 📋 Checking prerequisites...

REM Check if gh CLI is installed
gh --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ⚠️  GitHub CLI not found. Please install it first:
    echo    https://github.com/cli/cli#installation
    exit /b 1
)

REM Check if user is authenticated
gh auth status >nul 2>&1
if %errorlevel% neq 0 (
    echo 🔐 Please authenticate with GitHub first:
    echo    gh auth login
    exit /b 1
)

echo ✅ Prerequisites met

echo 🏷️  Setting up repository labels...

REM Create essential labels
gh label create "bug" --color "d73a4a" --description "Something isn't working" --force >nul 2>&1
gh label create "enhancement" --color "a2eeef" --description "New feature or request" --force >nul 2>&1
gh label create "documentation" --color "0075ca" --description "Improvements or additions to documentation" --force >nul 2>&1
gh label create "question" --color "d876e3" --description "Further information is requested" --force >nul 2>&1
gh label create "device-support" --color "fbca04" --description "Adding support for new scale device" --force >nul 2>&1
gh label create "priority-high" --color "d93f0b" --description "High priority issue" --force >nul 2>&1
gh label create "priority-critical" --color "b60205" --description "Critical priority issue" --force >nul 2>&1
gh label create "needs-triage" --color "ededed" --description "Needs initial review and categorization" --force >nul 2>&1
gh label create "good-first-issue" --color "7057ff" --description "Good for newcomers" --force >nul 2>&1
gh label create "help-wanted" --color "008672" --description "Extra attention is needed" --force >nul 2>&1
gh label create "platform-android" --color "3ddc84" --description "Android platform specific" --force >nul 2>&1
gh label create "automated" --color "ededed" --description "Created by automation" --force >nul 2>&1
gh label create "dependencies" --color "0366d6" --description "Pull requests that update a dependency file" --force >nul 2>&1

echo ✅ Labels configured

echo 🔧 Configuring repository settings...

REM Update repository description and homepage
gh repo edit --description "Flutter plugin for commercial weight scales via RS232 AUTO COMMUNICATE PROTOCOL"
gh repo edit --homepage "https://pub.dev/packages/weight_scale"

REM Add topics
gh repo edit --add-topic "flutter" >nul 2>&1
gh repo edit --add-topic "dart" >nul 2>&1
gh repo edit --add-topic "weight-scale" >nul 2>&1
gh repo edit --add-topic "rs232" >nul 2>&1
gh repo edit --add-topic "usb-serial" >nul 2>&1
gh repo edit --add-topic "android" >nul 2>&1
gh repo edit --add-topic "commercial-scales" >nul 2>&1
gh repo edit --add-topic "protocol" >nul 2>&1
gh repo edit --add-topic "hardware-integration" >nul 2>&1
gh repo edit --add-topic "iot" >nul 2>&1

echo ✅ Repository settings updated

echo 🚀 Testing workflows...

REM Check if workflows exist
if exist ".github\workflows" (
    echo Found workflow files:
    dir .github\workflows
    echo ✅ Workflows ready
) else (
    echo ⚠️  No workflow files found
)

echo.
echo 🎉 Repository setup complete!
echo.
echo Next steps:
echo 1. 🔒 Configure branch protection rules in GitHub Settings
echo 2. 🔑 Add required secrets for CI/CD:
echo    • CODECOV_TOKEN (optional) - for coverage reporting
echo    • PUB_CREDENTIALS (required) - for pub.dev publishing
echo 3. 📊 Install Codecov GitHub App (optional)
echo 4. 🧪 Create a test PR to verify CI/CD
echo 5. 🚀 Ready to collaborate with the community!
echo.
echo Documentation:
echo • 📖 See .github/AUTOMATION.md for detailed automation docs
echo • ⚙️  See .github/REPOSITORY_SETTINGS.md for manual settings
echo • 🤝 See CONTRIBUTING.md for contributor guidelines

pause
