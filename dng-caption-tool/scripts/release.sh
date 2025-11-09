#!/bin/bash
# Release script for DNG Caption Tool

set -e

echo "🚀 DNG Caption Tool Release Builder"
echo "===================================="

# Check version
VERSION=$(python -c "import src.dng_caption; print(dng_caption.__version__)")
echo "Version: $VERSION"

# Clean previous builds
rm -rf dist/ build/ *.egg-info

# Run tests
echo "Running tests..."
pytest tests/

# Check code style
echo "Checking code style..."
black --check src/
flake8 src/

# Build distribution
echo "Building distribution..."
python -m build

# Create checksums
cd dist/
shasum -a 256 * > checksums.txt
cd ..

echo "✅ Release $VERSION ready!"
echo ""
echo "Next steps:"
echo "1. git tag -a v$VERSION -m 'Release $VERSION'"
echo "2. git push origin v$VERSION"
echo "3. Upload to PyPI: twine upload dist/*"
echo "4. Create GitHub release"
echo "5. Update Homebrew formula"
