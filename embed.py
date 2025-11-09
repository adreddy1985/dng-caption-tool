"""XMP embedding functionality"""

import subprocess
import shutil
from pathlib import Path
from typing import Optional
import xml.etree.ElementTree as ET
import html


class XMPEmbedder:
    """Embed XMP metadata into JPEG files"""
    
    def __init__(self):
        """Initialize embedder and check for ExifTool"""
        self.exiftool_available = self._check_exiftool()
    
    def _check_exiftool(self) -> bool:
        """Check if ExifTool is available"""
        try:
            result = subprocess.run(
                ['exiftool', '-ver'],
                capture_output=True,
                text=True
            )
            return result.returncode == 0
        except FileNotFoundError:
            return False
    
    def create_xmp(self, caption: str, location: Optional[str] = None) -> str:
        """Create XMP metadata string"""
        caption_escaped = html.escape(caption)
        
        location_block = ""
        if location:
            location_escaped = html.escape(location)
            location_block = f'''
      <photoshop:City>{location_escaped}</photoshop:City>'''
        
        return f'''<?xml version="1.0" encoding="UTF-8"?>
<x:xmpmeta xmlns:x="adobe:ns:meta/">
  <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
    <rdf:Description rdf:about=""
        xmlns:dc="http://purl.org/dc/elements/1.1/"
        xmlns:photoshop="http://ns.adobe.com/photoshop/1.0/">
      <dc:description>
        <rdf:Alt>
          <rdf:li xml:lang="x-default">{caption_escaped}</rdf:li>
        </rdf:Alt>
      </dc:description>{location_block}
    </rdf:Description>
  </rdf:RDF>
</x:xmpmeta>'''
    
    def write_sidecar(self, image_path: Path, caption: str, 
                     location: Optional[str] = None) -> Path:
        """Write XMP sidecar file"""
        xmp_path = image_path.with_suffix('.xmp')
        xmp_content = self.create_xmp(caption, location)
        
        with open(xmp_path, 'w', encoding='utf-8') as f:
            f.write(xmp_content)
        
        return xmp_path
    
    def embed(self, image_path: Path, caption: str,
              location: Optional[str] = None, backup: bool = True) -> bool:
        """Embed XMP directly into JPEG"""
        
        if not self.exiftool_available:
            # Fallback to sidecar only
            self.write_sidecar(image_path, caption, location)
            return False
        
        # Create backup if requested
        if backup:
            backup_path = image_path.with_suffix('.jpg.backup')
            shutil.copy2(image_path, backup_path)
        
        # Write sidecar first
        xmp_path = self.write_sidecar(image_path, caption, location)
        
        # Embed using ExifTool
        try:
            # Build ExifTool command
            cmd = [
                'exiftool',
                '-overwrite_original',
                f'-Description={caption}',
                f'-ImageDescription={caption}'
            ]
            
            if location:
                cmd.append(f'-LocationShownCity={location}')
            
            # Add XMP
            cmd.extend([
                '-tagsfromfile', str(xmp_path),
                '-xmp',
                str(image_path)
            ])
            
            result = subprocess.run(cmd, capture_output=True, text=True)
            
            return result.returncode == 0
            
        except Exception as e:
            print(f"Embedding failed: {e}")
            return False
    
    def verify_embedding(self, image_path: Path) -> bool:
        """Verify if XMP was successfully embedded"""
        
        if not self.exiftool_available:
            return False
        
        try:
            result = subprocess.run(
                ['exiftool', '-xmp:description', str(image_path)],
                capture_output=True,
                text=True
            )
            
            return 'Description' in result.stdout
            
        except Exception:
            return False
