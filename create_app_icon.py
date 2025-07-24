#!/usr/bin/env python3
"""
VMUrugan App Icon Generator
Creates app icons in different sizes for Android
"""

from PIL import Image, ImageDraw, ImageFont
import os

def create_vmurugan_icon(size):
    """Create VMUrugan app icon of specified size"""
    
    # Create image with transparent background
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Colors
    red_color = (220, 20, 60)  # Crimson red
    white_color = (255, 255, 255)
    black_color = (0, 0, 0)
    gold_color = (255, 215, 0)
    
    # Draw background circle
    margin = size // 20
    circle_size = size - (margin * 2)
    draw.ellipse([margin, margin, margin + circle_size, margin + circle_size], 
                 fill=red_color, outline=black_color, width=max(1, size//50))
    
    # Calculate text size
    font_size = size // 3
    try:
        # Try to use a bold font
        font = ImageFont.truetype("arial.ttf", font_size)
    except:
        try:
            font = ImageFont.truetype("Arial Bold.ttf", font_size)
        except:
            # Fallback to default font
            font = ImageFont.load_default()
    
    # Draw "Vm" text
    text = "Vm"
    
    # Get text bounding box
    bbox = draw.textbbox((0, 0), text, font=font)
    text_width = bbox[2] - bbox[0]
    text_height = bbox[3] - bbox[1]
    
    # Center the text
    x = (size - text_width) // 2
    y = (size - text_height) // 2 - size // 20  # Slightly up
    
    # Draw text with shadow effect
    shadow_offset = max(1, size // 100)
    draw.text((x + shadow_offset, y + shadow_offset), text, font=font, fill=black_color)
    draw.text((x, y), text, font=font, fill=white_color)
    
    # Add small gold accent
    accent_size = size // 8
    accent_x = size - accent_size - margin
    accent_y = margin
    draw.ellipse([accent_x, accent_y, accent_x + accent_size, accent_y + accent_size], 
                 fill=gold_color, outline=black_color, width=1)
    
    return img

def main():
    """Generate all required icon sizes"""
    
    # Android icon sizes
    sizes = {
        'mipmap-mdpi': 48,
        'mipmap-hdpi': 72,
        'mipmap-xhdpi': 96,
        'mipmap-xxhdpi': 144,
        'mipmap-xxxhdpi': 192
    }
    
    base_path = "android/app/src/main/res"
    
    print("🎨 Creating VMUrugan app icons...")
    
    for folder, size in sizes.items():
        # Create directory if it doesn't exist
        folder_path = os.path.join(base_path, folder)
        os.makedirs(folder_path, exist_ok=True)
        
        # Generate icon
        icon = create_vmurugan_icon(size)
        
        # Save icon
        icon_path = os.path.join(folder_path, "ic_launcher.png")
        icon.save(icon_path, "PNG")
        
        print(f"✅ Created {icon_path} ({size}x{size})")
    
    print("🎉 VMUrugan app icons created successfully!")
    print("📱 Rebuild your APK to see the new logo")

if __name__ == "__main__":
    main()
