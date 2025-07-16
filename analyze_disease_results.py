#!/usr/bin/env python3
"""
Medical Diagnosis Analysis Script for MobileNetV3 Hardware
Analyzes hardware outputs and maps them to disease names
"""

import numpy as np
import matplotlib.pyplot as plt
import argparse
import os
import re

# Disease names mapping (actual 15 chest X-ray conditions)
DISEASE_NAMES = [
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

def read_hardware_output(filename, num_tests=5, num_classes=15):
    """Read hardware output file and extract disease scores"""
    outputs = []
    test_names = []
    
    with open(filename, 'r') as f:
        content = f.read()
    
    # Split by test cases
    test_sections = content.split('=== Test')
    
    for section in test_sections[1:]:  # Skip first empty section
        lines = section.strip().split('\n')
        if len(lines) < 2:
            continue
            
        # Extract test name
        test_name = lines[0].split(': ')[1].split(' ===')[0]
        test_names.append(test_name)
        
        # Extract output values
        values = []
        for line in lines[1:]:
            line = line.strip()
            if line and line.startswith('===') == False:
                try:
                    values.append(int(line, 16))
                except ValueError:
                    continue
        
        if len(values) == num_classes:
            outputs.append(np.array(values, dtype=np.int16))
        else:
            print(f"Warning: Test {test_name} has {len(values)} values, expected {num_classes}")
            outputs.append(np.zeros(num_classes, dtype=np.int16))
    
    return outputs, test_names

def analyze_disease_predictions(outputs, test_names):
    """Analyze disease predictions from hardware outputs"""
    print("\n=== MEDICAL DIAGNOSIS ANALYSIS ===")
    
    for i, (output, test_name) in enumerate(zip(outputs, test_names)):
        print(f"\nTest {i}: {test_name}")
        
        # Find the highest scoring disease
        max_index = np.argmax(output)
        max_score = output[max_index]
        predicted_disease = DISEASE_NAMES[max_index]
        
        print(f"  Predicted Disease: {predicted_disease}")
        print(f"  Confidence Score: {max_score}")
        print(f"  Disease Index: {max_index}")
        
        # Show top 3 predictions
        top_indices = np.argsort(output)[-3:][::-1]
        print("  Top 3 Predictions:")
        for j, idx in enumerate(top_indices):
            print(f"    {j+1}. {DISEASE_NAMES[idx]}: {output[idx]}")
        
        # Calculate confidence percentage (normalized)
        total_score = np.sum(np.abs(output))
        if total_score > 0:
            confidence_pct = (max_score / total_score) * 100
            print(f"  Confidence: {confidence_pct:.1f}%")
        else:
            print(f"  Confidence: 0.0%")

def create_disease_analysis_plot(outputs, test_names, save_path="disease_analysis.png"):
    """Create comprehensive disease analysis plots"""
    fig, axs = plt.subplots(2, 2, figsize=(16, 12))
    
    # Plot 1: All disease scores for each test
    x = np.arange(len(DISEASE_NAMES))
    colors = ['blue', 'red', 'green', 'orange', 'purple']
    
    for i, (output, test_name) in enumerate(zip(outputs, test_names)):
        color = colors[i % len(colors)]
        axs[0,0].plot(x, output, marker='o', color=color, label=f'Test {i}: {test_name[:20]}...')
    
    axs[0,0].set_title('Disease Scores Across All Tests')
    axs[0,0].set_xlabel('Disease Index')
    axs[0,0].set_ylabel('Score')
    axs[0,0].set_xticks(x)
    axs[0,0].set_xticklabels([f'{i}\n{name[:10]}' for i, name in enumerate(DISEASE_NAMES)], rotation=45)
    axs[0,0].legend(bbox_to_anchor=(1.05, 1), loc='upper left')
    axs[0,0].grid(True, alpha=0.3)
    
    # Plot 2: Predicted diseases for each test
    predicted_diseases = []
    for output in outputs:
        max_index = np.argmax(output)
        predicted_diseases.append(max_index)
    
    axs[0,1].bar(range(len(predicted_diseases)), predicted_diseases)
    axs[0,1].set_title('Predicted Disease Index per Test')
    axs[0,1].set_xlabel('Test Index')
    axs[0,1].set_ylabel('Disease Index')
    axs[0,1].set_xticks(range(len(predicted_diseases)))
    axs[0,1].set_xticklabels([f'Test {i}' for i in range(len(predicted_diseases))])
    axs[0,1].grid(True, alpha=0.3)
    
    # Plot 3: Confidence scores
    confidence_scores = []
    for output in outputs:
        max_score = np.max(output)
        total_score = np.sum(np.abs(output))
        if total_score > 0:
            confidence = (max_score / total_score) * 100
        else:
            confidence = 0
        confidence_scores.append(confidence)
    
    axs[1,0].bar(range(len(confidence_scores)), confidence_scores, color='green', alpha=0.7)
    axs[1,0].set_title('Confidence Scores per Test')
    axs[1,0].set_xlabel('Test Index')
    axs[1,0].set_ylabel('Confidence (%)')
    axs[1,0].set_xticks(range(len(confidence_scores)))
    axs[1,0].set_xticklabels([f'Test {i}' for i in range(len(confidence_scores))])
    axs[1,0].grid(True, alpha=0.3)
    
    # Plot 4: Disease frequency analysis
    disease_counts = np.zeros(len(DISEASE_NAMES))
    for predicted in predicted_diseases:
        disease_counts[predicted] += 1
    
    axs[1,1].bar(range(len(DISEASE_NAMES)), disease_counts, color='orange', alpha=0.7)
    axs[1,1].set_title('Disease Prediction Frequency')
    axs[1,1].set_xlabel('Disease Index')
    axs[1,1].set_ylabel('Number of Predictions')
    axs[1,1].set_xticks(range(len(DISEASE_NAMES)))
    axs[1,1].set_xticklabels([f'{i}\n{name[:8]}' for i, name in enumerate(DISEASE_NAMES)], rotation=45)
    axs[1,1].grid(True, alpha=0.3)
    
    plt.tight_layout()
    plt.savefig(save_path, dpi=300, bbox_inches='tight')
    print(f"\nDisease analysis plot saved to {save_path}")

def generate_medical_report(outputs, test_names, report_path="medical_diagnosis_report.txt"):
    """Generate a comprehensive medical diagnosis report"""
    with open(report_path, 'w') as f:
        f.write("=== MEDICAL DIAGNOSIS SYSTEM REPORT ===\n")
        f.write(f"Date: {__import__('datetime').datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
        f.write(f"Total Tests: {len(outputs)}\n")
        f.write(f"Disease Classes: {len(DISEASE_NAMES)}\n\n")
        
        f.write("DISEASE MAPPING:\n")
        for i, name in enumerate(DISEASE_NAMES):
            f.write(f"  {i:2d}: {name}\n")
        f.write("\n")
        
        f.write("DETAILED TEST RESULTS:\n")
        for i, (output, test_name) in enumerate(zip(outputs, test_names)):
            f.write(f"\nTest {i}: {test_name}\n")
            f.write("-" * 50 + "\n")
            
            # Find predictions
            max_index = np.argmax(output)
            max_score = output[max_index]
            predicted_disease = DISEASE_NAMES[max_index]
            
            f.write(f"PRIMARY DIAGNOSIS:\n")
            f.write(f"  Disease: {predicted_disease}\n")
            f.write(f"  Confidence Score: {max_score}\n")
            f.write(f"  Disease Index: {max_index}\n")
            
            # Calculate confidence percentage
            total_score = np.sum(np.abs(output))
            if total_score > 0:
                confidence_pct = (max_score / total_score) * 100
                f.write(f"  Confidence: {confidence_pct:.1f}%\n")
            else:
                f.write(f"  Confidence: 0.0%\n")
            
            f.write(f"\nALL DISEASE SCORES:\n")
            for j, (score, disease) in enumerate(zip(output, DISEASE_NAMES)):
                f.write(f"  {j:2d}: {disease:25s}: {score:6d}\n")
            
            # Show top 3 predictions
            top_indices = np.argsort(output)[-3:][::-1]
            f.write(f"\nTOP 3 PREDICTIONS:\n")
            for j, idx in enumerate(top_indices):
                f.write(f"  {j+1}. {DISEASE_NAMES[idx]:25s}: {output[idx]:6d}\n")
        
        # Summary statistics
        f.write(f"\nSUMMARY STATISTICS:\n")
        f.write("-" * 50 + "\n")
        
        all_scores = np.concatenate(outputs)
        f.write(f"Overall Statistics:\n")
        f.write(f"  Mean Score: {np.mean(all_scores):.2f}\n")
        f.write(f"  Std Score:  {np.std(all_scores):.2f}\n")
        f.write(f"  Min Score:  {np.min(all_scores)}\n")
        f.write(f"  Max Score:  {np.max(all_scores)}\n")
        
        # Most common predictions
        predicted_diseases = [np.argmax(output) for output in outputs]
        disease_counts = np.bincount(predicted_diseases, minlength=len(DISEASE_NAMES))
        
        f.write(f"\nPrediction Frequency:\n")
        for i, count in enumerate(disease_counts):
            if count > 0:
                f.write(f"  {DISEASE_NAMES[i]:25s}: {count} predictions\n")
    
    print(f"Medical diagnosis report saved to {report_path}")

def main():
    parser = argparse.ArgumentParser(description="Analyze medical diagnosis hardware outputs")
    parser.add_argument('--hw_output', type=str, default='full_system_outputs.txt', 
                       help='Hardware output file')
    parser.add_argument('--num_tests', type=int, default=5, help='Number of testcases')
    parser.add_argument('--num_classes', type=int, default=15, help='Number of disease classes')
    parser.add_argument('--plot', type=str, default='disease_analysis.png', 
                       help='Output plot file')
    parser.add_argument('--report', type=str, default='medical_diagnosis_report.txt',
                       help='Medical report file')
    args = parser.parse_args()

    # Read hardware outputs
    if os.path.exists(args.hw_output):
        outputs, test_names = read_hardware_output(args.hw_output, args.num_tests, args.num_classes)
        print(f"Loaded {len(outputs)} hardware testcases")
    else:
        print(f"Error: Hardware output file {args.hw_output} not found")
        return

    # Analyze disease predictions
    analyze_disease_predictions(outputs, test_names)
    
    # Create analysis plots
    create_disease_analysis_plot(outputs, test_names, args.plot)
    
    # Generate medical report
    generate_medical_report(outputs, test_names, args.report)
    
    print(f"\nAnalysis complete!")
    print(f"  - Disease analysis plot: {args.plot}")
    print(f"  - Medical report: {args.report}")

if __name__ == "__main__":
    main() 