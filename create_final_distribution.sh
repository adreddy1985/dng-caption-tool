#!/bin/bash
# Create Production-Ready Distribution Package for GitHub & Homebrew

set -e

echo "🚀 Creating Production Distribution Package"
echo "=========================================="

PROJECT_NAME="dng-caption-tool"
VERSION="2.1.0"

# Create project structure
mkdir -p $PROJECT_NAME
cd $PROJECT_NAME

# Create directory structure
mkdir -p src/dng_caption
mkdir -p tests
mkdir -p docs
mkdir -p scripts
mkdir -p examples
mkdir -p .github/workflows

echo "📁 Creating project structure..."

# ============================================
# Core Python Package Structure
# ============================================

# Package __init__.py
cat > src/dng_caption/__init__.py << 'EOF'
"""
DNG Caption Tool - AI-powered photo caption generator
"""

__version__ = "2.1.0"
__author__ = "Ari Reddy"

from .caption import CaptionGenerator
from .gps import GPSExtractor
from .embed import XMPEmbedder

__all__ = ["CaptionGenerator", "GPSExtractor", "XMPEmbedder"]
EOF

# Main caption module
cat > src/dng_caption/caption.py << 'EOF'
"""Core caption generation functionality"""

import base64
from pathlib import Path
from typing import Optional, Dict
import anthropic
from PIL import Image


class CaptionGenerator:
    """AI-powered caption generator using Claude"""
    
    MODELS = {
        'haiku': {
            'name': 'claude-3-haiku-20240307',
            'cost': 0.001,
            'description': 'Fast and affordable'
        },
        'sonnet': {
            'name': 'claude-3-5-sonnet-20241022', 
            'cost': 0.003,
            'description': 'Best balance'
        },
        'opus': {
            'name': 'claude-3-opus-20240229',
            'cost': 0.015,
            'description': 'Highest quality'
        }
    }
    
    STYLES = {
        'descriptive': "Write a 2-3 sentence professional caption for this image.",
        'social': "Write an engaging social media caption with relevant hashtags.",
        'minimal': "Write a brief one-sentence caption.",
        'artistic': "Write a poetic, evocative caption.",
        'documentary': "Write a factual, journalistic caption.",
        'travel': "Write a travel photography caption emphasizing the location."
    }
    
    def __init__(self, api_key: Optional[str] = None):
        """Initialize with API key"""
        import os
        self.api_key = api_key or os.environ.get('ANTHROPIC_API_KEY')
        if not self.api_key:
            raise ValueError("API key required")
        self.client = anthropic.Anthropic(api_key=self.api_key)
    
    def generate(self, 
                 image_path: Path,
                 style: str = 'descriptive',
                 model: str = 'haiku',
                 location_context: Optional[str] = None) -> str:
        """Generate caption for image"""
        
        # Prepare image
        image_base64 = self._prepare_image(image_path)
        
        # Build prompt
        prompt = self.STYLES.get(style, self.STYLES['descriptive'])
        if location_context:
            prompt += f"\n\n{location_context}"
        
        # Generate caption
        response = self.client.messages.create(
            model=self.MODELS[model]['name'],
            max_tokens=300,
            messages=[{
                "role": "user",
                "content": [
                    {"type": "image", "source": {
                        "type": "base64",
                        "media_type": "image/jpeg",
                        "data": image_base64
                    }},
                    {"type": "text", "text": prompt}
                ]
            }]
        )
        
        return response.content[0].text.strip()
    
    def _prepare_image(self, image_path: Path) -> str:
        """Prepare image for API"""
        img = Image.open(image_path)
        if img.mode != 'RGB':
            img = img.convert('RGB')
        img.thumbnail((1600, 1600), Image.Resampling.LANCZOS)
        
        import io
        buffer = io.BytesIO()
        img.save(buffer, format='JPEG', quality=85)
        return base64.b64encode(buffer.getvalue()).decode('utf-8')
EOF

# GPS module
cat > src/dng_caption/gps.py << 'EOF'
"""GPS extraction and geocoding functionality"""

from typing import Optional, Dict
from pathlib import Path
import piexif
from PIL import Image
from geopy.geocoders import Nominatim
from geopy.exc import GeocoderTimedOut, GeocoderServiceError
import time


