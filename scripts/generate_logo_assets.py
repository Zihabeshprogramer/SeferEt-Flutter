#!/usr/bin/env python3
"""
Generate optimized logo assets for Flutter app icons and splash screens.
This script creates properly padded and centered versions to avoid stretching.
"""

from PIL import Image, ImageDraw
import os

# Paths
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.dirname(SCRIPT_DIR)
LOGO_DIR = os.path.join(PROJECT_ROOT, "assets", "images", "logo")
OUTPUT_DIR = os.path.join(LOGO_DIR, "generated")

# Source images
PLAYSTORE_IMG = os.path.join(LOGO_DIR, "appicons", "playstore.png")
LOGO_NOTEXT_IMG = os.path.join(LOGO_DIR, "imagesets", "ios", "seferet-logo-notext-colored@3x.png")

# Colors from logo analysis
BG_COLOR_LIGHT = (255, 255, 255)  # White
BG_COLOR_DARK = (26, 26, 26)       # Dark gray
ADAPTIVE_BG = (255, 255, 255)      # White for adaptive icon background

def create_output_dir():
    """Create output directory if it doesn't exist."""
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    print(f"✓ Output directory: {OUTPUT_DIR}")

def crop_decorative_bars(img):
    """
    Remove the decorative blue bars from top and bottom of the logo.
    Returns the cropped image with just the core triangle logo.
    """
    # Convert to RGBA if not already
    img = img.convert("RGBA")
    
    # Get image data
    width, height = img.size
    pixels = img.load()
    
    # Find the actual content bounds (non-transparent and non-blue-bar areas)
    # The blue bars are at the top and bottom, approximately 15% each
    crop_top = int(height * 0.15)
    crop_bottom = int(height * 0.85)
    
    # Crop to remove decorative bars
    cropped = img.crop((0, crop_top, width, crop_bottom))
    
    return cropped

def create_icon_with_padding(source_img, size, padding_percent=15, bg_color=BG_COLOR_LIGHT):
    """
    Create a square icon with proper padding to prevent stretching.
    
    Args:
        source_img: PIL Image object
        size: Output size (width, height)
        padding_percent: Percentage of padding around the logo
        bg_color: Background color tuple (R, G, B)
    """
    # Create a new square canvas
    canvas = Image.new("RGBA", size, bg_color + (255,))
    
    # Calculate the area for the logo (with padding)
    padding = int(size[0] * padding_percent / 100)
    logo_area = size[0] - (2 * padding)
    
    # Remove decorative bars from source
    logo = crop_decorative_bars(source_img)
    
    # Resize logo to fit within the logo area, maintaining aspect ratio
    logo.thumbnail((logo_area, logo_area), Image.Resampling.LANCZOS)
    
    # Calculate position to center the logo
    x = (size[0] - logo.width) // 2
    y = (size[1] - logo.height) // 2
    
    # Paste logo onto canvas
    canvas.paste(logo, (x, y), logo if logo.mode == 'RGBA' else None)
    
    return canvas

def create_splash_with_padding(source_img, width, height, scale_percent=35, bg_color=BG_COLOR_LIGHT):
    """
    Create a splash screen with logo properly centered and scaled.
    
    Args:
        source_img: PIL Image object
        width: Canvas width
        height: Canvas height
        scale_percent: Logo size as percentage of canvas height
        bg_color: Background color tuple (R, G, B)
    """
    # Create canvas
    canvas = Image.new("RGBA", (width, height), bg_color + (255,))
    
    # Use full logo with decorative bars for splash screen
    logo = source_img.convert("RGBA")
    
    # Calculate logo size (as percentage of canvas height)
    target_height = int(height * scale_percent / 100)
    
    # Resize maintaining aspect ratio
    aspect_ratio = logo.width / logo.height
    target_width = int(target_height * aspect_ratio)
    logo_resized = logo.resize((target_width, target_height), Image.Resampling.LANCZOS)
    
    # Center the logo
    x = (width - logo_resized.width) // 2
    y = (height - logo_resized.height) // 2
    
    # Paste logo
    canvas.paste(logo_resized, (x, y), logo_resized)
    
    return canvas

def create_adaptive_icon_foreground(source_img, size=1024):
    """
    Create foreground for Android adaptive icon (transparent background).
    Logo should occupy ~60% of the canvas for safe area.
    """
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    
    # Remove decorative bars
    logo = crop_decorative_bars(source_img)
    
    # Scale logo to 60% of canvas (safe area for adaptive icons)
    logo_size = int(size * 0.60)
    logo.thumbnail((logo_size, logo_size), Image.Resampling.LANCZOS)
    
    # Center
    x = (size - logo.width) // 2
    y = (size - logo.height) // 2
    
    canvas.paste(logo, (x, y), logo)
    
    return canvas

