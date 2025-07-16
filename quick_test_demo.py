#!/usr/bin/env python3
"""
Quick Test Demo - Test different disease patterns
"""

import os
import shutil
import subprocess
import sys

def test_disease_pattern(disease_name):
    """Test a specific disease pattern"""
    print(f"\n🏥 Testing {disease_name.upper()} pattern...")
    print("-" * 50)
    
    # Check if disease file exists
    disease_file = f"disease_{disease_name}.mem"
    if not os.path.exists(disease_file):
        print(f"❌ Disease file {disease_file} not found!")
        return False
    
    # Backup current test image
    if os.path.exists("test_image.mem"):
        shutil.copy("test_image.mem", "test_image_backup.mem")
        print("📋 Backed up current test_image.mem")
    
    # Copy disease pattern to test image
    shutil.copy(disease_file, "test_image.mem")
    print(f"📋 Copied {disease_file} to test_image.mem")
    
    # Try to run simulation (if ModelSim available)
    print("🔄 Attempting hardware simulation...")
    try:
        result = subprocess.run(["vsim", "-do", "run_tb_full_system_top.do"],
                              capture_output=True, text=True, timeout=60)
        if result.returncode == 0:
            print("✅ Simulation completed successfully")
        else:
            print("⚠️  Simulation failed or ModelSim not available")
            print("📋 Using existing analysis capabilities")
    except:
        print("⚠️  ModelSim not available, using existing results")
    
    # Analyze results
    print("📊 Analyzing results...")
    try:
        analysis_result = subprocess.run(["python", "analyze_disease_hex_outputs.py"],
                                       capture_output=True, text=True, timeout=30)
        
        if analysis_result.returncode == 0:
            print("✅ Analysis completed")
            print("\n📋 Results Summary:")
            print("-" * 30)
            
            # Extract key information from output
            output = analysis_result.stdout
            if "PRIMARY DIAGNOSIS:" in output:
                lines = output.split('\n')
                for i, line in enumerate(lines):
                    if "PRIMARY DIAGNOSIS:" in line:
                        print(f"Primary: {line}")
                    elif "Confidence:" in line:
                        print(f"Confidence: {line}")
                    elif "Recommendation:" in line:
                        print(f"Recommendation: {line}")
                        break
        else:
            print("❌ Analysis failed")
            print(analysis_result.stderr)
            
    except Exception as e:
        print(f"❌ Analysis error: {e}")
    
    # Restore backup
    if os.path.exists("test_image_backup.mem"):
        shutil.copy("test_image_backup.mem", "test_image.mem")
        print("📋 Restored original test_image.mem")
    
    return True

def main():
    """Main function"""
    print("🏥 Quick Disease Testing Demo")
    print("=" * 40)
    print()
    
    # Available diseases
    diseases = ["pneumonia", "pneumothorax", "normal", "atelectasis", "effusion"]
    
    print("Available disease patterns:")
    for i, disease in enumerate(diseases, 1):
        print(f"  {i}. {disease}")
    print()
    
    # Test each disease
    for disease in diseases:
        test_disease_pattern(disease)
        print("\n" + "="*50)
    
    print("\n🎉 Demo completed!")
    print("\n📋 Next steps:")
    print("1. Review the results above")
    print("2. Compare expected vs actual diagnoses")
    print("3. Check confidence levels")
    print("4. Validate urgency assessments")
    print("\n🔧 To test manually:")
    print("   cp disease_pneumonia.mem test_image.mem")
    print("   vsim -do run_tb_full_system_top.do")
    print("   python analyze_disease_hex_outputs.py")

if __name__ == "__main__":
    main() 