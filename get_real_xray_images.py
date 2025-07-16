#!/usr/bin/env python3
"""
Real X-ray Image Sources and Preparation
Information about where to get real chest X-ray images
"""

import os
import sys
from pathlib import Path

# Public datasets with real chest X-ray images
PUBLIC_DATASETS = {
    "chestxray14": {
        "name": "ChestX-ray14",
        "description": "Large dataset with 112,120 chest X-ray images",
        "diseases": ["Atelectasis", "Cardiomegaly", "Consolidation", "Edema", "Effusion", "Emphysema", "Fibrosis", "Hernia", "Infiltration", "Mass", "Nodule", "Pleural_Thickening", "Pneumonia", "Pneumothorax"],
        "source": "https://nihcc.app.box.com/v/ChestXray-NIHCC",
        "size": "~40GB",
        "license": "Public domain",
        "paper": "https://arxiv.org/abs/1705.02315"
    },
    "chestxray8": {
        "name": "ChestX-ray8",
        "description": "Dataset with 108,948 chest X-ray images",
        "diseases": ["Atelectasis", "Cardiomegaly", "Consolidation", "Edema", "Effusion", "Emphysema", "Fibrosis", "Hernia", "Infiltration", "Mass", "Nodule", "Pleural_Thickening", "Pneumonia", "Pneumothorax"],
        "source": "https://github.com/ieee8023/covid-chestxray-dataset",
        "size": "~35GB",
        "license": "Public domain",
        "paper": "https://arxiv.org/abs/1705.02315"
    },
    "covid19": {
        "name": "COVID-19 Chest X-ray Dataset",
        "description": "Dataset focused on COVID-19 and related conditions",
        "diseases": ["COVID-19", "Pneumonia", "Normal"],
        "source": "https://github.com/ieee8023/covid-chestxray-dataset",
        "size": "~2GB",
        "license": "Public domain",
        "paper": "https://arxiv.org/abs/2003.11597"
    },
    "padchest": {
        "name": "PadChest",
        "description": "Large dataset with 160,868 chest X-ray images",
        "diseases": ["Atelectasis", "Cardiomegaly", "Consolidation", "Edema", "Effusion", "Emphysema", "Fibrosis", "Hernia", "Infiltration", "Mass", "Nodule", "Pleural_Thickening", "Pneumonia", "Pneumothorax"],
        "source": "https://bimcv.cipf.es/bimcv-projects/padchest/",
        "size": "~50GB",
        "license": "Creative Commons",
        "paper": "https://arxiv.org/abs/1901.07441"
    }
}

def show_dataset_info():
    """Show information about available datasets"""
    print("🏥 REAL CHEST X-RAY IMAGE SOURCES")
    print("=" * 80)
    print()
    
    for key, dataset in PUBLIC_DATASETS.items():
        print(f"📊 {dataset['name']}")
        print(f"   Description: {dataset['description']}")
        print(f"   Diseases: {', '.join(dataset['diseases'])}")
        print(f"   Source: {dataset['source']}")
        print(f"   Size: {dataset['size']}")
        print(f"   License: {dataset['license']}")
        print(f"   Paper: {dataset['paper']}")
        print()
    
    print("📋 HOW TO GET REAL IMAGES:")
    print("-" * 80)
    print("1. Download from public datasets (links above)")
    print("2. Use medical image repositories")
    print("3. Collaborate with medical institutions")
    print("4. Use synthetic patterns (current approach)")
    print()

def prepare_real_image(image_path):
    """Prepare a real X-ray image for testing"""
    print(f"Preparing real X-ray image: {image_path}")
    print()
    
    if not os.path.exists(image_path):
        print(f"❌ Error: Image file {image_path} not found")
        return False
    
    # Use the existing prepare_test_image.py script
    print("Converting real image to memory format...")
    print()
    
    # Import and use the conversion function
    try:
        from prepare_test_image import convert_image_to_mem
        success = convert_image_to_mem(image_path, "test_image.mem")
        
        if success:
            print("✅ Real image converted successfully!")
            print("📋 Next steps:")
            print("   vsim -do run_tb_full_system_top.do")
            print("   python analyze_disease_hex_outputs.py")
            return True
        else:
            print("❌ Image conversion failed")
            return False
            
    except ImportError:
        print("❌ Error: prepare_test_image.py not found")
        print("📋 Manual conversion needed")
        return False

def create_sample_download_script():
    """Create a script to download sample images"""
    script_content = '''#!/bin/bash
# Sample script to download chest X-ray images
# This is a template - modify as needed

echo "Downloading sample chest X-ray images..."

# Create images directory
mkdir -p real_xray_images

# Download sample images (example URLs - replace with actual sources)
# wget -O real_xray_images/pneumonia.jpg "https://example.com/pneumonia.jpg"
# wget -O real_xray_images/normal.jpg "https://example.com/normal.jpg"
# wget -O real_xray_images/pneumothorax.jpg "https://example.com/pneumothorax.jpg"

echo "Download complete!"
echo "Convert images using:"
echo "  python prepare_test_image.py real_xray_images/pneumonia.jpg"
'''
    
    with open("download_sample_images.sh", "w") as f:
        f.write(script_content)
    
    print("📄 Created download_sample_images.sh template")
    print("📋 Edit the script with actual image URLs")

def show_ethical_guidelines():
    """Show ethical guidelines for medical images"""
    print("⚖️ ETHICAL GUIDELINES FOR MEDICAL IMAGES")
    print("=" * 80)
    print()
    print("1. **Patient Privacy**: Never use images with patient identifiers")
    print("2. **Informed Consent**: Only use images with proper consent")
    print("3. **Data Protection**: Follow HIPAA and GDPR guidelines")
    print("4. **Research Purposes**: Use only for research/educational purposes")
    print("5. **Medical Disclaimer**: Always include medical disclaimers")
    print("6. **Professional Review**: Have medical professionals review results")
    print()
    print("📋 RECOMMENDED APPROACHES:")
    print("- Use de-identified public datasets")
    print("- Work with medical institutions")
    print("- Use synthetic patterns for testing")
    print("- Include proper disclaimers")
    print()

def main():
    """Main function"""
    print("🏥 Real X-ray Image Sources and Preparation")
    print("=" * 60)
    print()
    
    if len(sys.argv) < 2:
        print("Usage:")
        print("  python get_real_xray_images.py --datasets")
        print("  python get_real_xray_images.py --prepare <image_path>")
        print("  python get_real_xray_images.py --download")
        print("  python get_real_xray_images.py --ethics")
        print()
        print("Examples:")
        print("  python get_real_xray_images.py --datasets")
        print("  python get_real_xray_images.py --prepare pneumonia.jpg")
        print("  python get_real_xray_images.py --ethics")
        return
    
    if sys.argv[1] == "--datasets":
        show_dataset_info()
    elif sys.argv[1] == "--prepare" and len(sys.argv) >= 3:
        image_path = sys.argv[2]
        prepare_real_image(image_path)
    elif sys.argv[1] == "--download":
        create_sample_download_script()
    elif sys.argv[1] == "--ethics":
        show_ethical_guidelines()
    else:
        print("Invalid command. Use --datasets, --prepare, --download, or --ethics")

if __name__ == "__main__":
    main() 