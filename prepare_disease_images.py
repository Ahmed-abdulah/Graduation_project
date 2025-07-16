#!/usr/bin/env python3
"""
Disease-Specific X-ray Image Preparation
Prepares different X-ray images for various medical conditions
"""

import cv2
import numpy as np
import sys
import os
from pathlib import Path

# Medical conditions and their typical X-ray characteristics
DISEASE_PATTERNS = {
    "normal": {
        "description": "Normal chest X-ray",
        "characteristics": "Clear lung fields, normal heart size, no abnormalities"
    },
    "pneumonia": {
        "description": "Pneumonia - lung infection",
        "characteristics": "Patchy opacities, consolidation in lung fields"
    },
    "pneumothorax": {
        "description": "Pneumothorax - collapsed lung",
        "characteristics": "Air in pleural space, lung edge visible"
    },
    "atelectasis": {
        "description": "Atelectasis - partial lung collapse",
        "characteristics": "Linear opacities, volume loss"
    },
    "effusion": {
        "description": "Pleural effusion - fluid around lungs",
        "characteristics": "Blunting of costophrenic angles, fluid level"
    },
    "cardiomegaly": {
        "description": "Cardiomegaly - enlarged heart",
        "characteristics": "Increased cardiac silhouette"
    },
    "nodule": {
        "description": "Pulmonary nodule",
        "characteristics": "Round opacity, well-defined borders"
    },
    "mass": {
        "description": "Lung mass",
        "characteristics": "Large opacity, irregular borders"
    },
    "consolidation": {
        "description": "Lung consolidation",
        "characteristics": "Dense opacification, air bronchograms"
    },
    "emphysema": {
        "description": "Emphysema",
        "characteristics": "Hyperinflated lungs, flattened diaphragm"
    }
}

def create_synthetic_disease_pattern(disease_type, size=(224, 224)):
    """
    Create synthetic X-ray patterns for different diseases
    """
    img = np.zeros(size, dtype=np.uint8)
    
    if disease_type == "normal":
        # Normal chest X-ray - clear lung fields
        img = np.random.normal(128, 30, size).astype(np.uint8)
        # Add some normal anatomical structures
        img[100:150, 80:180] = np.random.normal(140, 20, (50, 100)).astype(np.uint8)
        
    elif disease_type == "pneumonia":
        # Pneumonia - patchy opacities
        img = np.random.normal(128, 30, size).astype(np.uint8)
        # Add patchy opacities
        for _ in range(5):
            x, y = np.random.randint(50, 174, 2)
            radius = np.random.randint(10, 30)
            cv2.circle(img, (x, y), radius, np.random.randint(180, 220), -1)
        
    elif disease_type == "pneumothorax":
        # Pneumothorax - air in pleural space
        img = np.random.normal(128, 30, size).astype(np.uint8)
        # Add air pocket (dark area)
        cv2.ellipse(img, (112, 100), (40, 60), 0, 0, 360, 50, -1)
        # Add lung edge
        cv2.ellipse(img, (112, 100), (35, 55), 0, 0, 360, 200, 2)
        
    elif disease_type == "atelectasis":
        # Atelectasis - linear opacities
        img = np.random.normal(128, 30, size).astype(np.uint8)
        # Add linear opacities
        for i in range(3):
            y = 80 + i * 30
            cv2.line(img, (60, y), (164, y), 180, 3)
        
    elif disease_type == "effusion":
        # Pleural effusion - fluid level
        img = np.random.normal(128, 30, size).astype(np.uint8)
        # Add fluid level (horizontal line)
        cv2.line(img, (50, 150), (174, 150), 200, 5)
        # Add fluid below the line
        img[150:, :] = np.random.normal(180, 20, (74, 224)).astype(np.uint8)
        
    elif disease_type == "cardiomegaly":
        # Cardiomegaly - enlarged heart
        img = np.random.normal(128, 30, size).astype(np.uint8)
        # Add enlarged heart shadow
        cv2.ellipse(img, (112, 120), (60, 40), 0, 0, 360, 160, -1)
        
    elif disease_type == "nodule":
        # Pulmonary nodule
        img = np.random.normal(128, 30, size).astype(np.uint8)
        # Add round nodule
        cv2.circle(img, (112, 100), 15, 180, -1)
        
    elif disease_type == "mass":
        # Lung mass
        img = np.random.normal(128, 30, size).astype(np.uint8)
        # Add large irregular mass
        points = np.array([[90, 80], [130, 70], [140, 120], [100, 130]], np.int32)
        cv2.fillPoly(img, [points], 190)
        
    elif disease_type == "consolidation":
        # Lung consolidation
        img = np.random.normal(128, 30, size).astype(np.uint8)
        # Add dense consolidation
        cv2.rectangle(img, (80, 60), (144, 140), 200, -1)
        # Add air bronchograms (bright lines)
        for i in range(3):
            x = 90 + i * 15
            cv2.line(img, (x, 70), (x, 130), 100, 2)
        
    elif disease_type == "emphysema":
        # Emphysema - hyperinflated lungs
        img = np.random.normal(128, 30, size).astype(np.uint8)
        # Add hyperinflated appearance
        img[40:180, :] = np.random.normal(110, 25, (140, 224)).astype(np.uint8)
        # Flattened diaphragm
        cv2.line(img, (50, 180), (174, 180), 150, 3)
        
    else:
        # Default - random pattern
        img = np.random.randint(0, 256, size, dtype=np.uint8)
    
    return img

