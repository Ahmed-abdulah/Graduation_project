#!/usr/bin/env python3
"""
Medical X-ray Classification Analysis System
Analyzes hardware simulation outputs and provides medical diagnosis with probabilities
"""

import re
import sys
import os
import math
from pathlib import Path

# Medical condition class names (15 chest X-ray conditions)
MEDICAL_CONDITIONS = [
    "No Finding",
    "Infiltration",
    "Atelectasis", 
    "Effusion",
    "Nodule",
    "Pneumothorax",
    "Mass",
    "Consolidation",
    "Pleural Thickening",
    "Cardiomegaly",
    "Emphysema",
    "Fibrosis",
    "Edema",
    "Pneumonia",
    "Hernia"
]

# Medical recommendations
MEDICAL_RECOMMENDATIONS = [
    "The X-ray appears normal. Continue regular health checkups.",
    "Possible fluid or infection in lungs. Consult a pulmonologist.",
    "Partial lung collapse suspected. Immediate evaluation is advised.",
    "Fluid around lungs detected. You should see a physician promptly.",
    "A small spot was found. Further imaging or biopsy may be required.",
    "Air in lung cavity. This could be urgent – seek ER care.",
    "Abnormal tissue detected. Specialist referral is needed.",
    "Signs of infection or pneumonia. Medical evaluation required.",
    "Scarring detected. Monitor regularly with your doctor.",
    "Heart appears enlarged. Cardiologist follow-up recommended.",
    "Signs of chronic lung disease. Pulmonary care advised.",
    "Lung scarring seen. Long-term monitoring may be needed.",
    "Fluid buildup in lungs. Heart function check is essential.",
    "Infection detected. Prompt antibiotic treatment recommended.",
    "Possible diaphragm hernia. Consult a surgeon for evaluation."
]

def fixed_to_probability(fixed_val, data_width=16, frac_bits=8):
    """Convert fixed-point value to probability (0.0 to 1.0)"""
    # Convert to signed integer
    if fixed_val >= 2**(data_width-1):
        fixed_val -= 2**data_width
    
    # Convert to floating point (assuming Q8.8 format)
    temp_real = fixed_val / (2.0**frac_bits)
    
    # Apply sigmoid approximation to get 0-1 range
    if temp_real > 5.0:
        return 1.0
    elif temp_real < -5.0:
        return 0.0
    else:
        return 1.0 / (1.0 + math.exp(-temp_real))

def extract_hex_values_from_log(log_file_path):
    """Extract hex values from simulation log file"""
    hex_values = []
    
    try:
        with open(log_file_path, 'r') as f:
            content = f.read()
            
        # Look for hex patterns in the output
        # Pattern to match hex values (8-bit, 16-bit, 32-bit)
        hex_patterns = [
            r'0x[0-9a-fA-F]{2}',      # 8-bit hex
            r'0x[0-9a-fA-F]{4}',      # 16-bit hex  
            r'0x[0-9a-fA-F]{8}',      # 32-bit hex
            r'[0-9a-fA-F]{2}',        # 8-bit hex without 0x
            r'[0-9a-fA-F]{4}',        # 16-bit hex without 0x
            r'[0-9a-fA-F]{8}'         # 32-bit hex without 0x
        ]
        
        for pattern in hex_patterns:
            matches = re.findall(pattern, content)
            if matches:
                hex_values.extend(matches)
                
        # Also look for specific disease output patterns
        disease_pattern = r'Disease\s+(\d+):\s+([0-9a-fA-Fx]+)'
        disease_matches = re.findall(disease_pattern, content)
        
        if disease_matches:
            print("Found disease-specific outputs:")
            for idx, hex_val in disease_matches:
                disease_idx = int(idx)
                if disease_idx < len(MEDICAL_CONDITIONS):
                    print(f"  {MEDICAL_CONDITIONS[disease_idx]}: {hex_val}")
        
        return hex_values
        
    except FileNotFoundError:
        print(f"Error: Log file {log_file_path} not found")
        return []
    except Exception as e:
        print(f"Error reading log file: {e}")
        return []

def analyze_output_file(output_file_path):
    """Analyze the full system outputs file"""
    try:
        with open(output_file_path, 'r') as f:
            content = f.read()
            
        print("=== FULL SYSTEM OUTPUT ANALYSIS ===")
        print(f"Output file: {output_file_path}")
        print(f"File size: {len(content)} characters")
        print()
        
        # Look for test results
        test_pattern = r'Test\s+(\d+):\s+(.+)'
        test_matches = re.findall(test_pattern, content)
        
        if test_matches:
            print("Test Results:")
            for test_num, result in test_matches:
                print(f"  Test {test_num}: {result}")
            print()
        
        # Look for hex values
        hex_values = re.findall(r'0x[0-9a-fA-F]+', content)
        if hex_values:
            print(f"Found {len(hex_values)} hex values:")
            for i, hex_val in enumerate(hex_values[:20]):  # Show first 20
                print(f"  {i+1}: {hex_val}")
            if len(hex_values) > 20:
                print(f"  ... and {len(hex_values) - 20} more")
            print()
            
        return hex_values
        
    except FileNotFoundError:
        print(f"Error: Output file {output_file_path} not found")
        return []
    except Exception as e:
        print(f"Error reading output file: {e}")
        return []