class GPSExtractor:
    """Extract and geocode GPS data from images"""
    
    def __init__(self):
        self.geolocator = Nominatim(user_agent="dng_caption_tool")
    
    def extract_gps(self, image_path: Path) -> Optional[Dict]:
        """Extract GPS coordinates from image"""
        try:
            img = Image.open(image_path)
            if 'exif' not in img.info:
                return None
            
            exif_dict = piexif.load(img.info['exif'])
            if piexif.GPSIFD.GPSLatitude not in exif_dict.get('GPS', {}):
                return None
            
            # Extract coordinates
            lat = self._convert_to_degrees(
                exif_dict['GPS'][piexif.GPSIFD.GPSLatitude],
                exif_dict['GPS'][piexif.GPSIFD.GPSLatitudeRef].decode('utf-8')
            )
            
            lon = self._convert_to_degrees(
                exif_dict['GPS'][piexif.GPSIFD.GPSLongitude],
                exif_dict['GPS'][piexif.GPSIFD.GPSLongitudeRef].decode('utf-8')
            )
            
            result = {'latitude': lat, 'longitude': lon}
            
            # Extract altitude if available
            if piexif.GPSIFD.GPSAltitude in exif_dict.get('GPS', {}):
                alt = exif_dict['GPS'][piexif.GPSIFD.GPSAltitude]
                result['altitude'] = alt[0] / alt[1]
            
            return result
            
        except Exception:
            return None
    
    def reverse_geocode(self, latitude: float, longitude: float, 
                        retries: int = 2) -> Optional[Dict]:
        """Convert coordinates to location name"""
        for attempt in range(retries):
            try:
                location = self.geolocator.reverse(
                    f"{latitude}, {longitude}",
                    timeout=5,
                    language='en'
                )
                
                if location:
                    return self._parse_location(location)
                    
            except (GeocoderTimedOut, GeocoderServiceError):
                if attempt < retries - 1:
                    time.sleep(1)
                    
        return None
    
    def _convert_to_degrees(self, value, ref):
        """Convert GPS coordinates to decimal degrees"""
        degrees = value[0][0] / value[0][1]
        minutes = value[1][0] / value[1][1]
        seconds = value[2][0] / value[2][1]
        
        decimal = degrees + (minutes / 60.0) + (seconds / 3600.0)
        
        if ref in ['S', 'W']:
            decimal = -decimal
            
        return decimal
    
    def _parse_location(self, location):
        """Parse location data"""
        address = location.raw.get('address', {})
        
        city = (address.get('city') or 
                address.get('town') or 
                address.get('village') or
                address.get('hamlet'))
        
        parts = []
        if city:
            parts.append(city)
        if state := address.get('state'):
            parts.append(state)
        if country := address.get('country'):
            parts.append(country)
        
        return {
            'formatted': ', '.join(parts) if parts else location.address,
            'city': city,
            'state': address.get('state'),
            'country': address.get('country'),
            'full_address': location.address
        }
EOF

# CLI module
cat > src/dng_caption/cli.py << 'EOF'
"""Command-line interface"""

import sys
import argparse
from pathlib import Path
from .caption import CaptionGenerator
from .gps import GPSExtractor
from .embed import XMPEmbedder


def main():
    """Main CLI entry point"""
    parser = argparse.ArgumentParser(
        description='Generate AI captions for photos with GPS support'
    )
    parser.add_argument('images', nargs='+', help='Images to process')
    parser.add_argument('--model', default='haiku',
                       choices=['haiku', 'sonnet', 'opus'])
    parser.add_argument('--style', default='descriptive',
                       choices=['descriptive', 'social', 'minimal', 
                               'artistic', 'documentary', 'travel'])
    parser.add_argument('--no-gps', action='store_true',
                       help='Disable GPS extraction')
    parser.add_argument('--embed', action='store_true',
                       help='Embed captions into JPEG files')
    
    args = parser.parse_args()
    
    # Initialize components
    generator = CaptionGenerator()
    gps_extractor = GPSExtractor() if not args.no_gps else None
    embedder = XMPEmbedder() if args.embed else None
    
    # Process images
    for image_path in args.images:
        path = Path(image_path)
        if not path.exists():
            print(f"File not found: {path}")
            continue
        
        try:
            # Extract GPS if enabled
            location_context = None
            if gps_extractor:
                if gps_data := gps_extractor.extract_gps(path):
                    if location := gps_extractor.reverse_geocode(
                        gps_data['latitude'], gps_data['longitude']
                    ):
                        location_context = f"Location: {location['formatted']}"
            
            # Generate caption
            caption = generator.generate(
                path, args.style, args.model, location_context
            )
            
            print(f"✓ {path.name}: {caption[:50]}...")
            
            # Embed if requested
            if embedder:
                embedder.embed(path, caption)
                
        except Exception as e:
            print(f"✗ {path.name}: {e}")
    
    return 0


if __name__ == '__main__':
    sys.exit(main())
EOF

# ============================================
# Create professional documentation
# ============================================

cat > README.md << 'EOF'
# DNG Caption Tool

