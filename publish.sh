#!/bin/bash
# Publication script for weight_scale Flutter plugin

set -e

echo "🚀 Weight Scale Plugin Publication Script"
echo "========================================"

# Check if we're in the right directory
if [ ! -f "pubspec.yaml" ]; then
    echo "❌ Error: Not in plugin root directory"
    exit 1
fi

echo "📋 Running pre-publication checks..."

# 1. Format code
echo "🎨 Formatting code..."
flutter format .

# 2. Run analyzer
echo "🔍 Running analyzer..."
flutter analyze

# 3. Run tests
echo "🧪 Running tests..."
flutter test

# 4. Run integration tests
echo "🔗 Running integration tests..."
cd example
flutter test integration_test/
cd ..

# 5. Validate package
echo "📦 Validating package..."
flutter packages pub publish --dry-run

echo ""
echo "✅ All checks passed! Package is ready for publication."
echo ""
echo "📋 Final checklist:"
echo "   - [ ] Version updated in pubspec.yaml"
echo "   - [ ] CHANGELOG.md updated"
echo "   - [ ] All tests passing"
echo "   - [ ] Documentation complete"
echo "   - [ ] Git repository clean"
echo ""

read -p "🤔 Do you want to publish now? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "🚀 Publishing to pub.dev..."
    flutter packages pub publish
    echo "🎉 Successfully published!"
    echo ""
    echo "📋 Post-publication tasks:"
    echo "   - [ ] Create GitHub release"
    echo "   - [ ] Update README badges"
    echo "   - [ ] Announce on social media"
    echo "   - [ ] Monitor pub.dev for issues"
else
    echo "👍 Publication cancelled. Run this script again when ready."
fi
