#!/usr/bin/env python3
"""
Test Image Preparation Script
Converts any image to the format needed for hardware testing
"""

import cv2
import numpy as np
import sys
import os
from pathlib import Path

def convert_image_to_mem(image_path, output_path="test_image.mem", target_size=(224, 224)):
    """
    Convert an image to the memory format needed for hardware testing
    
    Args:
        image_path: Path to input image
        output_path: Output memory file path
        target_size: Target image size (width, height)
    """
    
    print(f"Converting image: {image_path}")
    print(f"Target size: {target_size}")
    print(f"Output file: {output_path}")
    print()
    
    # Read image
    try:
        img = cv2.imread(image_path)
        if img is None:
            print(f"Error: Could not read image {image_path}")
            return False
    except Exception as e:
        print(f"Error reading image: {e}")
        return False
    
    print(f"Original image size: {img.shape}")
    
    # Convert BGR to RGB
    img_rgb = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
    
    # Resize image
    img_resized = cv2.resize(img_rgb, target_size)
    print(f"Resized image size: {img_resized.shape}")
    
    # Normalize to 0-255 range (if not already)
    if img_resized.dtype != np.uint8:
        img_resized = np.clip(img_resized, 0, 255).astype(np.uint8)
    
    # Convert to grayscale if needed (for chest X-rays)
    if len(img_resized.shape) == 3:
        img_gray = cv2.cvtColor(img_resized, cv2.COLOR_RGB2GRAY)
    else:
        img_gray = img_resized
    
    print(f"Final grayscale image size: {img_gray.shape}")
    print(f"Value range: {img_gray.min()} to {img_gray.max()}")
    
    # Convert to memory format
    # Each pixel is 8-bit, stored as hex values
    height, width = img_gray.shape
    total_pixels = height * width
    
    print(f"Total pixels: {total_pixels}")
    print(f"Expected memory file size: {total_pixels} lines")
    
    # Write to memory file
    try:
        with open(output_path, 'w') as f:
            for y in range(height):
                for x in range(width):
                    pixel_value = img_gray[y, x]
                    hex_value = f"{pixel_value:02x}"  # 8-bit hex
                    f.write(f"{hex_value}\n")
        
        print(f"Successfully wrote {total_pixels} pixel values to {output_path}")
        
        # Verify file size
        with open(output_path, 'r') as f:
            lines = f.readlines()
        print(f"Actual file lines: {len(lines)}")
        
        if len(lines) == total_pixels:
            print("✓ File size verification passed")
        else:
            print(f"⚠ Warning: Expected {total_pixels} lines, got {len(lines)}")
        
        return True
        
    except Exception as e:
        print(f"Error writing memory file: {e}")
        return False

def create_test_patterns():
    """Create various test patterns for debugging"""
    
    patterns = {
        "zeros": np.zeros((224, 224), dtype=np.uint8),
        "ones": np.ones((224, 224), dtype=np.uint8) * 255,
        "gradient": np.linspace(0, 255, 224*224).reshape(224, 224).astype(np.uint8),
        "checkerboard": np.indices((224, 224)).sum(axis=0) % 2 * 255
    }
    
    for name, pattern in patterns.items():
        output_path = f"test_pattern_{name}.mem"
        print(f"\nCreating test pattern: {name}")
        
        with open(output_path, 'w') as f:
            for y in range(224):
                for x in range(224):
                    pixel_value = pattern[y, x]
                    hex_value = f"{pixel_value:02x}"
                    f.write(f"{hex_value}\n")
        
        print(f"Created: {output_path}")

def main():
    """Main function"""
    print("Test Image Preparation Script")
    print("=" * 40)
    print()
    
    if len(sys.argv) < 2:
        print("Usage:")
        print("  python prepare_test_image.py <image_path>")
        print("  python prepare_test_image.py --patterns")
        print()
        print("Examples:")
        print("  python prepare_test_image.py chest_xray.jpg")
        print("  python prepare_test_image.py pneumonia.png")
        print("  python prepare_test_image.py --patterns")
        return
    
    if sys.argv[1] == "--patterns":
        print("Creating test patterns...")
        create_test_patterns()
        print("\nTest patterns created!")
        print("You can use any of these files as test_image.mem:")
        print("  - test_pattern_zeros.mem (all zeros)")
        print("  - test_pattern_ones.mem (all 255)")
        print("  - test_pattern_gradient.mem (gradient)")
        print("  - test_pattern_checkerboard.mem (checkerboard)")
        return
    
    image_path = sys.argv[1]
    
    if not os.path.exists(image_path):
        print(f"Error: Image file {image_path} not found")
        return
    
    # Convert image
    success = convert_image_to_mem(image_path)
    
    if success:
        print("\n✓ Image conversion successful!")
        print("\nNext steps:")
        print("1. Copy the generated test_image.mem to your project directory")
        print("2. Run the hardware simulation:")
        print("   vsim -do run_tb_full_system_top.do")
        print("3. Analyze the results:")
        print("   python analyze_disease_hex_outputs.py")
    else:
        print("\n✗ Image conversion failed!")

if __name__ == "__main__":
    main() 