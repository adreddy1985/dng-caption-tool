"""GPS extraction and geocoding functionality"""

from typing import Optional, Dict
from pathlib import Path
import piexif
from PIL import Image
from geopy.geocoders import Nominatim
from geopy.exc import GeocoderTimedOut, GeocoderServiceError
import time


class GPSExtractor:
    """Extract and geocode GPS data from images"""
    
    def __init__(self):
        self.geolocator = Nominatim(user_agent="dng_caption_tool")
    
    def extract_gps(self, image_path: Path) -> Optional[Dict]:
        """Extract GPS coordinates from image"""
        try:
            img = Image.open(image_path)
            if 'exif' not in img.info:
                return None
            
            exif_dict = piexif.load(img.info['exif'])
            if piexif.GPSIFD.GPSLatitude not in exif_dict.get('GPS', {}):
                return None
            
            # Extract coordinates
            lat = self._convert_to_degrees(
                exif_dict['GPS'][piexif.GPSIFD.GPSLatitude],
                exif_dict['GPS'][piexif.GPSIFD.GPSLatitudeRef].decode('utf-8')
            )
            
            lon = self._convert_to_degrees(
                exif_dict['GPS'][piexif.GPSIFD.GPSLongitude],
                exif_dict['GPS'][piexif.GPSIFD.GPSLongitudeRef].decode('utf-8')
            )
            
            result = {'latitude': lat, 'longitude': lon}
            
            # Extract altitude if available
            if piexif.GPSIFD.GPSAltitude in exif_dict.get('GPS', {}):
                alt = exif_dict['GPS'][piexif.GPSIFD.GPSAltitude]
                result['altitude'] = alt[0] / alt[1]
            
            return result
            
        except Exception:
            return None
    
    def reverse_geocode(self, latitude: float, longitude: float, 
                        retries: int = 2) -> Optional[Dict]:
        """Convert coordinates to location name"""
        for attempt in range(retries):
            try:
                location = self.geolocator.reverse(
                    f"{latitude}, {longitude}",
                    timeout=5,
                    language='en'
                )
                
                if location:
                    return self._parse_location(location)
                    
            except (GeocoderTimedOut, GeocoderServiceError):
                if attempt < retries - 1:
                    time.sleep(1)
                    
        return None
    
    def _convert_to_degrees(self, value, ref):
        """Convert GPS coordinates to decimal degrees"""
        degrees = value[0][0] / value[0][1]
        minutes = value[1][0] / value[1][1]
        seconds = value[2][0] / value[2][1]
        
        decimal = degrees + (minutes / 60.0) + (seconds / 3600.0)
        
        if ref in ['S', 'W']:
            decimal = -decimal
            
        return decimal
    
    def _parse_location(self, location):
        """Parse location data"""
        address = location.raw.get('address', {})
        
        city = (address.get('city') or 
                address.get('town') or 
                address.get('village') or
                address.get('hamlet'))
        
        parts = []
        if city:
            parts.append(city)
        if state := address.get('state'):
            parts.append(state)
        if country := address.get('country'):
            parts.append(country)
        
        return {
            'formatted': ', '.join(parts) if parts else location.address,
            'city': city,
            'state': address.get('state'),
            'country': address.get('country'),
            'full_address': location.address
        }
