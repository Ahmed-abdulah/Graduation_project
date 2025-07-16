#!/usr/bin/env python3
"""
Medical X-ray Test Case Generator
Creates synthetic X-ray patterns that simulate different medical conditions
"""

import numpy as np
import matplotlib.pyplot as plt
from PIL import Image
import os

def create_normal_xray():
    """Create normal chest X-ray pattern"""
    img = np.zeros((224, 224), dtype=np.uint8)
    
    # Normal lung fields (darker areas)
    for row in range(50, 180):
        for col in range(30, 90):  # Left lung
            img[row, col] = 40 + np.random.randint(0, 30)
        for col in range(130, 190):  # Right lung
            img[row, col] = 40 + np.random.randint(0, 30)
    
    # Heart shadow (brighter)
    for row in range(100, 170):
        for col in range(90, 130):
            if (row-135)**2 + (col-110)**2 < 800:
                img[row, col] = 120 + np.random.randint(0, 40)
    
    # Ribs (bright lines)
    for i in range(6):
        y = 60 + i * 20
        for col in range(20, 200):
            if 50 < col < 170:
                img[y:y+2, col] = 180 + np.random.randint(0, 30)
    
    return img

def create_pneumonia_xray():
    """Create pneumonia pattern - consolidation in lower lobes"""
    img = create_normal_xray()
    
    # Add consolidation (bright patches) in lower lungs
    for row in range(140, 180):
        for col in range(40, 80):  # Left lower lobe
            if np.random.random() > 0.3:
                img[row, col] = 160 + np.random.randint(0, 60)
        for col in range(140, 180):  # Right lower lobe
            if np.random.random() > 0.4:
                img[row, col] = 150 + np.random.randint(0, 50)
    
    return img

def create_cardiomegaly_xray():
    """Create enlarged heart pattern"""
    img = create_normal_xray()
    
    # Enlarged heart shadow
    for row in range(90, 180):
        for col in range(80, 140):
            if (row-135)**2 + (col-110)**2 < 1400:  # Larger heart
                img[row, col] = 140 + np.random.randint(0, 50)
    
    return img

def create_pneumothorax_xray():
    """Create pneumothorax pattern - air in pleural space"""
    img = create_normal_xray()
    
    # Dark area indicating air (left side)
    for row in range(60, 140):
        for col in range(20, 60):
            img[row, col] = 10 + np.random.randint(0, 20)
    
    # Collapsed lung edge
    for row in range(60, 140):
        img[row, 60:62] = 200
    
    return img

def create_pleural_effusion_xray():
    """Create pleural effusion - fluid at lung bases"""
    img = create_normal_xray()
    
    # Fluid at bottom (bright areas)
    for row in range(160, 190):
        for col in range(30, 90):  # Left base
            img[row, col] = 180 + np.random.randint(0, 40)
        for col in range(130, 190):  # Right base
            img[row, col] = 170 + np.random.randint(0, 30)
    
    return img

def create_nodule_xray():
    """Create lung nodule pattern"""
    img = create_normal_xray()
    
    # Small round nodules
    centers = [(80, 60), (120, 150), (100, 70)]
    for cy, cx in centers:
        for row in range(cy-8, cy+8):
            for col in range(cx-8, cx+8):
                if (row-cy)**2 + (col-cx)**2 < 25:
                    img[row, col] = 180 + np.random.randint(0, 40)
    
    return img

def create_emphysema_xray():
    """Create emphysema pattern - hyperinflated lungs"""
    img = create_normal_xray()
    
    # Make lungs darker (hyperinflated)
    for row in range(40, 180):
        for col in range(20, 100):  # Left lung
            img[row, col] = max(0, img[row, col] - 30)
        for col in range(120, 200):  # Right lung
            img[row, col] = max(0, img[row, col] - 30)
    
    # Flattened diaphragm
    for col in range(30, 190):
        img[175:180, col] = 100
    
    return img

def save_as_mem_file(img_array, filename):
    """Convert image to 16-bit values and save as .mem file"""
    # Convert 8-bit to 16-bit
    img_16bit = (img_array.astype(np.uint32) * 257).astype(np.uint16)
    
    with open(filename, 'w') as f:
        for pixel in img_16bit.flatten():
            f.write(f"{pixel:04x}\n")
    
    print(f"✅ Saved {filename} ({img_16bit.shape[0]*img_16bit.shape[1]} pixels)")

def create_all_testcases():
    """Generate all medical test cases"""
    
    print("🏥 GENERATING MEDICAL X-RAY TEST CASES")
    print("=" * 50)
    
    # Test case definitions
    testcases = [
        ("normal_xray.mem", create_normal_xray(), "Normal chest X-ray"),
        ("pneumonia_xray.mem", create_pneumonia_xray(), "Pneumonia with consolidation"),
        ("cardiomegaly_xray.mem", create_cardiomegaly_xray(), "Enlarged heart"),
        ("pneumothorax_xray.mem", create_pneumothorax_xray(), "Collapsed lung"),
        ("pleural_effusion_xray.mem", create_pleural_effusion_xray(), "Fluid in lungs"),
        ("nodule_xray.mem", create_nodule_xray(), "Lung nodules"),
        ("emphysema_xray.mem", create_emphysema_xray(), "Emphysema/COPD")
    ]
    
    # Create visualization
    fig, axes = plt.subplots(2, 4, figsize=(16, 8))
    axes = axes.flatten()
    
    for i, (filename, img_array, description) in enumerate(testcases):
        # Save as memory file
        save_as_mem_file(img_array, filename)
        
        # Create visualization
        if i < len(axes):
            axes[i].imshow(img_array, cmap='gray')
            axes[i].set_title(f"{description}\n{filename}")
            axes[i].axis('off')
    
    # Hide unused subplot
    if len(testcases) < len(axes):
        axes[-1].axis('off')
    
    plt.tight_layout()
    plt.savefig('medical_testcases_preview.png', dpi=150, bbox_inches='tight')
    plt.show()
    
    print(f"\n🎯 GENERATED {len(testcases)} TEST CASES:")
    for filename, _, description in testcases:
        print(f"  📁 {filename} - {description}")
    
    print(f"\n📊 Preview saved as: medical_testcases_preview.png")
    print(f"\n🔬 USAGE:")
    print(f"1. Copy .mem files to your testbench directory")
    print(f"2. Update testbench to load these files")
    print(f"3. Run simulation to test each medical condition")
    
    return testcases

if __name__ == "__main__":
    create_all_testcases()
