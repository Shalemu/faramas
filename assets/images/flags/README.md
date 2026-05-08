# Flag Images for Language Selection

This directory should contain flag images for the language selector.

## Required Files:

1. **en.png** - English flag (UK flag 🇬🇧 or US flag 🇺🇸)
2. **sw.png** - Kiswahili flag (Tanzania flag 🇹🇿)

## Image Specifications:
- Format: PNG
- Recommended size: 64x64 pixels or 128x128 pixels
- Transparent background (optional)

## Where to Get Flag Images:

### Option 1: Download from Free Resources
- **Flaticon**: https://www.flaticon.com/free-icons/flag
- **Freepik**: https://www.freepik.com/search?format=search&query=flag%20icons
- **Country Flags API**: https://flagcdn.com/
  - UK Flag: https://flagcdn.com/w80/gb.png
  - Tanzania Flag: https://flagcdn.com/w80/tz.png

### Option 2: Use Flutter Packages
You can also use the `country_flags` or `flag` package from pub.dev instead of image files.

### Option 3: Create Simple Colored Rectangles
For testing purposes, you can create simple colored rectangles:
- English (UK): Red, white, and blue
- Kiswahili (Tanzania): Green, yellow, blue, and black

## Quick Download Commands:

If you have curl or wget installed, you can download the flags directly:

```bash
# Download UK flag
curl -o assets/images/flags/en.png https://flagcdn.com/w80/gb.png

# Download Tanzania flag
curl -o assets/images/flags/sw.png https://flagcdn.com/w80/tz.png
```

Or using PowerShell on Windows:

```powershell
# Download UK flag
Invoke-WebRequest -Uri "https://flagcdn.com/w80/gb.png" -OutFile "assets/images/flags/en.png"

# Download Tanzania flag
Invoke-WebRequest -Uri "https://flagcdn.com/w80/tz.png" -OutFile "assets/images/flags/sw.png"
```

## Note:
The app will still work without these images - it will show a fallback icon (language icon) if the flag images are not found.
