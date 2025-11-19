class DngCaption < Formula
  include Language::Python::Virtualenv

  desc "AI-powered photo caption generator with Claude and OpenAI support"
  homepage "https://github.com/adreddy1985/dng-caption-tool"
  url "https://github.com/adreddy1985/dng-caption-tool/archive/refs/tags/v2.3.0.tar.gz"
  sha256 "0e2044b1d5400223b49405cabaf0b15e2ace2e16129606a6bbd1cec51ec130ad"
  license "MIT"
  head "https://github.com/adreddy1985/dng-caption-tool.git", branch: "main"

  depends_on "python@3.11"
  depends_on "exiftool"

  resource "anthropic" do
    url "https://files.pythonhosted.org/packages/anthropic-0.18.0.tar.gz"
    sha256 "PLACEHOLDER"
  end

  resource "openai" do
    url "https://files.pythonhosted.org/packages/openai-1.0.0.tar.gz"
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
      To use this tool, set your API key for your chosen provider:

      For Claude (default):
        export ANTHROPIC_API_KEY="sk-ant-..."
        Get your key at: https://console.anthropic.com

      For OpenAI:
        export OPENAI_API_KEY="sk-..."
        Get your key at: https://platform.openai.com/api-keys

      Add to your ~/.zshrc to make it permanent.

      Usage:
        dng-caption photo.jpg --provider claude
        dng-caption photo.jpg --provider openai --model gpt-4o
    EOS
  end
end
