# DNG Caption Tool

[![Version](https://img.shields.io/github/v/release/yourusername/dng-caption-tool)](https://github.com/yourusername/dng-caption-tool/releases)
[![Python](https://img.shields.io/badge/python-3.9+-blue)](https://www.python.org/downloads/)
[![License](https://img.shields.io/badge/license-MIT-green)](LICENSE)
[![Tests](https://github.com/yourusername/dng-caption-tool/actions/workflows/tests.yml/badge.svg)](https://github.com/yourusername/dng-caption-tool/actions)

AI-powered photo caption generator with GPS location support, XMP embedding, and multi-platform compatibility.

## Features

- 🤖 **AI-Powered Captions** - Supports both Claude (Opus/Sonnet/Haiku) and OpenAI (GPT-4o/GPT-4o-mini/GPT-4-turbo) models
- 📍 **GPS Location Support** - Automatic extraction and geocoding
- 🏷️ **XMP Metadata** - Industry-standard sidecar files
- 💾 **JPEG Embedding** - Direct metadata embedding
- 🎨 **Multiple Styles** - Descriptive, social, artistic, travel
- 🚀 **Batch Processing** - Handle entire folders efficiently
- 💰 **Cost Optimization** - Smart model selection
- 🔄 **Multi-Provider** - Switch between Claude and OpenAI easily

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

### Using Claude (default)

```bash
# Set your API key
export ANTHROPIC_API_KEY="sk-ant-..."

# Caption a single image
dng-caption photo.jpg

# Use specific model
dng-caption photo.jpg --model sonnet --style descriptive

# Process folder with GPS
dng-caption-batch ~/Photos/ --style travel

# Embed captions into JPEGs
dng-caption *.jpg --embed
```

### Using OpenAI

```bash
# Set your API key
export OPENAI_API_KEY="sk-..."

# Caption with OpenAI
dng-caption photo.jpg --provider openai

# Use specific OpenAI model
dng-caption photo.jpg --provider openai --model gpt-4o --style social

# Batch process with OpenAI
dng-caption-batch ~/Photos/ --provider openai --model gpt-4o-mini
```

### Available Models

**Claude Models:**
- `haiku` - Fast and affordable (default)
- `sonnet` - Best balance of speed and quality
- `opus` - Highest quality (auto-selected for social media)

**OpenAI Models:**
- `gpt-4o-mini` - Fast and affordable (default)
- `gpt-4o` - Latest GPT-4 with vision (auto-selected for social media)
- `gpt-4-turbo` - Previous generation GPT-4

## Documentation

See the [full documentation](https://github.com/yourusername/dng-caption-tool/wiki) for detailed usage.

## License

MIT License - see [LICENSE](LICENSE) file

## Contributing

Contributions welcome! See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.
