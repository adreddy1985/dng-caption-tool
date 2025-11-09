#!/usr/bin/env python3
"""
DNG Caption Tool
Professional photo caption generator with GPS support
"""

from setuptools import setup, find_packages
from pathlib import Path

# Read the README file
this_directory = Path(__file__).parent
long_description = (this_directory / "README.md").read_text()

setup(
    name="dng-caption",
    version="2.1.0",
    author="Ari Reddy",
    author_email="your.email@example.com",
    description="AI-powered photo caption generator with GPS location support",
    long_description=long_description,
    long_description_content_type="text/markdown",
    url="https://github.com/yourusername/dng-caption-tool",
    project_urls={
        "Bug Tracker": "https://github.com/yourusername/dng-caption-tool/issues",
        "Documentation": "https://github.com/yourusername/dng-caption-tool/wiki",
        "Source Code": "https://github.com/yourusername/dng-caption-tool",
    },
    classifiers=[
        "Development Status :: 5 - Production/Stable",
        "Intended Audience :: End Users/Desktop",
        "Topic :: Multimedia :: Graphics",
        "License :: OSI Approved :: MIT License",
        "Programming Language :: Python :: 3",
        "Programming Language :: Python :: 3.9",
        "Programming Language :: Python :: 3.10",
        "Programming Language :: Python :: 3.11",
        "Programming Language :: Python :: 3.12",
        "Operating System :: MacOS :: MacOS X",
        "Operating System :: POSIX :: Linux",
        "Operating System :: Microsoft :: Windows",
        "Natural Language :: English",
    ],
    packages=find_packages(where="src"),
    package_dir={"": "src"},
    python_requires=">=3.9",
    install_requires=[
        "anthropic>=0.18.0",
        "Pillow>=10.0.0",
        "piexif>=1.1.3",
        "geopy>=2.3.0",
        "exifread>=3.0.0",
    ],
    extras_require={
        "dev": [
            "pytest>=7.0",
            "black>=22.0",
            "flake8>=4.0",
            "mypy>=0.900",
            "pre-commit>=2.0",
        ],
        "docs": [
            "sphinx>=4.0",
            "sphinx-rtd-theme>=1.0",
        ],
    },
    entry_points={
        "console_scripts": [
            "dng-caption=dng_caption.cli:main",
            "dng-caption-batch=dng_caption.batch:main",
            "dng-caption-embed=dng_caption.embed:main",
            "dng-caption-view=dng_caption.viewer:main",
        ],
    },
    include_package_data=True,
    package_data={
        "dng_caption": ["templates/*.xmp", "data/*.json"],
    },
    zip_safe=False,
)