def create_medical_diagnosis_report(hex_values, output_file="medical_diagnosis_report.txt"):
    """Create a comprehensive medical diagnosis report"""
    
    print("=== MEDICAL X-RAY CLASSIFICATION ANALYSIS ===")
    print(f"Total hex values found: {len(hex_values)}")
    print()
    
    # Group hex values by size
    hex_8bit = [h for h in hex_values if len(h) == 2 or (h.startswith('0x') and len(h) == 4)]
    hex_16bit = [h for h in hex_values if len(h) == 4 or (h.startswith('0x') and len(h) == 6)]
    hex_32bit = [h for h in hex_values if len(h) == 8 or (h.startswith('0x') and len(h) == 10)]
    
    print(f"8-bit hex values: {len(hex_8bit)}")
    print(f"16-bit hex values: {len(hex_16bit)}")
    print(f"32-bit hex values: {len(hex_32bit)}")
    print()
    
    # Convert hex values to probabilities and analyze medical conditions
    if len(hex_values) >= 15:
        print("MEDICAL CONDITION ANALYSIS:")
        print("-" * 80)
        print(f"{'Condition':<20} | {'Probability':<12} | {'Raw Score':<10} | {'Confidence':<12} | {'Recommendation'}")
        print("-" * 80)
        
        probabilities = []
        max_probability = 0.0
        primary_condition = 0
        
        for i in range(min(15, len(hex_values))):
            hex_val = hex_values[i]
            try:
                # Convert hex to integer
                if hex_val.startswith('0x'):
                    raw_score = int(hex_val, 16)
                else:
                    raw_score = int(hex_val, 16)
                
                # Convert to probability
                probability = fixed_to_probability(raw_score)
                probabilities.append(probability)
                
                # Track highest probability
                if probability > max_probability:
                    max_probability = probability
                    primary_condition = i
                
                # Format recommendation (truncate if too long)
                recommendation = MEDICAL_RECOMMENDATIONS[i]
                if len(recommendation) > 50:
                    recommendation = recommendation[:47] + "..."
                
                print(f"{MEDICAL_CONDITIONS[i]:<20} | {probability:>10.4f} | {raw_score:>8d} | {probability*100:>10.2f}% | {recommendation}")
                
            except ValueError:
                print(f"{MEDICAL_CONDITIONS[i]:<20} | {'INVALID':<12} | {hex_val:<10} | {'ERROR':<12} | Invalid hex value")
        
        print("-" * 80)
        
        # Primary diagnosis
        print(f"\nPRIMARY DIAGNOSIS:")
        print(f"Condition: {MEDICAL_CONDITIONS[primary_condition]}")
        print(f"Confidence: {max_probability*100:.2f}% ({max_probability:.4f})")
        print(f"Recommendation: {MEDICAL_RECOMMENDATIONS[primary_condition]}")
        
        # Secondary conditions (probability > 0.3)
        print(f"\nSECONDARY FINDINGS (>30% probability):")
        secondary_count = 0
        for i, prob in enumerate(probabilities):
            if prob > 0.3 and i != primary_condition:
                print(f"  • {MEDICAL_CONDITIONS[i]}: {prob*100:.2f}%")
                secondary_count += 1
        if secondary_count == 0:
            print("  No significant secondary findings.")
        
        # Urgency assessment
        print(f"\nURGENCY ASSESSMENT:")
        if primary_condition == 5:  # Pneumothorax
            print("  HIGH URGENCY - Seek emergency care immediately!")
        elif primary_condition in [2, 6, 13]:  # Atelectasis, Mass, Pneumonia
            print("  MODERATE URGENCY - Schedule appointment within 24-48 hours")
        elif primary_condition == 0:  # No Finding
            print("  LOW URGENCY - Normal findings, routine follow-up")
        else:
            print("  STANDARD URGENCY - Schedule appointment within 1-2 weeks")
        
        # Save detailed report
        with open(output_file, 'w') as f:
            f.write("MEDICAL X-RAY CLASSIFICATION ANALYSIS REPORT\n")
            f.write("=" * 60 + "\n\n")
            f.write(f"Total hex values found: {len(hex_values)}\n")
            f.write(f"8-bit hex values: {len(hex_8bit)}\n")
            f.write(f"16-bit hex values: {len(hex_16bit)}\n")
            f.write(f"32-bit hex values: {len(hex_32bit)}\n\n")
            
            f.write("MEDICAL CONDITION ANALYSIS:\n")
            f.write("-" * 80 + "\n")
            f.write(f"{'Condition':<20} | {'Probability':<12} | {'Raw Score':<10} | {'Confidence':<12} | {'Recommendation'}\n")
            f.write("-" * 80 + "\n")
            
            for i in range(min(15, len(hex_values))):
                hex_val = hex_values[i]
                try:
                    if hex_val.startswith('0x'):
                        raw_score = int(hex_val, 16)
                    else:
                        raw_score = int(hex_val, 16)
                    
                    probability = fixed_to_probability(raw_score)
                    recommendation = MEDICAL_RECOMMENDATIONS[i]
                    if len(recommendation) > 50:
                        recommendation = recommendation[:47] + "..."
                    
                    f.write(f"{MEDICAL_CONDITIONS[i]:<20} | {probability:>10.4f} | {raw_score:>8d} | {probability*100:>10.2f}% | {recommendation}\n")
                    
                except ValueError:
                    f.write(f"{MEDICAL_CONDITIONS[i]:<20} | {'INVALID':<12} | {hex_val:<10} | {'ERROR':<12} | Invalid hex value\n")
            
            f.write("-" * 80 + "\n\n")
            f.write(f"PRIMARY DIAGNOSIS: {MEDICAL_CONDITIONS[primary_condition]} ({max_probability*100:.2f}%)\n")
            f.write(f"RECOMMENDATION: {MEDICAL_RECOMMENDATIONS[primary_condition]}\n\n")
            
            f.write("SECONDARY FINDINGS (>30% probability):\n")
            for i, prob in enumerate(probabilities):
                if prob > 0.3 and i != primary_condition:
                    f.write(f"  • {MEDICAL_CONDITIONS[i]}: {prob*100:.2f}%\n")
            
            f.write("\nURGENCY ASSESSMENT:\n")
            if primary_condition == 5:
                f.write("  HIGH URGENCY - Seek emergency care immediately!\n")
            elif primary_condition in [2, 6, 13]:
                f.write("  MODERATE URGENCY - Schedule appointment within 24-48 hours\n")
            elif primary_condition == 0:
                f.write("  LOW URGENCY - Normal findings, routine follow-up\n")
            else:
                f.write("  STANDARD URGENCY - Schedule appointment within 1-2 weeks\n")
        
        print(f"\nDetailed medical report saved to: {output_file}")
        return output_file
    
    else:
        print("ERROR: Insufficient hex values for medical analysis (need at least 15)")
        return None

