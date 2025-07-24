#!/usr/bin/python
"""
Comprehensive Disease Image Converter
Converts all real X-ray disease images to memory files for neural network testing
"""

from PIL import Image
import numpy as np
import os
import sys
from pathlib import Path

# Disease mapping - maps image filenames to disease names and expected classifications
DISEASE_MAPPING = {
    # Real disease images
    "Atelectasis.png": {
        "disease": "Atelectasis", 
        "class_index": 2,
        "description": "Partial lung collapse"
    },
    "Cardiomegaly.png": {
        "disease": "Cardiomegaly", 
        "class_index": 9,
        "description": "Enlarged heart"
    },
    "Consolidation.png": {
        "disease": "Consolidation", 
        "class_index": 7,
        "description": "Lung consolidation"
    },
    "Edema.png": {
        "disease": "Edema", 
        "class_index": 12,
        "description": "Pulmonary edema"
    },
    "Effusion.png": {
        "disease": "Effusion", 
        "class_index": 3,
        "description": "Pleural effusion"
    },
    "Emphysema.png": {
        "disease": "Emphysema", 
        "class_index": 10,
        "description": "Emphysema/COPD"
    },
    "Fibrosis.png": {
        "disease": "Fibrosis", 
        "class_index": 11,
        "description": "Pulmonary fibrosis"
    },
    "Hernia.png": {
        "disease": "Hernia", 
        "class_index": 14,
        "description": "Hiatal hernia"
    },
    "Infiltration.png": {
        "disease": "Infiltration", 
        "class_index": 1,
        "description": "Lung infiltration"
    },
    "Mass.png": {
        "disease": "Mass", 
        "class_index": 6,
        "description": "Lung mass"
    },
    "Nodule.png": {
        "disease": "Nodule", 
        "class_index": 4,
        "description": "Pulmonary nodule"
    },
    "normal.png": {
        "disease": "No Finding", 
        "class_index": 0,
        "description": "Normal chest X-ray"
    },
    "Pleural Thickening.png": {
        "disease": "Pleural_Thickening", 
        "class_index": 8,
        "description": "Pleural thickening"
    },
    "Pleural_Thickening.png": {
        "disease": "Pleural_Thickening", 
        "class_index": 8,
        "description": "Pleural thickening"
    },
    "Pneumonia.png": {
        "disease": "Pneumonia", 
        "class_index": 13,
        "description": "Pneumonia"
    },
    "Pneumothorax.png": {
        "disease": "Pneumothorax", 
        "class_index": 5,
        "description": "Pneumothorax"
    },
    # Additional patterns
    "Chest-X-ray-showing-infiltrate-in-the-right-lung.png": {
        "disease": "Infiltration", 
        "class_index": 1,
        "description": "Lung infiltration (alternative)"
    },
    "pneumonia_xray.png": {
        "disease": "Pneumonia", 
        "class_index": 13,
        "description": "Pneumonia (alternative)"
    },
    "test_image.png": {
        "disease": "Test_Pattern", 
        "class_index": -1,
        "description": "Test pattern"
    }
}

def convert_xray_to_mem(image_path, output_path, disease_info=None):
    """Convert X-ray image to memory file format with detailed analysis"""
    
    print(f"\n🏥 Converting: {os.path.basename(image_path)}")
    if disease_info:
        print(f"   Disease: {disease_info['disease']}")
        print(f"   Description: {disease_info['description']}")
        print(f"   Expected class: {disease_info['class_index']}")
    
    # Step 1: Load image
    try:
        img = Image.open(image_path)
        print(f"   ✅ Loaded: {img.size} pixels, mode: {img.mode}")
    except Exception as e:
        print(f"   ❌ Error loading: {e}")
        return False
    
    # Step 2: Convert to grayscale
    if img.mode != 'L':
        img = img.convert('L')
        print("   ✅ Converted to grayscale")
    
    # Step 3: Resize to 224x224
    original_size = img.size
    img = img.resize((224, 224), Image.Resampling.LANCZOS)
    print(f"   ✅ Resized: {original_size} → 224x224")
    
    # Step 4: Convert to numpy array and analyze
    img_array = np.array(img)
    print(f"   📊 Pixel range: {img_array.min()} to {img_array.max()}")
    print(f"   📊 Average brightness: {np.mean(img_array):.1f}")
    print(f"   📊 Standard deviation: {np.std(img_array):.1f}")
    
    # Step 5: Convert 8-bit (0-255) to 16-bit (0-65535)
    img_16bit = (img_array.astype(np.uint32) * 257).astype(np.uint16)
    
    # Step 6: Flatten to 1D array
    img_flat = img_16bit.flatten()
    print(f"   ✅ 16-bit range: {img_flat.min()} to {img_flat.max()}")
    print(f"   ✅ Total pixels: {len(img_flat)}")
    
    # Step 7: Save as memory file
    try:
        with open(output_path, 'w') as f:
            for pixel in img_flat:
                f.write(f"{pixel:04x}\n")  # Write as 4-digit hex
        print(f"   ✅ Saved: {output_path}")
        return True
    except Exception as e:
        print(f"   ❌ Error saving: {e}")
        return False

