"""Core caption generation functionality"""

import base64
from pathlib import Path
from typing import Optional, Dict
import anthropic
import openai
from PIL import Image


class CaptionGenerator:
    """AI-powered caption generator using Claude or OpenAI"""

    CLAUDE_MODELS = {
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
            'name': 'claude-opus-4-5-20251101',
            'cost': 0.015,
            'description': 'Highest quality'
        }
    }

    OPENAI_MODELS = {
        'gpt-4o': {
            'name': 'gpt-4o',
            'cost': 0.005,
            'description': 'Latest GPT-4 with vision'
        },
        'gpt-4o-mini': {
            'name': 'gpt-4o-mini',
            'cost': 0.00015,
            'description': 'Fast and affordable GPT-4'
        },
        'gpt-4-turbo': {
            'name': 'gpt-4-turbo',
            'cost': 0.01,
            'description': 'Previous GPT-4 Turbo'
        }
    }
    
    STYLES = {
        'descriptive': "Write a 2-3 sentence professional caption for this image.",
        'social': """Generate an engaging, but straightforward caption for Instagram using the image and metadata. Follow these guidelines:
- First line should be descriptive of what the subject is if known
- Use a masculine voice and avoid excessively flowery language
- Use any location data if available
- Append the caption with up to 8 hashtags that are likely to drive traffic and engagement
- Keep the tone engaging but direct""",
        'minimal': "Write a brief one-sentence caption.",
        'artistic': "Write a poetic, evocative caption.",
        'documentary': "Write a factual, journalistic caption.",
        'travel': "Write a travel photography caption emphasizing the location."
    }
    
    def __init__(self, api_key: Optional[str] = None, provider: str = 'claude'):
        """Initialize with API key and provider

        Args:
            api_key: API key for the selected provider. If not provided, will use
                    ANTHROPIC_API_KEY or OPENAI_API_KEY from environment
            provider: Either 'claude' or 'openai' (default: 'claude')
        """
        import os
        self.provider = provider.lower()

        if self.provider == 'claude':
            self.api_key = api_key or os.environ.get('ANTHROPIC_API_KEY')
            if not self.api_key:
                raise ValueError("Anthropic API key required (set ANTHROPIC_API_KEY)")
            self.client = anthropic.Anthropic(api_key=self.api_key)
            self.models = self.CLAUDE_MODELS
        elif self.provider == 'openai':
            self.api_key = api_key or os.environ.get('OPENAI_API_KEY')
            if not self.api_key:
                raise ValueError("OpenAI API key required (set OPENAI_API_KEY)")
            self.client = openai.OpenAI(api_key=self.api_key)
            self.models = self.OPENAI_MODELS
        else:
            raise ValueError(f"Invalid provider: {provider}. Must be 'claude' or 'openai'")
    
    def generate(self,
                 image_path: Path,
                 style: str = 'descriptive',
                 model: Optional[str] = None,
                 location_context: Optional[str] = None) -> str:
        """Generate caption for image

        Args:
            image_path: Path to image file
            style: Caption style (descriptive, social, minimal, etc.)
            model: Model to use. If None, uses smart defaults based on style and provider
            location_context: Optional GPS location context to include

        Returns:
            Generated caption text
        """
        # Route to provider-specific method
        if self.provider == 'claude':
            return self._generate_claude(image_path, style, model, location_context)
        else:
            return self._generate_openai(image_path, style, model, location_context)

    def _generate_claude(self,
                         image_path: Path,
                         style: str,
                         model: Optional[str],
                         location_context: Optional[str]) -> str:
        """Generate caption using Claude"""
        # Use Opus model for social media captions if no model specified
        if model is None:
            model = 'opus' if style == 'social' else 'haiku'

        # Validate model
        if model not in self.CLAUDE_MODELS:
            raise ValueError(f"Invalid Claude model: {model}. Choose from {list(self.CLAUDE_MODELS.keys())}")

        # Prepare image
        image_base64 = self._prepare_image(image_path)

        # Build prompt
        prompt = self.STYLES.get(style, self.STYLES['descriptive'])
        if location_context:
            prompt += f"\n\n{location_context}"

        # Generate caption
        response = self.client.messages.create(
            model=self.CLAUDE_MODELS[model]['name'],
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

    def _generate_openai(self,
                         image_path: Path,
                         style: str,
                         model: Optional[str],
                         location_context: Optional[str]) -> str:
        """Generate caption using OpenAI"""
        # Use gpt-4o for social media, gpt-4o-mini for others if no model specified
        if model is None:
            model = 'gpt-4o' if style == 'social' else 'gpt-4o-mini'

        # Validate model
        if model not in self.OPENAI_MODELS:
            raise ValueError(f"Invalid OpenAI model: {model}. Choose from {list(self.OPENAI_MODELS.keys())}")

        # Prepare image
        image_base64 = self._prepare_image(image_path)

        # Build prompt
        prompt = self.STYLES.get(style, self.STYLES['descriptive'])
        if location_context:
            prompt += f"\n\n{location_context}"

        # Generate caption using OpenAI Vision API
        response = self.client.chat.completions.create(
            model=self.OPENAI_MODELS[model]['name'],
            max_tokens=300,
            messages=[{
                "role": "user",
                "content": [
                    {
                        "type": "image_url",
                        "image_url": {
                            "url": f"data:image/jpeg;base64,{image_base64}"
                        }
                    },
                    {
                        "type": "text",
                        "text": prompt
                    }
                ]
            }]
        )

        return response.choices[0].message.content.strip()
    
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
