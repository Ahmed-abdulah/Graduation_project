from PIL import Image
import numpy as np
import os
import sys

def convert_xray_to_mem(image_path, output_path):
    """Convert X-ray image to memory file format"""
    
    print(f"🏥 Converting X-ray: {image_path}")
    
    # Step 1: Load image
    try:
        img = Image.open(image_path)
        print(f"✅ Loaded image: {img.size} pixels, mode: {img.mode}")
    except Exception as e:
        print(f"❌ Error loading image: {e}")
        return False
    
    # Step 2: Convert to grayscale
    if img.mode != 'L':
        img = img.convert('L')
        print("✅ Converted to grayscale")
    
    # Step 3: Resize to 224x224
    img = img.resize((224, 224), Image.Resampling.LANCZOS)
    print("✅ Resized to 224x224")
    
    # Step 4: Convert to numpy array
    img_array = np.array(img)
    
    # Step 5: Convert 8-bit (0-255) to 16-bit (0-65535)
    img_16bit = (img_array.astype(np.uint32) * 257).astype(np.uint16)
    
    # Step 6: Flatten to 1D array
    img_flat = img_16bit.flatten()
    
    print(f"✅ Pixel range: {img_flat.min()} to {img_flat.max()}")
    print(f"✅ Total pixels: {len(img_flat)}")
    
    # Step 7: Save as memory file
    try:
        with open(output_path, 'w') as f:
            for pixel in img_flat:
                f.write(f"{pixel:04x}\n")  # Write as 4-digit hex
        print(f"✅ Saved to: {output_path}")
        return True
    except Exception as e:
        print(f"❌ Error saving file: {e}")
        return False

def analyze_xray(image_path):
    """Analyze X-ray image characteristics"""
    img = Image.open(image_path)
    img_gray = img.convert('L')
    img_resized = img_gray.resize((224, 224))
    img_array = np.array(img_resized)
    
    print(f"\n📊 X-RAY ANALYSIS:")
    print(f"  Average brightness: {np.mean(img_array):.1f}")
    print(f"  Brightness range: {np.min(img_array)} to {np.max(img_array)}")
    print(f"  Standard deviation: {np.std(img_array):.1f}")
    
    # Check for typical X-ray characteristics
    if np.mean(img_array) < 100:
        print("  🔍 Dark image - typical for X-rays")
    if np.std(img_array) > 50:
        print("  🔍 Good contrast - shows tissue differences")

if __name__ == "__main__":
    # Configuration - can be overridden by command line arguments
    if len(sys.argv) >= 3:
        input_image = sys.argv[1]
        output_mem = sys.argv[2]
    else:
        input_image = "pneumonia_xray.png"  # Put your X-ray image here
        output_mem = "real_pneumonia_xray.mem"
    
    print("🏥 REAL X-RAY CONVERTER")
    print("=" * 40)
    
    # Check if input image exists
    if not os.path.exists(input_image):
        print(f"❌ Image not found: {input_image}")
        print("\n📋 INSTRUCTIONS:")
        print("1. Download a real chest X-ray image")
        print("2. Save it as 'pneumonia_xray.png' in this folder")
        print("3. Run this script again")
        exit(1)
    
    # Analyze the image
    analyze_xray(input_image)
    
    # Convert to memory file
    success = convert_xray_to_mem(input_image, output_mem)
    
    if success:
        print(f"\n🎯 SUCCESS!")
        print(f"✅ Real X-ray converted to: {output_mem}")
        print(f"✅ Ready for neural network testing")
        print(f"\n📋 NEXT STEPS:")
        print(f"1. Copy {output_mem} to your testbench folder")
        print(f"2. Update testbench to load this file")
        print(f"3. Run simulation to test real X-ray")
    else:
        print(f"\n❌ CONVERSION FAILED")