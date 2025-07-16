#!/usr/bin/env python3
"""
Comprehensive Disease Testing Script
Tests all disease patterns and provides detailed analysis
"""

import os
import subprocess
import time
import shutil
from pathlib import Path

# Medical conditions mapping
DISEASE_MAPPING = {
    "normal": "No Finding",
    "pneumonia": "Pneumonia", 
    "pneumothorax": "Pneumothorax",
    "atelectasis": "Atelectasis",
    "effusion": "Effusion",
    "cardiomegaly": "Cardiomegaly",
    "nodule": "Nodule",
    "mass": "Mass",
    "consolidation": "Consolidation",
    "emphysema": "Emphysema"
}

def test_single_disease(disease_name):
    """Test a single disease pattern"""
    print(f"\n🏥 Testing {disease_name.upper()} pattern...")
    print("-" * 50)
    
    # Check if disease file exists
    disease_file = f"disease_{disease_name}.mem"
    if not os.path.exists(disease_file):
        print(f"❌ Disease file {disease_file} not found!")
        print("Run: python prepare_disease_images_simple.py --diseases")
        return False
    
    # Backup current test image
    if os.path.exists("test_image.mem"):
        shutil.copy("test_image.mem", "test_image_backup.mem")
        print("📋 Backed up current test_image.mem")
    
    # Copy disease pattern to test image
    shutil.copy(disease_file, "test_image.mem")
    print(f"📋 Copied {disease_file} to test_image.mem")
    
    # Run simulation (if ModelSim is available)
    print("🔄 Running hardware simulation...")
    try:
        # Check if ModelSim is available
        result = subprocess.run(["vsim", "-version"], 
                              capture_output=True, text=True, timeout=10)
        if result.returncode == 0:
            print("✅ ModelSim found, running simulation...")
            
            # Run the simulation
            sim_result = subprocess.run(["vsim", "-do", "run_tb_full_system_top.do"],
                                      capture_output=True, text=True, timeout=300)
            
            if sim_result.returncode == 0:
                print("✅ Simulation completed successfully")
                
                # Analyze results
                print("📊 Analyzing results...")
                analysis_result = subprocess.run(["python", "analyze_disease_hex_outputs.py"],
                                              capture_output=True, text=True, timeout=60)
                
                if analysis_result.returncode == 0:
                    print("✅ Analysis completed")
                    
                    # Save results
                    output_file = f"results_{disease_name}.txt"
                    with open(output_file, 'w') as f:
                        f.write(f"=== {disease_name.upper()} TEST RESULTS ===\n")
                        f.write(f"Test Date: {time.strftime('%Y-%m-%d %H:%M:%S')}\n")
                        f.write(f"Expected Disease: {DISEASE_MAPPING.get(disease_name, disease_name)}\n")
                        f.write("\n=== SIMULATION OUTPUT ===\n")
                        f.write(sim_result.stdout)
                        f.write("\n=== ANALYSIS OUTPUT ===\n")
                        f.write(analysis_result.stdout)
                    
                    print(f"📄 Results saved to {output_file}")
                    return True
                else:
                    print("❌ Analysis failed")
                    print(analysis_result.stderr)
            else:
                print("❌ Simulation failed")
                print(sim_result.stderr)
        else:
            print("⚠️  ModelSim not available, skipping simulation")
            print("📋 To run simulation manually:")
            print(f"   cp {disease_file} test_image.mem")
            print("   vsim -do run_tb_full_system_top.do")
            print("   python analyze_disease_hex_outputs.py")
            
    except subprocess.TimeoutExpired:
        print("⏰ Simulation timed out")
    except FileNotFoundError:
        print("⚠️  ModelSim not found in PATH")
        print("📋 To run simulation manually:")
        print(f"   cp {disease_file} test_image.mem")
        print("   vsim -do run_tb_full_system_top.do")
        print("   python analyze_disease_hex_outputs.py")
    except Exception as e:
        print(f"❌ Error running simulation: {e}")
    
    # Restore backup
    if os.path.exists("test_image_backup.mem"):
        shutil.copy("test_image_backup.mem", "test_image.mem")
        print("📋 Restored original test_image.mem")
    
    return False

