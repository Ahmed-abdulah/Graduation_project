#!/usr/bin/env python3
"""
Disease-Specific X-ray Image Preparation (Simple Version)
Creates synthetic X-ray patterns for different medical conditions
"""

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
    Create synthetic X-ray patterns for different diseases using numpy only
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
        # Add patchy opacities (circles)
        for _ in range(5):
            x, y = np.random.randint(50, 174, 2)
            radius = np.random.randint(10, 30)
            # Create circle pattern
            for i in range(max(0, y-radius), min(224, y+radius)):
                for j in range(max(0, x-radius), min(224, x+radius)):
                    if (i-y)**2 + (j-x)**2 <= radius**2:
                        img[i, j] = np.random.randint(180, 220)
        
    elif disease_type == "pneumothorax":
        # Pneumothorax - air in pleural space
        img = np.random.normal(128, 30, size).astype(np.uint8)
        # Add air pocket (dark area) - ellipse shape
        center_x, center_y = 112, 100
        for i in range(224):
            for j in range(224):
                # Check if point is inside ellipse
                if ((i-center_y)**2/60**2 + (j-center_x)**2/40**2) <= 1:
                    img[i, j] = 50  # Dark area
                # Add lung edge
                elif ((i-center_y)**2/55**2 + (j-center_x)**2/35**2) <= 1:
                    img[i, j] = 200  # Bright edge
        
    elif disease_type == "atelectasis":
        # Atelectasis - linear opacities
        img = np.random.normal(128, 30, size).astype(np.uint8)
        # Add linear opacities (horizontal lines)
        for i in range(3):
            y = 80 + i * 30
            img[y-2:y+3, 60:164] = 180
        
    elif disease_type == "effusion":
        # Pleural effusion - fluid level
        img = np.random.normal(128, 30, size).astype(np.uint8)
        # Add fluid level (horizontal line)
        img[148:153, 50:174] = 200
        # Add fluid below the line
        img[150:, :] = np.random.normal(180, 20, (74, 224)).astype(np.uint8)
        
    elif disease_type == "cardiomegaly":
        # Cardiomegaly - enlarged heart
        img = np.random.normal(128, 30, size).astype(np.uint8)
        # Add enlarged heart shadow (ellipse)
        center_x, center_y = 112, 120
        for i in range(224):
            for j in range(224):
                if ((i-center_y)**2/40**2 + (j-center_x)**2/60**2) <= 1:
                    img[i, j] = 160
        
    elif disease_type == "nodule":
        # Pulmonary nodule
        img = np.random.normal(128, 30, size).astype(np.uint8)
        # Add round nodule
        center_x, center_y = 112, 100
        radius = 15
        for i in range(224):
            for j in range(224):
                if (i-center_y)**2 + (j-center_x)**2 <= radius**2:
                    img[i, j] = 180
        
    elif disease_type == "mass":
        # Lung mass
        img = np.random.normal(128, 30, size).astype(np.uint8)
        # Add large irregular mass (polygon)
        points = [(90, 80), (130, 70), (140, 120), (100, 130)]
        # Simple rectangular mass
        img[80:130, 90:140] = 190
        
    elif disease_type == "consolidation":
        # Lung consolidation
        img = np.random.normal(128, 30, size).astype(np.uint8)
        # Add dense consolidation
        img[60:140, 80:144] = 200
        # Add air bronchograms (bright lines)
        for i in range(3):
            x = 90 + i * 15
            img[70:130, x-1:x+2] = 100
        
    elif disease_type == "emphysema":
        # Emphysema - hyperinflated lungs
        img = np.random.normal(128, 30, size).astype(np.uint8)
        # Add hyperinflated appearance
        img[40:180, :] = np.random.normal(110, 25, (140, 224)).astype(np.uint8)
        # Flattened diaphragm
        img[178:183, 50:174] = 150
        
    else:
        # Default - random pattern
        img = np.random.randint(0, 256, size, dtype=np.uint8)
    
    return img

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
        
        print(f"   ✓ Created {output_path} ({total_pixels} pixels)")
        return True
    except Exception as e:
        print(f"   ✗ Error: {e}")
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
        
        # Convert to memory format
        mem_path = f"disease_{disease}.mem"
        success = convert_image_to_mem_from_array(img, mem_path)
        
        if success:
            print(f"   ✓ Pattern created successfully")
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

def create_single_disease_pattern(disease_name):
    """Create a single disease pattern"""
    if disease_name not in DISEASE_PATTERNS:
        print(f"Unknown disease: {disease_name}")
        print("Available diseases:")
        for disease in DISEASE_PATTERNS.keys():
            print(f"  - {disease}")
        return False
    
    print(f"Creating {disease_name} pattern...")
    print(f"Description: {DISEASE_PATTERNS[disease_name]['description']}")
    print(f"Characteristics: {DISEASE_PATTERNS[disease_name]['characteristics']}")
    
    # Create synthetic pattern
    img = create_synthetic_disease_pattern(disease_name)
    
    # Convert to memory format
    mem_path = f"disease_{disease_name}.mem"
    success = convert_image_to_mem_from_array(img, mem_path)
    
    if success:
        print(f"\n✓ Created: {mem_path}")
        print(f"\nTo use this pattern:")
        print(f"  cp {mem_path} test_image.mem")
        print(f"  vsim -do run_tb_full_system_top.do")
        return True
    else:
        print("✗ Failed to create pattern")
        return False

def main():
    """Main function"""
    print("🏥 Disease-Specific X-ray Image Preparation (Simple)")
    print("=" * 55)
    print()
    
    if len(sys.argv) < 2:
        print("Usage:")
        print("  python prepare_disease_images_simple.py --diseases")
        print("  python prepare_disease_images_simple.py --disease <disease_name>")
        print()
        print("Available diseases:")
        for disease, info in DISEASE_PATTERNS.items():
            print(f"  - {disease}: {info['description']}")
        print()
        print("Examples:")
        print("  python prepare_disease_images_simple.py --diseases")
        print("  python prepare_disease_images_simple.py --disease pneumonia")
        return
    
    if sys.argv[1] == "--diseases":
        create_disease_test_images()
        return
    
    if sys.argv[1] == "--disease" and len(sys.argv) >= 3:
        disease_name = sys.argv[2]
        create_single_disease_pattern(disease_name)
        return
    
    print("Invalid command. Use --diseases or --disease <name>")

if __name__ == "__main__":
    main() 