#!/usr/bin/env python3
"""
Disease Pattern Lister
Lists all available disease patterns and their characteristics
"""

import os
from pathlib import Path

# Medical conditions and their characteristics
DISEASE_INFO = {
    "normal": {
        "description": "Normal chest X-ray",
        "characteristics": "Clear lung fields, normal heart size, no abnormalities",
        "urgency": "Low",
        "expected_diagnosis": "No Finding"
    },
    "pneumonia": {
        "description": "Pneumonia - lung infection",
        "characteristics": "Patchy opacities, consolidation in lung fields",
        "urgency": "Standard",
        "expected_diagnosis": "Pneumonia"
    },
    "pneumothorax": {
        "description": "Pneumothorax - collapsed lung",
        "characteristics": "Air in pleural space, lung edge visible",
        "urgency": "High",
        "expected_diagnosis": "Pneumothorax"
    },
    "atelectasis": {
        "description": "Atelectasis - partial lung collapse",
        "characteristics": "Linear opacities, volume loss",
        "urgency": "Moderate",
        "expected_diagnosis": "Atelectasis"
    },
    "effusion": {
        "description": "Pleural effusion - fluid around lungs",
        "characteristics": "Blunting of costophrenic angles, fluid level",
        "urgency": "Standard",
        "expected_diagnosis": "Effusion"
    },
    "cardiomegaly": {
        "description": "Cardiomegaly - enlarged heart",
        "characteristics": "Increased cardiac silhouette",
        "urgency": "Standard",
        "expected_diagnosis": "Cardiomegaly"
    },
    "nodule": {
        "description": "Pulmonary nodule",
        "characteristics": "Round opacity, well-defined borders",
        "urgency": "Standard",
        "expected_diagnosis": "Nodule"
    },
    "mass": {
        "description": "Lung mass",
        "characteristics": "Large opacity, irregular borders",
        "urgency": "Moderate",
        "expected_diagnosis": "Mass"
    },
    "consolidation": {
        "description": "Lung consolidation",
        "characteristics": "Dense opacification, air bronchograms",
        "urgency": "Standard",
        "expected_diagnosis": "Consolidation"
    },
    "emphysema": {
        "description": "Emphysema",
        "characteristics": "Hyperinflated lungs, flattened diaphragm",
        "urgency": "Standard",
        "expected_diagnosis": "Emphysema"
    }
}

def list_disease_patterns():
    """List all available disease patterns"""
    print("🏥 AVAILABLE DISEASE PATTERNS")
    print("=" * 80)
    print()
    
    # Check which files exist
    available_patterns = []
    missing_patterns = []
    
    for disease, info in DISEASE_INFO.items():
        file_path = f"disease_{disease}.mem"
        if os.path.exists(file_path):
            available_patterns.append(disease)
        else:
            missing_patterns.append(disease)
    
    # Display available patterns
    if available_patterns:
        print("✅ AVAILABLE PATTERNS:")
        print("-" * 80)
        print(f"{'Disease':<15} | {'File':<20} | {'Expected Diagnosis':<20} | {'Urgency':<10}")
        print("-" * 80)
        
        for disease in available_patterns:
            info = DISEASE_INFO[disease]
            file_name = f"disease_{disease}.mem"
            print(f"{disease:<15} | {file_name:<20} | {info['expected_diagnosis']:<20} | {info['urgency']:<10}")
        
        print()
        print("📋 DETAILED DESCRIPTIONS:")
        print("-" * 80)
        
        for disease in available_patterns:
            info = DISEASE_INFO[disease]
            print(f"\n🏥 {disease.upper()}:")
            print(f"   Description: {info['description']}")
            print(f"   Characteristics: {info['characteristics']}")
            print(f"   Expected Diagnosis: {info['expected_diagnosis']}")
            print(f"   Urgency Level: {info['urgency']}")
            print(f"   File: disease_{disease}.mem")
    
    # Display missing patterns
    if missing_patterns:
        print(f"\n❌ MISSING PATTERNS ({len(missing_patterns)}):")
        print("-" * 80)
        for disease in missing_patterns:
            print(f"   - disease_{disease}.mem")
        
        print(f"\n📋 To create missing patterns:")
        print("   python prepare_disease_images_simple.py --diseases")
    
    # Usage instructions
    print("\n🔧 USAGE INSTRUCTIONS:")
    print("-" * 80)
    print("1. Choose a disease to test:")
    print("   cp disease_pneumonia.mem test_image.mem")
    print()
    print("2. Run hardware simulation:")
    print("   vsim -do run_tb_full_system_top.do")
    print()
    print("3. Analyze results:")
    print("   python analyze_disease_hex_outputs.py")
    print()
    print("📊 QUICK TESTING:")
    print("-" * 80)
    print("Test urgent condition (pneumothorax):")
    print("   cp disease_pneumothorax.mem test_image.mem")
    print("   vsim -do run_tb_full_system_top.do")
    print("   python analyze_disease_hex_outputs.py")
    print()
    print("Test normal X-ray:")
    print("   cp disease_normal.mem test_image.mem")
    print("   vsim -do run_tb_full_system_top.do")
    print("   python analyze_disease_hex_outputs.py")
    
    # File size verification
    print("\n📏 FILE SIZE VERIFICATION:")
    print("-" * 80)
    for disease in available_patterns:
        file_path = f"disease_{disease}.mem"
        try:
            with open(file_path, 'r') as f:
                lines = len(f.readlines())
            status = "✅" if lines == 50176 else "❌"
            print(f"   {status} {file_path}: {lines:,} lines")
        except Exception as e:
            print(f"   ❌ {file_path}: Error reading file")

def main():
    """Main function"""
    list_disease_patterns()

if __name__ == "__main__":
    main() 