def main():
    """Main analysis function"""
    print("Medical X-ray Classification Analysis System")
    print("=" * 60)
    print()
    
    # Check for output files
    log_file = "full_system_testbench.log"
    output_file = "full_system_outputs.txt"
    
    hex_values = []
    
    # Analyze log file
    if os.path.exists(log_file):
        print(f"Analyzing log file: {log_file}")
        log_hex = extract_hex_values_from_log(log_file)
        hex_values.extend(log_hex)
        print()
    
    # Analyze output file
    if os.path.exists(output_file):
        print(f"Analyzing output file: {output_file}")
        output_hex = analyze_output_file(output_file)
        hex_values.extend(output_hex)
        print()
    
    if not hex_values:
        print("No hex values found in output files!")
        print("Please run the hardware simulation first:")
        print("  vsim -do run_tb_full_system_top.do")
        return
    
    # Remove duplicates while preserving order
    unique_hex = []
    seen = set()
    for hex_val in hex_values:
        if hex_val not in seen:
            unique_hex.append(hex_val)
            seen.add(hex_val)
    
    # Create comprehensive medical report
    report_file = create_medical_diagnosis_report(unique_hex)
    
    print("\n=== MEDICAL AI SYSTEM SUMMARY ===")
    print("System: MobileNetV3 Chest X-ray Classifier")
    print("Conditions detected: 15 chest pathologies")
    print("Input resolution: 224x224 grayscale")
    print("Processing: Fixed-point to probability conversion")
    print("Clinical validation: Integrated recommendations")
    print()
    print("DISCLAIMER:")
    print("This AI system is for research/educational purposes.")
    print("Always consult qualified medical professionals for diagnosis.")
    print("===============================================")
    
    print(f"\nAnalysis complete!")
    print(f"Medical report saved to: {report_file}")
    print()
    print("To test with a specific X-ray image:")
    print("1. Replace test_image.mem with your X-ray data")
    print("2. Run: vsim -do run_tb_full_system_top.do")
    print("3. Run this script again to analyze results")

if __name__ == "__main__":
    main() 