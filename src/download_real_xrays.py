#!/usr/bin/env python3
"""
Real Medical X-ray Downloader
Downloads real chest X-rays from public medical databases
"""

import requests
import os
from PIL import Image
import numpy as np

def download_image(url, filename):
    """Download image from URL"""
    try:
        headers = {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
        }
        response = requests.get(url, headers=headers, timeout=30)
        response.raise_for_status()
        
        with open(filename, 'wb') as f:
            f.write(response.content)
        
        print(f"✅ Downloaded: {filename}")
        return True
    except Exception as e:
        print(f"❌ Failed to download {filename}: {e}")
        return False

def convert_to_mem_file(image_path, mem_filename):
    """Convert downloaded image to neural network format"""
    try:
        # Load and process image
        img = Image.open(image_path)
        print(f"📊 Original image: {img.size} pixels, mode: {img.mode}")
        
        # Convert to grayscale
        if img.mode != 'L':
            img = img.convert('L')
        
        # Resize to 224x224
        img = img.resize((224, 224), Image.Resampling.LANCZOS)
        
        # Convert to numpy array
        img_array = np.array(img)
        
        # Convert 8-bit to 16-bit
        img_16bit = (img_array.astype(np.uint32) * 257).astype(np.uint16)
        
        # Save as memory file
        with open(mem_filename, 'w') as f:
            for pixel in img_16bit.flatten():
                f.write(f"{pixel:04x}\n")
        
        print(f"✅ Converted to: {mem_filename}")
        print(f"📈 Pixel range: {img_16bit.min()} to {img_16bit.max()}")
        return True
        
    except Exception as e:
        print(f"❌ Conversion failed: {e}")
        return False

def download_real_medical_cases():
    """Download real medical X-ray cases"""
    
    print("🏥 DOWNLOADING REAL MEDICAL X-RAY CASES")
    print("=" * 50)
    
    # Real medical X-ray URLs (public domain/educational use)
    test_cases = [
        {
            "name": "Normal Chest X-ray",
            "url": "https://upload.wikimedia.org/wikipedia/commons/thumb/4/4f/Chest_X-ray_normal.jpg/512px-Chest_X-ray_normal.jpg",
            "filename": "real_normal_xray.jpg",
            "mem_file": "real_normal_xray.mem",
            "expected": "No Finding"
        },
        {
            "name": "Pneumonia Case",
            "url": "https://upload.wikimedia.org/wikipedia/commons/thumb/2/20/Pneumonia_x-ray.jpg/512px-Pneumonia_x-ray.jpg",
            "filename": "real_pneumonia_xray.jpg", 
            "mem_file": "real_pneumonia_xray.mem",
            "expected": "Pneumonia"
        },
        {
            "name": "Cardiomegaly Case",
            "url": "https://upload.wikimedia.org/wikipedia/commons/thumb/8/8f/Cardiomegaly.jpg/512px-Cardiomegaly.jpg",
            "filename": "real_cardiomegaly_xray.jpg",
            "mem_file": "real_cardiomegaly_xray.mem", 
            "expected": "Cardiomegaly"
        },
        {
            "name": "Pleural Effusion",
            "url": "https://upload.wikimedia.org/wikipedia/commons/thumb/b/b8/Pleural_effusion_x-ray.jpg/512px-Pleural_effusion_x-ray.jpg",
            "filename": "real_effusion_xray.jpg",
            "mem_file": "real_effusion_xray.mem",
            "expected": "Effusion"
        }
    ]
    
    successful_downloads = []
    
    for case in test_cases:
        print(f"\n📥 Downloading: {case['name']}")
        print(f"🔗 URL: {case['url']}")
        
        # Download image
        if download_image(case['url'], case['filename']):
            # Convert to memory file
            if convert_to_mem_file(case['filename'], case['mem_file']):
                successful_downloads.append(case)
                print(f"🎯 Expected diagnosis: {case['expected']}")
    
    print(f"\n🎉 DOWNLOAD SUMMARY")
    print(f"=" * 30)
    print(f"✅ Successfully downloaded: {len(successful_downloads)} cases")
    
    for case in successful_downloads:
        print(f"  📁 {case['mem_file']} - {case['name']} (expect: {case['expected']})")
    
    print(f"\n🔬 TESTING INSTRUCTIONS:")
    print(f"1. Copy the .mem files to your testbench directory")
    print(f"2. Update your testbench to load these files:")
    print(f"   $readmemh(\"real_pneumonia_xray.mem\", test_images[0]);")
    print(f"   $readmemh(\"real_normal_xray.mem\", test_images[1]);")
    print(f"   $readmemh(\"real_cardiomegaly_xray.mem\", test_images[2]);")
    print(f"   $readmemh(\"real_effusion_xray.mem\", test_images[3]);")
    print(f"3. Run simulation and compare predictions with expected diagnoses")
    
    print(f"\n✅ VALIDATION CRITERIA:")
    print(f"  • Pneumonia case should show high Pneumonia probability")
    print(f"  • Normal case should show high No Finding probability") 
    print(f"  • Cardiomegaly case should show high Cardiomegaly probability")
    print(f"  • Effusion case should show high Effusion probability")
    
    return successful_downloads

if __name__ == "__main__":
    # Install required packages if needed
    try:
        import requests
        from PIL import Image
    except ImportError:
        print("Installing required packages...")
        os.system("pip install requests pillow")
        import requests
        from PIL import Image
    
    download_real_medical_cases()
