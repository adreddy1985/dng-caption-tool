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