def test_all_diseases():
    """Test all disease patterns"""
    print("🏥 COMPREHENSIVE DISEASE TESTING")
    print("=" * 60)
    print()
    
    # Check if disease files exist
    missing_files = []
    for disease in DISEASE_MAPPING.keys():
        if not os.path.exists(f"disease_{disease}.mem"):
            missing_files.append(disease)
    
    if missing_files:
        print("❌ Missing disease files:")
        for disease in missing_files:
            print(f"   - disease_{disease}.mem")
        print("\n📋 Create missing files:")
        print("   python prepare_disease_images_simple.py --diseases")
        return
    
    print("✅ All disease files found!")
    print()
    
    # Test each disease
    results = {}
    for disease in DISEASE_MAPPING.keys():
        success = test_single_disease(disease)
        results[disease] = success
        
        # Small delay between tests
        time.sleep(1)
    
    # Summary
    print("\n" + "=" * 60)
    print("📊 TESTING SUMMARY")
    print("=" * 60)
    
    successful_tests = sum(results.values())
    total_tests = len(results)
    
    print(f"Total tests: {total_tests}")
    print(f"Successful: {successful_tests}")
    print(f"Failed: {total_tests - successful_tests}")
    print()
    
    print("📋 Results by disease:")
    for disease, success in results.items():
        status = "✅ PASS" if success else "❌ FAIL"
        expected = DISEASE_MAPPING.get(disease, disease)
        print(f"   {disease:15} | {expected:15} | {status}")
    
    print()
    print("📄 Individual result files:")
    for disease in DISEASE_MAPPING.keys():
        result_file = f"results_{disease}.txt"
        if os.path.exists(result_file):
            print(f"   - {result_file}")
    
    print()
    print("🎯 Next steps:")
    print("1. Review individual result files")
    print("2. Check simulation outputs for accuracy")
    print("3. Compare expected vs detected diseases")
    print("4. Fine-tune model if needed")

def test_specific_disease(disease_name):
    """Test a specific disease"""
    if disease_name not in DISEASE_MAPPING:
        print(f"❌ Unknown disease: {disease_name}")
        print("Available diseases:")
        for disease in DISEASE_MAPPING.keys():
            print(f"   - {disease}")
        return
    
    print(f"🏥 Testing specific disease: {disease_name}")
    print("=" * 50)
    
    success = test_single_disease(disease_name)
    
    if success:
        print(f"\n✅ {disease_name} test completed successfully")
        print(f"📄 Check results_{disease_name}.txt for details")
    else:
        print(f"\n❌ {disease_name} test failed")
        print("📋 Manual steps:")
        print(f"   cp disease_{disease_name}.mem test_image.mem")
        print("   vsim -do run_tb_full_system_top.do")
        print("   python analyze_disease_hex_outputs.py")

def main():
    """Main function"""
    print("🏥 Disease Testing System")
    print("=" * 40)
    print()
    
    if len(sys.argv) < 2:
        print("Usage:")
        print("  python test_all_diseases.py --all")
        print("  python test_all_diseases.py --disease <disease_name>")
        print()
        print("Available diseases:")
        for disease, expected in DISEASE_MAPPING.items():
            print(f"   - {disease}: {expected}")
        print()
        print("Examples:")
        print("  python test_all_diseases.py --all")
        print("  python test_all_diseases.py --disease pneumonia")
        return
    
    if sys.argv[1] == "--all":
        test_all_diseases()
    elif sys.argv[1] == "--disease" and len(sys.argv) >= 3:
        disease_name = sys.argv[2]
        test_specific_disease(disease_name)
    else:
        print("Invalid command. Use --all or --disease <name>")

if __name__ == "__main__":
    import sys
    main() 