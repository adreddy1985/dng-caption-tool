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
