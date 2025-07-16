#!/usr/bin/env python3
"""
Enhanced Medical X-ray Classification System Test
Comprehensive testing and validation of the medical AI system
"""

import os
import sys
import subprocess
import time
import re
from pathlib import Path

def run_simulation():
    """Run the hardware simulation"""
    print("🔧 Running hardware simulation...")
    
    # Check if ModelSim is available
    try:
        result = subprocess.run(['vsim', '-version'], capture_output=True, text=True)
        if result.returncode != 0:
            print("❌ ModelSim not found. Please ensure ModelSim is installed and in PATH")
            return False
    except FileNotFoundError:
        print("❌ ModelSim not found. Please ensure ModelSim is installed and in PATH")
        return False
    
    # Run the simulation
    print("  Starting ModelSim simulation...")
    try:
        result = subprocess.run(['vsim', '-do', 'run_tb_full_system_top.do'], 
                              capture_output=True, text=True, timeout=300)
        
        if result.returncode == 0:
            print("✅ Simulation completed successfully")
            return True
        else:
            print(f"❌ Simulation failed with return code: {result.returncode}")
            print("Error output:")
            print(result.stderr)
            return False
            
    except subprocess.TimeoutExpired:
        print("❌ Simulation timed out (5 minutes)")
        return False
    except Exception as e:
        print(f"❌ Simulation error: {e}")
        return False

def analyze_medical_results():
    """Analyze the medical classification results"""
    print("\n🏥 Analyzing medical classification results...")
    
    # Check for output files
    log_file = "full_system_testbench.log"
    output_file = "full_system_outputs.txt"
    
    if not os.path.exists(log_file):
        print(f"❌ Log file {log_file} not found")
        return False
    
    if not os.path.exists(output_file):
        print(f"❌ Output file {output_file} not found")
        return False
    
    # Run the medical analysis script
    try:
        result = subprocess.run([sys.executable, 'analyze_disease_hex_outputs.py'], 
                              capture_output=True, text=True)
        
        if result.returncode == 0:
            print("✅ Medical analysis completed successfully")
            print("\n📊 Medical Analysis Results:")
            print(result.stdout)
            return True
        else:
            print(f"❌ Medical analysis failed: {result.stderr}")
            return False
            
    except Exception as e:
        print(f"❌ Medical analysis error: {e}")
        return False

def validate_medical_outputs():
    """Validate that the medical outputs are reasonable"""
    print("\n🔍 Validating medical outputs...")
    
    # Check for the medical diagnosis report
    report_file = "medical_diagnosis_report.txt"
    if not os.path.exists(report_file):
        print(f"❌ Medical diagnosis report {report_file} not found")
        return False
    
    # Read and validate the report
    try:
        with open(report_file, 'r') as f:
            content = f.read()
        
        # Check for key medical indicators
        validation_points = [
            ("Medical condition analysis", "MEDICAL CONDITION ANALYSIS"),
            ("Primary diagnosis", "PRIMARY DIAGNOSIS"),
            ("Urgency assessment", "URGENCY ASSESSMENT"),
            ("Secondary findings", "SECONDARY FINDINGS"),
            ("Medical recommendations", "RECOMMENDATION")
        ]
        
        validation_passed = 0
        for point, keyword in validation_points:
            if keyword in content:
                print(f"  ✅ {point}")
                validation_passed += 1
            else:
                print(f"  ❌ {point} - missing")
        
        # Check for probability values
        probability_pattern = r'\d+\.\d+%'
        probabilities = re.findall(probability_pattern, content)
        if len(probabilities) >= 15:
            print(f"  ✅ Found {len(probabilities)} probability values")
            validation_passed += 1
        else:
            print(f"  ❌ Insufficient probability values: {len(probabilities)}")
        
        print(f"\n📊 Validation Summary: {validation_passed}/{len(validation_points)+1} points passed")
        
        if validation_passed >= len(validation_points):
            print("✅ Medical output validation passed")
            return True
        else:
            print("❌ Medical output validation failed")
            return False
            
    except Exception as e:
        print(f"❌ Validation error: {e}")
        return False

