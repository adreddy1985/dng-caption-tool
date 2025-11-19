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
    parser.add_argument('--provider', default='claude',
                       choices=['claude', 'openai'],
                       help='AI provider to use (default: claude)')
    parser.add_argument('--model',
                       help='Model to use. Claude: haiku, sonnet, opus. OpenAI: gpt-4o, gpt-4o-mini, gpt-4-turbo')
    parser.add_argument('--style', default='descriptive',
                       choices=['descriptive', 'social', 'minimal',
                               'artistic', 'documentary', 'travel'])
    parser.add_argument('--no-gps', action='store_true',
                       help='Disable GPS extraction')
    parser.add_argument('--embed', action='store_true',
                       help='Embed captions into JPEG files')

    args = parser.parse_args()

    # Initialize components
    generator = CaptionGenerator(provider=args.provider)
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