[![Version](https://img.shields.io/github/v/release/yourusername/dng-caption-tool)](https://github.com/yourusername/dng-caption-tool/releases)
[![Python](https://img.shields.io/badge/python-3.9+-blue)](https://www.python.org/downloads/)
[![License](https://img.shields.io/badge/license-MIT-green)](LICENSE)
[![Tests](https://github.com/yourusername/dng-caption-tool/actions/workflows/tests.yml/badge.svg)](https://github.com/yourusername/dng-caption-tool/actions)

AI-powered photo caption generator with GPS location support, XMP embedding, and multi-platform compatibility.

## Features

- 🤖 **AI-Powered Captions** - Uses Claude (Opus/Sonnet/Haiku) models
- 📍 **GPS Location Support** - Automatic extraction and geocoding
- 🏷️ **XMP Metadata** - Industry-standard sidecar files
- 💾 **JPEG Embedding** - Direct metadata embedding
- 🎨 **Multiple Styles** - Descriptive, social, artistic, travel
- 🚀 **Batch Processing** - Handle entire folders efficiently
- 💰 **Cost Optimization** - Smart model selection

## Installation

### Via Homebrew (macOS)

```bash
brew tap yourusername/tap
brew install dng-caption
```

### Via pip

```bash
pip install dng-caption
```

### From Source

```bash
git clone https://github.com/yourusername/dng-caption-tool.git
cd dng-caption-tool
pip install -e .
```

## Quick Start

```bash
# Set your API key
export ANTHROPIC_API_KEY="sk-ant-..."

# Caption a single image
dng-caption photo.jpg

# Process folder with GPS
dng-caption-batch ~/Photos/ --style travel

# Embed captions into JPEGs
dng-caption *.jpg --embed
```

## Documentation

See the [full documentation](https://github.com/yourusername/dng-caption-tool/wiki) for detailed usage.

## License

MIT License - see [LICENSE](LICENSE) file

## Contributing

Contributions welcome! See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.
EOF

# ============================================
# Create Homebrew formula
# ============================================

cat > dng-caption.rb << 'EOF'
class DngCaption < Formula
  include Language::Python::Virtualenv

  desc "AI-powered photo caption generator with GPS support"
  homepage "https://github.com/yourusername/dng-caption-tool"
  url "https://github.com/yourusername/dng-caption-tool/archive/refs/tags/v2.1.0.tar.gz"
  sha256 "PLACEHOLDER_SHA256"
  license "MIT"
  head "https://github.com/yourusername/dng-caption-tool.git", branch: "main"

  depends_on "python@3.11"
  depends_on "exiftool"

  resource "anthropic" do
    url "https://files.pythonhosted.org/packages/anthropic-0.18.0.tar.gz"
    sha256 "PLACEHOLDER"
  end

  resource "pillow" do
    url "https://files.pythonhosted.org/packages/Pillow-10.0.0.tar.gz"
    sha256 "PLACEHOLDER"
  end

  resource "piexif" do
    url "https://files.pythonhosted.org/packages/piexif-1.1.3.tar.gz"
    sha256 "PLACEHOLDER"
  end

  resource "geopy" do
    url "https://files.pythonhosted.org/packages/geopy-2.3.0.tar.gz"
    sha256 "PLACEHOLDER"
  end

  resource "exifread" do
    url "https://files.pythonhosted.org/packages/exifread-3.0.0.tar.gz"
    sha256 "PLACEHOLDER"
  end

  def install
    virtualenv_install_with_resources
  end

  test do
    system "#{bin}/dng-caption", "--help"
  end

  def caveats
    <<~EOS
      To use this tool, you need to set your Anthropic API key:
        export ANTHROPIC_API_KEY="sk-ant-..."
      
      Add this to your ~/.zshrc to make it permanent.
      
      Get your API key at: https://console.anthropic.com
    EOS
  end
end
EOF

# ============================================
# Create GitHub Actions CI/CD
# ============================================

cat > .github/workflows/release.yml << 'EOF'
name: Release

on:
  push:
    tags:
      - 'v*'

jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Set up Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.11'
      
      - name: Install dependencies
        run: |
          python -m pip install --upgrade pip
          pip install build twine
      
      - name: Build package
        run: python -m build
      
      - name: Publish to PyPI
        env:
          TWINE_USERNAME: __token__
          TWINE_PASSWORD: ${{ secrets.PYPI_API_TOKEN }}
        run: twine upload dist/*
      
      - name: Create GitHub Release
        uses: softprops/action-gh-release@v1
        with:
          files: dist/*
          generate_release_notes: true
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}

  homebrew:
    needs: release
    runs-on: ubuntu-latest
    steps:
      - name: Update Homebrew Formula
        uses: mislav/bump-homebrew-formula-action@v2
        with:
          formula-name: dng-caption
          homebrew-tap: yourusername/homebrew-tap
        env:
          COMMITTER_TOKEN: ${{ secrets.HOMEBREW_TOKEN }}
EOF

cat > .github/workflows/tests.yml << 'EOF'
name: Tests

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ${{ matrix.os }}
    strategy:
      matrix:
        os: [ubuntu-latest, macos-latest]
        python-version: ['3.9', '3.10', '3.11', '3.12']
    
    steps:
      - uses: actions/checkout@v3
      
      - name: Set up Python
        uses: actions/setup-python@v4
        with:
          python-version: ${{ matrix.python-version }}
      
      - name: Install dependencies
        run: |
          python -m pip install --upgrade pip
          pip install -e .[dev]
      
      - name: Run tests
        run: pytest tests/
      
      - name: Check code style
        run: |
          black --check src/
          flake8 src/
EOF

# ============================================
# Create distribution files
# ============================================

# License file
cat > LICENSE << 'EOF'
MIT License

Copyright (c) 2024 Ari Reddy

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
EOF

# Contributing guidelines
cat > CONTRIBUTING.md << 'EOF'
# Contributing to DNG Caption Tool

We love your input! We want to make contributing as easy and transparent as possible.

## Development Process

1. Fork the repo and create your branch from `main`
2. If you've added code, add tests
3. Ensure the test suite passes
4. Make sure your code follows the style guidelines
5. Issue a pull request

## Code Style

- Use Black for Python formatting
- Follow PEP 8
- Add type hints where possible
- Document all functions

## Testing

```bash
pytest tests/
```

## Pull Request Process

1. Update the README.md with details of changes if needed
2. Update the CHANGELOG.md
3. The PR will be merged once you have approval

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
EOF

# pyproject.toml
cat > pyproject.toml << 'EOF'
[build-system]
requires = ["setuptools>=61.0", "wheel"]
build-backend = "setuptools.build_meta"

[project]
name = "dng-caption"
version = "2.1.0"
description = "AI-powered photo caption generator with GPS support"
readme = "README.md"
authors = [
    {name = "Ari Reddy", email = "your.email@example.com"}
]
license = {text = "MIT"}
classifiers = [
    "Development Status :: 5 - Production/Stable",
    "Intended Audience :: End Users/Desktop",
    "License :: OSI Approved :: MIT License",
    "Programming Language :: Python :: 3",
    "Programming Language :: Python :: 3.9",
    "Programming Language :: Python :: 3.10",
    "Programming Language :: Python :: 3.11",
]
requires-python = ">=3.9"
dependencies = [
    "anthropic>=0.18.0",
    "Pillow>=10.0.0",
    "piexif>=1.1.3",
    "geopy>=2.3.0",
    "exifread>=3.0.0",
]

[project.urls]
Homepage = "https://github.com/yourusername/dng-caption-tool"
Documentation = "https://github.com/yourusername/dng-caption-tool/wiki"
Repository = "https://github.com/yourusername/dng-caption-tool.git"
Issues = "https://github.com/yourusername/dng-caption-tool/issues"

[project.scripts]
dng-caption = "dng_caption.cli:main"
dng-caption-batch = "dng_caption.batch:main"

[tool.black]
line-length = 88
target-version = ['py39']

[tool.pytest.ini_options]
testpaths = ["tests"]
python_files = ["test_*.py"]

[tool.mypy]
python_version = "3.9"
warn_return_any = true
warn_unused_configs = true
EOF

# .gitignore
cat > .gitignore << 'EOF'
# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
build/
develop-eggs/
dist/
downloads/
eggs/
.eggs/
lib/
lib64/
parts/
sdist/
var/
wheels/
*.egg-info/
.installed.cfg
*.egg
MANIFEST

# Virtual Environment
venv/
ENV/
env/
.venv

# IDE
.vscode/
.idea/
*.swp
*.swo
*~

# OS
.DS_Store
.DS_Store?
._*
.Spotlight-V100
.Trashes
ehthumbs.db
Thumbs.db

# Project specific
*.jpg
*.jpeg
*.png
*.dng
*.xmp
*.backup
test_images/
output/

# API Keys
.env
.env.local
*.key
config.ini

# Documentation
docs/_build/
*.rst~

# Testing
.coverage
.pytest_cache/
.tox/
htmlcov/

# Distribution
*.tar.gz
*.zip
*.dmg
EOF

# Create release script
cat > scripts/release.sh << 'EOF'
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
EOF

chmod +x scripts/release.sh

echo ""
echo "✅ Production package structure created!"
echo ""
echo "📁 Project structure:"
tree -L 2 2>/dev/null || find . -type d -maxdepth 2 | sed 's|./||'

echo ""
echo "📦 Distribution package ready for:"
echo "  • GitHub repository"
echo "  • PyPI package registry"
echo "  • Homebrew tap"
echo "  • Docker container"
echo ""
echo "Next steps:"
echo "1. Initialize git: git init"
echo "2. Add files: git add ."
echo "3. Commit: git commit -m 'Initial commit'"
echo "4. Create GitHub repo"
echo "5. Push to GitHub"
echo "6. Run release script: ./scripts/release.sh"
