#!/usr/bin/env python3
"""
Generate 5 test cases for each disease in the dataset
"""

import numpy as np
import os
import sys
from pathlib import Path
from prepare_disease_images_simple import DISEASE_PATTERNS, create_synthetic_disease_pattern

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

def apply_variation(base_img, variation_type, variation_strength=1.0):
    """Apply a specific variation to the base image"""
    img = np.copy(base_img)
    
    if variation_type == "noise":
        # Add random noise
        noise_level = int(15 * variation_strength)
        noise = np.random.normal(0, noise_level, img.shape).astype(np.int16)
        img = np.clip(img.astype(np.int16) + noise, 0, 255).astype(np.uint8)
    
    elif variation_type == "brightness":
        # Adjust brightness
        factor = 1.0 + (variation_strength * 0.3 * (np.random.random() - 0.5))
        img = np.clip(img.astype(np.float32) * factor, 0, 255).astype(np.uint8)
    
    elif variation_type == "contrast":
        # Adjust contrast
        factor = 1.0 + (variation_strength * 0.4 * (np.random.random() - 0.5))
        mean = np.mean(img)
        img = np.clip(mean + factor * (img.astype(np.float32) - mean), 0, 255).astype(np.uint8)
    
    elif variation_type == "shift":
        # Shift image
        max_shift = int(20 * variation_strength)
        shift_x = np.random.randint(-max_shift, max_shift + 1)
        shift_y = np.random.randint(-max_shift, max_shift + 1)
        
        height, width = img.shape
        shifted = np.zeros_like(img)
        
        # Calculate source and destination regions
        src_x_start = max(0, -shift_x)
        src_y_start = max(0, -shift_y)
        dst_x_start = max(0, shift_x)
        dst_y_start = max(0, shift_y)
        
        src_x_end = min(width, width - shift_x)
        src_y_end = min(height, height - shift_y)
        dst_x_end = min(width, width + shift_x)
        dst_y_end = min(height, height + shift_y)
        
        # Copy shifted region
        shifted[dst_y_start:dst_y_end, dst_x_start:dst_x_end] = img[src_y_start:src_y_end, src_x_start:src_x_end]
        img = shifted
    
    elif variation_type == "intensity":
        # Vary intensity of disease features
        # This is a simplified approach - in real implementation, you would
        # identify the disease features and modify their intensity
        mask = img > np.mean(img)
        img[mask] = np.clip(img[mask] * (1.0 + 0.2 * variation_strength * (np.random.random() - 0.5)), 0, 255).astype(np.uint8)
    
    return img

def generate_test_cases(disease_name, num_cases=5):
    """Generate multiple test cases for a specific disease"""
    if disease_name not in DISEASE_PATTERNS:
        print(f"Unknown disease: {disease_name}")
        return False
    
    print(f"\n🏥 Generating {num_cases} test cases for {disease_name.upper()}:")
    print(f"   Description: {DISEASE_PATTERNS[disease_name]['description']}")
    
    # Create output directory if it doesn't exist
    output_dir = Path(f"test_cases/{disease_name}")
    output_dir.mkdir(parents=True, exist_ok=True)
    
    # Variation types to apply
    variation_types = ["noise", "brightness", "contrast", "shift", "intensity"]
    
    # Generate base case first
    np.random.seed(42 + hash(disease_name) % 1000)  # Reproducible but different for each disease
    base_img = create_synthetic_disease_pattern(disease_name)
    
    # Save base case
    base_path = output_dir / f"{disease_name}_base.mem"
    convert_image_to_mem_from_array(base_img, base_path)
    
    # Generate variations
    for i in range(1, num_cases):
        # Set a different seed for each variation
        np.random.seed(42 + hash(disease_name) % 1000 + i * 100)
        
        # Select variation type
        var_type = variation_types[i % len(variation_types)]
        
        # Create variation with different strength
        strength = 0.5 + (i / num_cases)
        var_img = apply_variation(base_img, var_type, strength)
        
        # Save variation
        var_path = output_dir / f"{disease_name}_{var_type}_{i}.mem"
        convert_image_to_mem_from_array(var_img, var_path)
        
        print(f"   ✓ Created variation {i}/{num_cases-1}: {var_type} (strength: {strength:.2f})")
    
    # Also create a consolidated directory with numbered test cases
    test_dir = Path("test_cases/numbered")
    test_dir.mkdir(parents=True, exist_ok=True)
    
    # Copy files with numbered names for easier testing
    import shutil
    case_num = 1
    for src_path in output_dir.glob(f"{disease_name}_*.mem"):
        dst_path = test_dir / f"{disease_name}_case{case_num}.mem"
        shutil.copy(src_path, dst_path)
        print(f"   ✓ Created numbered test case: {dst_path}")
        case_num += 1
    
    return True

def generate_all_test_cases(num_cases=5):
    """Generate test cases for all diseases"""
    print("🏥 GENERATING TEST CASES FOR ALL DISEASES")
    print("=" * 50)
    
    results = {}
    for disease in DISEASE_PATTERNS.keys():
        success = generate_test_cases(disease, num_cases)
        results[disease] = success
    
    # Print summary
    print("\n📋 SUMMARY:")
    print("=" * 50)
    
    successful = sum(results.values())
    print(f"Total diseases: {len(results)}")
    print(f"Successfully generated: {successful}")
    print(f"Failed: {len(results) - successful}")
    
    if successful == len(results):
        print("\n✅ All test cases generated successfully!")
        print(f"Created {successful * num_cases} test cases in total")
    else:
        print("\n⚠️ Some test cases could not be generated")
    
    # Print test case locations
    print("\n📁 Test case locations:")
    print("  - Individual variations: ./test_cases/<disease_name>/")
    print("  - Numbered test cases: ./test_cases/numbered/")
    
    # Print usage instructions
    print("\n📋 Usage:")
    print("  To test a specific case:")
    print("  cp test_cases/numbered/pneumonia_case1.mem test_image.mem")
    print("  vsim -do run_tb_full_system_top.do")
    
    return successful == len(results)

def main():
    """Main function"""
    print("🏥 Disease Test Case Generator")
    print("=" * 40)
    
    if len(sys.argv) < 2:
        print("\nUsage:")
        print("  python generate_disease_test_cases.py --all")
        print("  python generate_disease_test_cases.py --disease <disease_name>")
        print("\nAvailable diseases:")
        for disease in DISEASE_PATTERNS.keys():
            print(f"  - {disease}")
        return
    
    if sys.argv[1] == "--all":
        generate_all_test_cases(5)  # Generate 5 test cases for each disease
    elif sys.argv[1] == "--disease" and len(sys.argv) >= 3:
        disease_name = sys.argv[2]
        generate_test_cases(disease_name, 5)  # Generate 5 test cases for the specified disease
    else:
        print("Invalid command. Use --all or --disease <name>")

if __name__ == "__main__":
    main()