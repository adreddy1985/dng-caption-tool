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
