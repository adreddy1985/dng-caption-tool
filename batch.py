"""Batch processing functionality"""

import sys
from pathlib import Path
from typing import List, Dict
import time
from .caption import CaptionGenerator
from .gps import GPSExtractor
from .embed import XMPEmbedder


class BatchProcessor:
    """Process multiple images efficiently"""
    
    def __init__(self, api_key: str = None):
        """Initialize batch processor"""
        self.generator = CaptionGenerator(api_key)
        self.gps_extractor = GPSExtractor()
        self.embedder = XMPEmbedder()
        self.stats = {
            'processed': 0,
            'skipped': 0,
            'failed': 0,
            'with_gps': 0
        }
    
    def process_folder(self, folder_path: Path,
                       model: str = 'haiku',
                       style: str = 'descriptive',
                       skip_existing: bool = False,
                       embed: bool = True,
                       use_gps: bool = True) -> Dict:
        """Process all images in folder"""
        
        # Find all JPEG files
        jpeg_files = []
        for ext in ['*.jpg', '*.jpeg', '*.JPG', '*.JPEG']:
            jpeg_files.extend(folder_path.glob(ext))
        
        if not jpeg_files:
            print(f"No JPEG files found in {folder_path}")
            return self.stats
        
        jpeg_files.sort()
        total = len(jpeg_files)
        
        print(f"Processing {total} images...")
        print(f"Model: {model}, Style: {style}")
        if use_gps:
            print("📍 GPS extraction enabled")
        print("-" * 40)
        
        for i, jpeg_path in enumerate(jpeg_files, 1):
            # Check if should skip
            if skip_existing:
                xmp_path = jpeg_path.with_suffix('.xmp')
                if xmp_path.exists():
                    print(f"[{i}/{total}] {jpeg_path.name} - Skipped (exists)")
                    self.stats['skipped'] += 1
                    continue
            
            try:
                print(f"[{i}/{total}] {jpeg_path.name}...", end=' ')
                
                # Extract GPS if enabled
                location_context = None
                location_name = None
                
                if use_gps:
                    if gps_data := self.gps_extractor.extract_gps(jpeg_path):
                        self.stats['with_gps'] += 1
                        
                        if location := self.gps_extractor.reverse_geocode(
                            gps_data['latitude'], 
                            gps_data['longitude']
                        ):
                            location_name = location['formatted']
                            location_context = f"Location: {location_name}"
                            print(f"\n    📍 {location_name}", end=' ')
                
                # Generate caption
                caption = self.generator.generate(
                    jpeg_path, style, model, location_context
                )
                
                # Embed or write sidecar
                if embed:
                    success = self.embedder.embed(
                        jpeg_path, caption, location_name
                    )
                    if success:
                        print("✓ (embedded)")
                    else:
                        print("✓ (sidecar)")
                else:
                    self.embedder.write_sidecar(
                        jpeg_path, caption, location_name
                    )
                    print("✓")
                
                self.stats['processed'] += 1
                
                # Rate limiting
                if i < total:
                    time.sleep(0.5)
                    
            except Exception as e:
                print(f"✗ ({e})")
                self.stats['failed'] += 1
        
        return self.stats


def main():
    """CLI entry point for batch processing"""
    import argparse
    
    parser = argparse.ArgumentParser(
        description='Batch process images with AI captions'
    )
    parser.add_argument('folder', help='Folder containing images')
    parser.add_argument('--model', default='haiku',
                       choices=['haiku', 'sonnet', 'opus'])
    parser.add_argument('--style', default='descriptive',
                       choices=['descriptive', 'social', 'minimal',
                               'artistic', 'documentary', 'travel'])
    parser.add_argument('--skip-existing', action='store_true',
                       help='Skip images with existing XMP files')
    parser.add_argument('--no-embed', action='store_true',
                       help='Create sidecars only, don\'t embed')
    parser.add_argument('--no-gps', action='store_true',
                       help='Disable GPS extraction')
    
    args = parser.parse_args()
    
    folder_path = Path(args.folder)
    if not folder_path.exists():
        print(f"Error: {folder_path} does not exist")
        return 1
    
    processor = BatchProcessor()
    stats = processor.process_folder(
        folder_path,
        model=args.model,
        style=args.style,
        skip_existing=args.skip_existing,
        embed=not args.no_embed,
        use_gps=not args.no_gps
    )
    
    # Print summary
    print("\n" + "=" * 40)
    print("SUMMARY")
    print("=" * 40)
    print(f"✅ Processed: {stats['processed']}")
    if stats['skipped'] > 0:
        print(f"⏭  Skipped: {stats['skipped']}")
    if stats['failed'] > 0:
        print(f"❌ Failed: {stats['failed']}")
    if stats['with_gps'] > 0:
        print(f"📍 With GPS: {stats['with_gps']}")
    
    return 0 if stats['failed'] == 0 else 1


if __name__ == '__main__':
    sys.exit(main())
