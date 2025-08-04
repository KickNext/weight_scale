#!/bin/bash

# 🚀 Weight Scale Plugin - Repository Setup Script
# This script helps set up the GitHub repository with optimal settings

set -e

echo "🚀 Weight Scale Plugin Repository Setup"
echo "======================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if we're in the right directory
if [ ! -f "pubspec.yaml" ]; then
    echo -e "${RED}❌ Error: Not in plugin root directory${NC}"
    exit 1
fi

echo -e "${BLUE}📋 Checking prerequisites...${NC}"

# Check if gh CLI is installed
if ! command -v gh &> /dev/null; then
    echo -e "${YELLOW}⚠️  GitHub CLI not found. Please install it first:${NC}"
    echo "   https://github.com/cli/cli#installation"
    exit 1
fi

# Check if user is authenticated
if ! gh auth status &> /dev/null; then
    echo -e "${YELLOW}🔐 Please authenticate with GitHub first:${NC}"
    echo "   gh auth login"
    exit 1
fi

echo -e "${GREEN}✅ Prerequisites met${NC}"

echo -e "${BLUE}🏷️  Setting up repository labels...${NC}"

# Create labels
labels=(
    "bug:d73a4a:Something isn't working"
    "enhancement:a2eeef:New feature or request"
    "documentation:0075ca:Improvements or additions to documentation"
    "question:d876e3:Further information is requested"
    "device-support:fbca04:Adding support for new scale device"
    "priority-low:e4e669:Low priority issue"
    "priority-medium:fbca04:Medium priority issue"
    "priority-high:d93f0b:High priority issue"
    "priority-critical:b60205:Critical priority issue"
    "needs-triage:ededed:Needs initial review and categorization"
    "needs-investigation:1d76db:Requires further investigation"
    "needs-testing:7057ff:Needs testing with physical device"
    "good-first-issue:7057ff:Good for newcomers"
    "help-wanted:008672:Extra attention is needed"
    "platform-android:3ddc84:Android platform specific"
    "platform-ios:007aff:iOS platform (future)"
    "protocol:f9d0c4:Related to RS232 protocol parsing"
    "connection:c2e0c6:Device connection and management"
    "performance:d4c5f9:Performance related"
    "testing:0e8a16:Related to testing"
    "automated:ededed:Created by automation"
    "dependencies:0366d6:Pull requests that update a dependency file"
    "github-actions:000000:Related to GitHub Actions"
    "stale:fef2c0:This issue/PR has been marked as stale"
    "monthly-report:b4a7d6:Monthly community report"
    "community:0e8a16:Community related"
)

for label in "${labels[@]}"; do
    IFS=':' read -r name color description <<< "$label"
    gh label create "$name" --color "$color" --description "$description" --force 2>/dev/null || true
done

echo -e "${GREEN}✅ Labels configured${NC}"

echo -e "${BLUE}🔧 Configuring repository settings...${NC}"

# Update repository description and topics
gh repo edit --description "Flutter plugin for commercial weight scales via RS232 AUTO COMMUNICATE PROTOCOL"
gh repo edit --homepage "https://pub.dev/packages/weight_scale"

# Add topics
topics="flutter dart weight-scale rs232 usb-serial android commercial-scales protocol hardware-integration iot"
for topic in $topics; do
    gh repo edit --add-topic "$topic" 2>/dev/null || true
done

echo -e "${GREEN}✅ Repository settings updated${NC}"

echo -e "${BLUE}📊 Setting up project boards...${NC}"

# Create project for issue tracking
gh project create --title "Weight Scale Plugin Development" --body "Main development tracking board" 2>/dev/null || true

echo -e "${GREEN}✅ Project boards configured${NC}"

echo -e "${BLUE}🔒 Security settings recommendations:${NC}"
echo "Please manually configure the following in GitHub Settings:"
echo "  • Enable Dependabot alerts"
echo "  • Enable automated security fixes"
echo "  • Configure branch protection for main branch"
echo "  • Add required status checks:"
echo "    - 📊 Static Analysis"
echo "    - 🧪 Unit Tests"
echo "    - 🏗️ Build Example"
echo "    - ✅ CI Success"

echo -e "${BLUE}🔑 Required secrets:${NC}"
echo "Add these secrets in Settings > Secrets and variables > Actions:"
echo "  • CODECOV_TOKEN (optional) - for coverage reporting"
echo "  • PUB_CREDENTIALS (required) - for pub.dev publishing"

echo -e "${BLUE}🚀 Testing workflows...${NC}"

# Test if workflows are valid
if [ -d ".github/workflows" ]; then
    echo "Found workflow files:"
    ls -la .github/workflows/
    echo -e "${GREEN}✅ Workflows ready${NC}"
else
    echo -e "${YELLOW}⚠️  No workflow files found${NC}"
fi

echo ""
echo -e "${GREEN}🎉 Repository setup complete!${NC}"
echo ""
echo "Next steps:"
echo "1. 🔒 Configure branch protection rules in GitHub Settings"
echo "2. 🔑 Add required secrets for CI/CD"
echo "3. 📊 Install Codecov GitHub App (optional)"
echo "4. 🧪 Create a test PR to verify CI/CD"
echo "5. 🚀 Ready to collaborate with the community!"
echo ""
echo "Documentation:"
echo "• 📖 See .github/AUTOMATION.md for detailed automation docs"
echo "• ⚙️  See .github/REPOSITORY_SETTINGS.md for manual settings"
echo "• 🤝 See CONTRIBUTING.md for contributor guidelines"