def analyze_image_characteristics(image_path):
    """Analyze X-ray image characteristics for medical validation"""
    try:
        img = Image.open(image_path)
        img_gray = img.convert('L')
        img_resized = img_gray.resize((224, 224))
        img_array = np.array(img_resized)
        
        print(f"   🔍 Medical Analysis:")
        print(f"      Average brightness: {np.mean(img_array):.1f}")
        print(f"      Brightness range: {np.min(img_array)} to {np.max(img_array)}")
        print(f"      Standard deviation: {np.std(img_array):.1f}")
        print(f"      Contrast ratio: {(np.max(img_array) - np.min(img_array)):.1f}")
        
        # Medical X-ray characteristics validation
        avg_brightness = np.mean(img_array)
        std_dev = np.std(img_array)
        
        if avg_brightness < 100:
            print("      ✓ Typical X-ray darkness detected")
        if std_dev > 40:
            print("      ✓ Good tissue contrast detected")
        if np.max(img_array) > 200:
            print("      ✓ Bone/metal structures visible")
        if np.min(img_array) < 50:
            print("      ✓ Air-filled spaces detected")
            
        return True
    except Exception as e:
        print(f"      ❌ Analysis failed: {e}")
        return False

def convert_all_disease_images():
    """Convert all available disease images to memory files"""
    
    print("🏥 COMPREHENSIVE DISEASE IMAGE CONVERTER")
    print("=" * 60)
    print("Converting all real X-ray disease images to memory files")
    print("=" * 60)
    
    current_dir = Path(".")
    converted_count = 0
    failed_count = 0
    conversion_log = []
    
    # Process each disease image
    for filename, disease_info in DISEASE_MAPPING.items():
        image_path = current_dir / filename
        
        if image_path.exists():
            print(f"\n📁 Found: {filename}")
            
            # Generate output filename
            disease_name = disease_info['disease'].lower().replace(' ', '_').replace('_finding', '')
            output_filename = f"real_{disease_name}_xray.mem"
            
            # Analyze image characteristics
            analyze_image_characteristics(image_path)
            
            # Convert to memory file
            success = convert_xray_to_mem(str(image_path), output_filename, disease_info)
            
            if success:
                converted_count += 1
                conversion_log.append({
                    'input': filename,
                    'output': output_filename,
                    'disease': disease_info['disease'],
                    'class_index': disease_info['class_index'],
                    'status': 'SUCCESS'
                })
            else:
                failed_count += 1
                conversion_log.append({
                    'input': filename,
                    'output': output_filename,
                    'disease': disease_info['disease'],
                    'class_index': disease_info['class_index'],
                    'status': 'FAILED'
                })
        else:
            print(f"\n❌ Not found: {filename}")
            failed_count += 1
    
    # Print summary
    print(f"\n🎯 CONVERSION SUMMARY")
    print("=" * 40)
    print(f"✅ Successfully converted: {converted_count}")
    print(f"❌ Failed conversions: {failed_count}")
    print(f"📊 Total processed: {converted_count + failed_count}")
    
    # Print detailed log
    print(f"\n📋 DETAILED CONVERSION LOG")
    print("=" * 40)
    for entry in conversion_log:
        status_icon = "✅" if entry['status'] == 'SUCCESS' else "❌"
        print(f"{status_icon} {entry['input']} → {entry['output']}")
        print(f"   Disease: {entry['disease']} (Class {entry['class_index']})")
    
    # Generate usage instructions
    if converted_count > 0:
        print(f"\n🔬 USAGE INSTRUCTIONS")
        print("=" * 40)
        print("1. Copy any .mem file to test_image.mem:")
        print("   cp real_pneumonia_xray.mem test_image.mem")
        print("2. Run simulation:")
        print("   vsim -do run_tb_full_system_top.do")
        print("3. Analyze results:")
        print("   python analyze_disease_hex_outputs.py")
        print("\n4. Test all diseases systematically:")
        print("   python test_all_diseases.py")
    
    return conversion_log

if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "--single":
        if len(sys.argv) < 3:
            print("Usage: python convert_all_disease_images.py --single <image_filename>")
            sys.exit(1)
        
        filename = sys.argv[2]
        if filename in DISEASE_MAPPING:
            disease_info = DISEASE_MAPPING[filename]
            disease_name = disease_info['disease'].lower().replace(' ', '_').replace('_finding', '')
            output_filename = f"real_{disease_name}_xray.mem"
            
            if os.path.exists(filename):
                analyze_image_characteristics(filename)
                success = convert_xray_to_mem(filename, output_filename, disease_info)
                if success:
                    print(f"\n✅ Single conversion successful!")
                else:
                    print(f"\n❌ Single conversion failed!")
            else:
                print(f"❌ Image not found: {filename}")
        else:
            print(f"❌ Unknown image: {filename}")
            print("Available images:")
            for img in DISEASE_MAPPING.keys():
                print(f"  - {img}")
    else:
        convert_all_disease_images()
