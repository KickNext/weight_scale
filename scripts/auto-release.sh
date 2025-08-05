#!/bin/bash
# Automatic version bumping script

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 Automatic Version Bump & Release${NC}"
echo "======================================"

# Check if we're in the right directory
if [ ! -f "pubspec.yaml" ]; then
    echo -e "${RED}❌ Error: Not in plugin root directory${NC}"
    exit 1
fi

# Check if git is clean
if ! git diff-index --quiet HEAD --; then
    echo -e "${RED}⚠️  Error: You have uncommitted changes. Please commit them first.${NC}"
    git status --porcelain
    exit 1
fi

# Get current version from pubspec.yaml
CURRENT_VERSION=$(grep '^version:' pubspec.yaml | sed 's/version: //' | sed 's/+.*//')
echo -e "📋 Current version: ${YELLOW}$CURRENT_VERSION${NC}"

# Parse version parts
IFS='.' read -ra VERSION_PARTS <<< "$CURRENT_VERSION"
MAJOR=${VERSION_PARTS[0]}
MINOR=${VERSION_PARTS[1]}
PATCH=${VERSION_PARTS[2]}

echo ""
echo "What type of release do you want to create?"
echo "1) 🐛 Patch (bug fixes): $CURRENT_VERSION → $MAJOR.$MINOR.$((PATCH + 1))"
echo "2) ✨ Minor (new features): $CURRENT_VERSION → $MAJOR.$((MINOR + 1)).0"
echo "3) 💥 Major (breaking changes): $CURRENT_VERSION → $((MAJOR + 1)).0.0"
echo "4) 📝 Custom version"
echo ""

read -p "Enter your choice (1-4): " choice

case $choice in
    1)
        NEW_VERSION="$MAJOR.$MINOR.$((PATCH + 1))"
        RELEASE_TYPE="patch"
        ;;
    2)
        NEW_VERSION="$MAJOR.$((MINOR + 1)).0"
        RELEASE_TYPE="minor"
        ;;
    3)
        NEW_VERSION="$((MAJOR + 1)).0.0"
        RELEASE_TYPE="major"
        ;;
    4)
        read -p "Enter custom version (e.g., 1.2.3): " NEW_VERSION
        RELEASE_TYPE="custom"
        ;;
    *)
        echo -e "${RED}❌ Invalid choice${NC}"
        exit 1
        ;;
esac

echo -e "${GREEN}📦 New version will be: $NEW_VERSION${NC}"

# Generate automatic changelog entry
echo ""
echo "🔍 Generating changelog from recent commits..."

# Get commits since last tag
LAST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "")
if [ -z "$LAST_TAG" ]; then
    echo "📝 This appears to be the first release"
    COMMITS=$(git log --oneline --pretty=format:"- %s" HEAD~10..HEAD)
else
    echo "📋 Changes since $LAST_TAG:"
    COMMITS=$(git log --oneline --pretty=format:"- %s" $LAST_TAG..HEAD)
fi

# Create temporary changelog
TEMP_CHANGELOG=$(mktemp)
CURRENT_DATE=$(date +%Y-%m-%d)

cat > $TEMP_CHANGELOG << EOF
## [$NEW_VERSION] - $CURRENT_DATE

### Changes
$COMMITS

EOF

# Show preview
echo -e "${YELLOW}📝 Generated changelog entry:${NC}"
echo "=================================="
cat $TEMP_CHANGELOG
echo "=================================="

read -p "🤔 Do you want to proceed with this changelog? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}👍 Cancelled. You can edit CHANGELOG.md manually and run the regular publish script.${NC}"
    rm $TEMP_CHANGELOG
    exit 0
fi

# Update pubspec.yaml
echo "📦 Updating pubspec.yaml..."
sed -i.bak "s/^version: .*/version: $NEW_VERSION/" pubspec.yaml

# Update CHANGELOG.md
echo "📝 Updating CHANGELOG.md..."
if [ -f "CHANGELOG.md" ]; then
    # Backup original
    cp CHANGELOG.md CHANGELOG.md.bak
    
    # Create new CHANGELOG.md with new entry at top
    echo "# Changelog" > CHANGELOG.md.new
    echo "" >> CHANGELOG.md.new
    cat $TEMP_CHANGELOG >> CHANGELOG.md.new
    
    # Add existing changelog (skip the header)
    tail -n +3 CHANGELOG.md >> CHANGELOG.md.new 2>/dev/null || true
    
    mv CHANGELOG.md.new CHANGELOG.md
else
    # Create new CHANGELOG.md
    echo "# Changelog" > CHANGELOG.md
    echo "" >> CHANGELOG.md
    cat $TEMP_CHANGELOG >> CHANGELOG.md
fi

# Clean up
rm $TEMP_CHANGELOG

# Commit changes
echo "📤 Committing changes..."
git add pubspec.yaml CHANGELOG.md
git commit -m "chore: bump version to $NEW_VERSION

Auto-generated $RELEASE_TYPE release with changelog"

# Create and push tag
echo "🏷️  Creating tag v$NEW_VERSION..."
git tag "v$NEW_VERSION"

echo "📤 Pushing changes and tag..."
git push origin main
git push origin "v$NEW_VERSION"

echo ""
echo -e "${GREEN}🎉 Success!${NC}"
echo "=================================="
echo -e "✅ Version updated: ${YELLOW}$CURRENT_VERSION → $NEW_VERSION${NC}"
echo -e "✅ Changelog updated automatically"
echo -e "✅ Tag ${YELLOW}v$NEW_VERSION${NC} created and pushed"
echo -e "🚀 GitHub Actions will now create the release and publish to pub.dev"
echo ""
echo -e "${YELLOW}📋 Next steps:${NC}"
echo "   - Monitor GitHub Actions: https://github.com/nikitiser/weight_scale/actions"
echo "   - Check release: https://github.com/nikitiser/weight_scale/releases"
echo "   - Verify pub.dev: https://pub.dev/packages/weight_scale"