def generate_app_icon():
    """Generate optimized app icon (1024x1024 for iOS/Android)."""
    print("\n📱 Generating app icon...")
    
    source = Image.open(PLAYSTORE_IMG)
    
    # Create iOS app icon (1024x1024, 20% padding, white background)
    icon_ios = create_icon_with_padding(source, (1024, 1024), padding_percent=20, bg_color=BG_COLOR_LIGHT)
    output_path = os.path.join(OUTPUT_DIR, "app_icon_1024.png")
    icon_ios.save(output_path, "PNG", quality=100)
    print(f"  ✓ iOS app icon: {output_path}")
    
    # Create Android standard icon (512x512, 15% padding)
    icon_android = create_icon_with_padding(source, (512, 512), padding_percent=15, bg_color=BG_COLOR_LIGHT)
    output_path = os.path.join(OUTPUT_DIR, "app_icon_512.png")
    icon_android.save(output_path, "PNG", quality=100)
    print(f"  ✓ Android standard icon: {output_path}")
    
    source.close()

def generate_adaptive_icon():
    """Generate Android adaptive icon layers."""
    print("\n🎨 Generating Android adaptive icon...")
    
    source = Image.open(PLAYSTORE_IMG)
    
    # Foreground (1024x1024, transparent, logo only)
    foreground = create_adaptive_icon_foreground(source, size=1024)
    output_path = os.path.join(OUTPUT_DIR, "adaptive_icon_foreground.png")
    foreground.save(output_path, "PNG", quality=100)
    print(f"  ✓ Adaptive foreground: {output_path}")
    
    # Background (solid white)
    background = Image.new("RGB", (1024, 1024), ADAPTIVE_BG)
    output_path = os.path.join(OUTPUT_DIR, "adaptive_icon_background.png")
    background.save(output_path, "PNG", quality=100)
    print(f"  ✓ Adaptive background: {output_path}")
    
    source.close()

def generate_splash_screens():
    """Generate splash screen images."""
    print("\n💦 Generating splash screens...")
    
    source = Image.open(PLAYSTORE_IMG)
    
    # Common mobile splash screen size (1242x2688 - iPhone 13 Pro Max)
    # Light mode
    splash_light = create_splash_with_padding(source, 1242, 2688, scale_percent=30, bg_color=BG_COLOR_LIGHT)
    output_path = os.path.join(OUTPUT_DIR, "splash_light.png")
    splash_light.save(output_path, "PNG", quality=100)
    print(f"  ✓ Splash (light): {output_path}")
    
    # Dark mode
    splash_dark = create_splash_with_padding(source, 1242, 2688, scale_percent=30, bg_color=BG_COLOR_DARK)
    output_path = os.path.join(OUTPUT_DIR, "splash_dark.png")
    splash_dark.save(output_path, "PNG", quality=100)
    print(f"  ✓ Splash (dark): {output_path}")
    
    # Android 12 splash (smaller logo, 288x288 recommended)
    android12_light = create_splash_with_padding(source, 288, 288, scale_percent=65, bg_color=(0, 0, 0, 0))
    output_path = os.path.join(OUTPUT_DIR, "splash_android12.png")
    android12_light.save(output_path, "PNG", quality=100)
    print(f"  ✓ Splash (Android 12): {output_path}")
    
    source.close()

def main():
    """Main execution function."""
    print("🚀 SeferEt Logo Asset Generator")
    print("=" * 50)
    
    # Check if source files exist
    if not os.path.exists(PLAYSTORE_IMG):
        print(f"❌ Error: Source image not found: {PLAYSTORE_IMG}")
        return
    
    # Create output directory
    create_output_dir()
    
    # Generate all assets
    generate_app_icon()
    generate_adaptive_icon()
    generate_splash_screens()
    
    print("\n" + "=" * 50)
    print("✅ All assets generated successfully!")
    print(f"\n📁 Output location: {OUTPUT_DIR}")
    print("\n📝 Next steps:")
    print("  1. Update pubspec.yaml to use new generated images")
    print("  2. Run: dart run flutter_launcher_icons")
    print("  3. Run: dart run flutter_native_splash:create")

if __name__ == "__main__":
    main()