def convert_image_to_mem(image_path, output_path="test_image.mem", target_size=(224, 224)):
    """
    Convert an image to the memory format needed for hardware testing
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
    
    # Convert to grayscale
    if len(img_resized.shape) == 3:
        img_gray = cv2.cvtColor(img_resized, cv2.COLOR_RGB2GRAY)
    else:
        img_gray = img_resized
    
    print(f"Final grayscale image size: {img_gray.shape}")
    print(f"Value range: {img_gray.min()} to {img_gray.max()}")
    
    # Convert to memory format
    height, width = img_gray.shape
    total_pixels = height * width
    
    print(f"Total pixels: {total_pixels}")
    
    # Write to memory file
    try:
        with open(output_path, 'w') as f:
            for y in range(height):
                for x in range(width):
                    pixel_value = img_gray[y, x]
                    hex_value = f"{pixel_value:02x}"
                    f.write(f"{hex_value}\n")
        
        print(f"Successfully wrote {total_pixels} pixel values to {output_path}")
        return True
        
    except Exception as e:
        print(f"Error writing memory file: {e}")
        return False

def create_disease_test_images():
    """Create synthetic test images for all diseases"""
    print("Creating synthetic disease test images...")
    print("=" * 50)
    
    for disease, info in DISEASE_PATTERNS.items():
        print(f"\n🏥 Creating {disease.upper()} pattern:")
        print(f"   Description: {info['description']}")
        print(f"   Characteristics: {info['characteristics']}")
        
        # Create synthetic pattern
        img = create_synthetic_disease_pattern(disease)
        
        # Save as PNG for visualization
        png_path = f"disease_{disease}.png"
        cv2.imwrite(png_path, img)
        
        # Convert to memory format
        mem_path = f"disease_{disease}.mem"
        success = convert_image_to_mem_from_array(img, mem_path)
        
        if success:
            print(f"   ✓ Created: {png_path} and {mem_path}")
        else:
            print(f"   ✗ Failed to create {disease} pattern")
    
    print("\n🎉 All disease patterns created!")
    print("\n📋 Usage:")
    print("1. Copy any disease pattern to test_image.mem:")
    print("   cp disease_pneumonia.mem test_image.mem")
    print("2. Run simulation:")
    print("   vsim -do run_tb_full_system_top.do")
    print("3. Analyze results:")
    print("   python analyze_disease_hex_outputs.py")

def convert_image_to_mem_from_array(img_array, output_path):
    """Convert numpy array to memory format"""
    try:
        height, width = img_array.shape
        total_pixels = height * width
        
        with open(output_path, 'w') as f:
            for y in range(height):
                for x in range(width):
                    pixel_value = img_array[y, x]
                    hex_value = f"{pixel_value:02x}"
                    f.write(f"{hex_value}\n")
        
        return True
    except Exception as e:
        print(f"Error: {e}")
        return False

def main():
    """Main function"""
    print("🏥 Disease-Specific X-ray Image Preparation")
    print("=" * 50)
    print()
    
    if len(sys.argv) < 2:
        print("Usage:")
        print("  python prepare_disease_images.py <image_path>")
        print("  python prepare_disease_images.py --diseases")
        print("  python prepare_disease_images.py --disease <disease_name>")
        print()
        print("Available diseases:")
        for disease, info in DISEASE_PATTERNS.items():
            print(f"  - {disease}: {info['description']}")
        print()
        print("Examples:")
        print("  python prepare_disease_images.py chest_xray.jpg")
        print("  python prepare_disease_images.py --diseases")
        print("  python prepare_disease_images.py --disease pneumonia")
        return
    
    if sys.argv[1] == "--diseases":
        create_disease_test_images()
        return
    
    if sys.argv[1] == "--disease" and len(sys.argv) >= 3:
        disease_name = sys.argv[2]
        if disease_name in DISEASE_PATTERNS:
            print(f"Creating {disease_name} pattern...")
            img = create_synthetic_disease_pattern(disease_name)
            
            # Save as PNG
            png_path = f"disease_{disease_name}.png"
            cv2.imwrite(png_path, img)
            
            # Convert to memory format
            mem_path = f"disease_{disease_name}.mem"
            success = convert_image_to_mem_from_array(img, mem_path)
            
            if success:
                print(f"✓ Created: {png_path} and {mem_path}")
                print(f"\nTo use this pattern:")
                print(f"  cp {mem_path} test_image.mem")
                print(f"  vsim -do run_tb_full_system_top.do")
            else:
                print("✗ Failed to create pattern")
        else:
            print(f"Unknown disease: {disease_name}")
            print("Available diseases:")
            for disease in DISEASE_PATTERNS.keys():
                print(f"  - {disease}")
        return
    
    # Regular image conversion
    image_path = sys.argv[1]
    
    if not os.path.exists(image_path):
        print(f"Error: Image file {image_path} not found")
        return
    
    # Convert image
    success = convert_image_to_mem(image_path)
    
    if success:
        print("\n✓ Image conversion successful!")
        print("\nNext steps:")
        print("1. Run the hardware simulation:")
        print("   vsim -do run_tb_full_system_top.do")
        print("2. Analyze the results:")
        print("   python analyze_disease_hex_outputs.py")
    else:
        print("\n✗ Image conversion failed!")

if __name__ == "__main__":
    main() 