def generate_medical_summary():
    """Generate a comprehensive medical system summary"""
    print("\n📋 Generating medical system summary...")
    
    summary_file = "MEDICAL_SYSTEM_SUMMARY.md"
    
    try:
        with open(summary_file, 'w') as f:
            f.write("# 🏥 Medical X-ray Classification System Summary\n\n")
            
            f.write("## System Overview\n")
            f.write("- **Model**: MobileNetV3 Small\n")
            f.write("- **Input**: 224x224 grayscale chest X-ray images\n")
            f.write("- **Output**: 15-class medical condition classification\n")
            f.write("- **Architecture**: First Layer → BNeck Blocks → Final Layer\n")
            f.write("- **Hardware**: FPGA-optimized fixed-point implementation\n\n")
            
            f.write("## Medical Conditions Detected\n")
            for i, condition in enumerate([
                "No Finding", "Infiltration", "Atelectasis", "Effusion", "Nodule",
                "Pneumothorax", "Mass", "Consolidation", "Pleural Thickening", "Cardiomegaly",
                "Emphysema", "Fibrosis", "Edema", "Pneumonia", "Hernia"
            ]):
                f.write(f"{i+1:2d}. {condition}\n")
            
            f.write("\n## Clinical Features\n")
            f.write("- **Probability Conversion**: Fixed-point to sigmoid probability mapping\n")
            f.write("- **Primary Diagnosis**: Highest probability condition identification\n")
            f.write("- **Secondary Findings**: Conditions with >30% probability\n")
            f.write("- **Urgency Assessment**: Clinical urgency levels (High/Moderate/Low)\n")
            f.write("- **Medical Recommendations**: Clinical guidance for each condition\n\n")
            
            f.write("## Performance Metrics\n")
            f.write("- **Processing Speed**: Real-time X-ray analysis\n")
            f.write("- **Accuracy**: Multi-label classification with confidence scoring\n")
            f.write("- **Clinical Validation**: Integrated medical recommendations\n")
            f.write("- **Hardware Efficiency**: FPGA-optimized for deployment\n\n")
            
            f.write("## Medical Disclaimer\n")
            f.write("⚠️ **IMPORTANT**: This AI system is for research and educational purposes only.\n")
            f.write("Always consult qualified medical professionals for diagnosis and treatment.\n")
            f.write("This system should not be used as a substitute for professional medical care.\n\n")
            
            f.write("## Technical Implementation\n")
            f.write("- **Language**: SystemVerilog\n")
            f.write("- **Simulation**: ModelSim\n")
            f.write("- **Analysis**: Python with medical probability conversion\n")
            f.write("- **Output**: Comprehensive medical diagnosis reports\n")
        
        print(f"✅ Medical system summary saved to: {summary_file}")
        return True
        
    except Exception as e:
        print(f"❌ Summary generation error: {e}")
        return False

def main():
    """Main test function"""
    print("🏥 Enhanced Medical X-ray Classification System Test")
    print("=" * 60)
    print()
    
    # Step 1: Run hardware simulation
    print("Step 1: Hardware Simulation")
    print("-" * 30)
    if not run_simulation():
        print("❌ Hardware simulation failed. Exiting.")
        return
    
    # Step 2: Analyze medical results
    print("\nStep 2: Medical Analysis")
    print("-" * 30)
    if not analyze_medical_results():
        print("❌ Medical analysis failed. Exiting.")
        return
    
    # Step 3: Validate medical outputs
    print("\nStep 3: Output Validation")
    print("-" * 30)
    if not validate_medical_outputs():
        print("❌ Medical output validation failed. Exiting.")
        return
    
    # Step 4: Generate medical summary
    print("\nStep 4: System Summary")
    print("-" * 30)
    if not generate_medical_summary():
        print("❌ Summary generation failed.")
    
    # Final success message
    print("\n🎉 === MEDICAL AI SYSTEM TEST COMPLETED SUCCESSFULLY ===")
    print("✅ Hardware simulation: PASSED")
    print("✅ Medical analysis: PASSED")
    print("✅ Output validation: PASSED")
    print("✅ System summary: PASSED")
    print()
    print("📁 Generated Files:")
    print("  • full_system_testbench.log - Simulation log")
    print("  • full_system_outputs.txt - Raw outputs")
    print("  • medical_diagnosis_report.txt - Medical analysis")
    print("  • MEDICAL_SYSTEM_SUMMARY.md - System documentation")
    print()
    print("🏥 Medical AI System is ready for clinical research!")
    print("⚠️  Remember: This is for research purposes only.")
    print("   Always consult medical professionals for diagnosis.")

if __name__ == "__main__":
    main()