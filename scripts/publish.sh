#!/bin/bash
# Simple publication script for weight_scale Flutter plugin

set -e

echo "[*] Weight Scale Plugin Publication Script"
echo "========================================"

# Check if we're in the right directory
if [ ! -f "pubspec.yaml" ]; then
    echo "[ERROR] Not in plugin root directory"
    exit 1
fi

echo "[*] Running pre-publication checks..."

# 1. Format and analyze
echo "[*] Formatting code..."
dart format .

echo "[*] Running analyzer..."
flutter analyze

# 2. Run tests
echo "[*] Running tests..."
flutter test

# 3. Validate package
echo "[*] Validating package..."
dart pub publish --dry-run

echo ""
echo "[SUCCESS] All checks passed! Package is ready for publication."
echo ""
echo "Release Checklist:"
echo "   - [ ] Version updated in pubspec.yaml"
echo "   - [ ] CHANGELOG.md updated with new version"
echo "   - [ ] All tests passing"
echo "   - [ ] Git repository clean (no uncommitted changes)"
echo ""

# Check if git is clean
if ! git diff-index --quiet HEAD --; then
    echo "[WARNING] You have uncommitted changes"
    git status --porcelain
    echo ""
fi

read -p "Do you want to create a release tag and push? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    # Get version from pubspec.yaml
    VERSION=$(grep '^version:' pubspec.yaml | sed 's/version: //' | sed 's/+.*//')
    
    echo "[*] Creating tag v$VERSION..."
    git tag "v$VERSION"
    
    echo "[*] Pushing tag to GitHub..."
    git push origin "v$VERSION"
    
    echo "[SUCCESS] Tag created and pushed! GitHub Actions will handle the release."
    echo "Next steps:"
    echo "   - [ ] Monitor GitHub Actions for release completion"
    echo "   - [ ] Check pub.dev for package publication"
    echo "   - [ ] Verify release notes on GitHub"
else
    echo "[INFO] Publication cancelled. Run this script again when ready."
fi
