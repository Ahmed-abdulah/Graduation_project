#!/usr/bin/env python3
"""
Comprehensive Disease Classification Results Analyzer
Analyzes the results from testing all 15 disease categories
"""

import os
import sys
import re
from pathlib import Path

# Disease mapping
DISEASE_NAMES = [
    "No Finding", "Infiltration", "Atelectasis", "Effusion", "Nodule",
    "Pneumothorax", "Mass", "Consolidation", "Pleural Thickening", 
    "Cardiomegaly", "Emphysema", "Fibrosis", "Edema", "Pneumonia", "Hernia"
]

DISEASE_FILES = [
    "real_normal_xray.mem", "real_infiltration_xray.mem", "real_atelectasis_xray.mem",
    "real_effusion_xray.mem", "real_nodule_xray.mem", "real_pneumothorax_xray.mem",
    "real_mass_xray.mem", "real_consolidation_xray.mem", "real_pleural_thickening_xray.mem",
    "real_cardiomegaly_xray.mem", "real_emphysema_xray.mem", "real_fibrosis_xray.mem",
    "real_edema_xray.mem", "real_pneumonia_xray.mem", "real_hernia_xray.mem"
]

def parse_summary_file():
    """Parse the disease classification summary file"""
    summary_file = "disease_classification_summary.txt"
    
    if not os.path.exists(summary_file):
        print(f"❌ Summary file not found: {summary_file}")
        return None
    
    results = {
        'total_tests': 0,
        'correct_predictions': 0,
        'accuracy': 0.0,
        'total_cycles': 0,
        'avg_cycles': 0,
        'disease_results': []
    }
    
    try:
        with open(summary_file, 'r') as f:
            content = f.read()
            
            # Extract overall statistics
            if match := re.search(r'Total Diseases Tested: (\d+)', content):
                results['total_tests'] = int(match.group(1))
            
            if match := re.search(r'Correct Predictions: (\d+)', content):
                results['correct_predictions'] = int(match.group(1))
            
            if match := re.search(r'Overall Accuracy: ([\d.]+)%', content):
                results['accuracy'] = float(match.group(1))
            
            if match := re.search(r'Total Simulation Cycles: (\d+)', content):
                results['total_cycles'] = int(match.group(1))
            
            if match := re.search(r'Average Cycles per Disease: (\d+)', content):
                results['avg_cycles'] = int(match.group(1))
            
            # Parse detailed results table
            lines = content.split('\n')
            in_results_table = False
            
            for line in lines:
                if 'DETAILED RESULTS BY DISEASE:' in line:
                    in_results_table = True
                    continue
                elif in_results_table and '|' in line and 'Expected' not in line and '-' not in line:
                    parts = [p.strip() for p in line.split('|')]
                    if len(parts) >= 5:
                        disease_result = {
                            'expected': parts[0],
                            'predicted': parts[1],
                            'result': parts[2],
                            'confidence': int(parts[3]) if parts[3].isdigit() else 0,
                            'cycles': int(parts[4]) if parts[4].isdigit() else 0
                        }
                        results['disease_results'].append(disease_result)
                elif in_results_table and 'PERFORMANCE ANALYSIS:' in line:
                    break
        
        return results
    
    except Exception as e:
        print(f"❌ Error parsing summary file: {e}")
        return None

def analyze_confusion_matrix(results):
    """Create and analyze confusion matrix"""
    if not results or not results['disease_results']:
        return
    
    print("\n📊 CONFUSION MATRIX ANALYSIS")
    print("=" * 60)
    
    # Count predictions for each class
    confusion = {}
    for i, expected_name in enumerate(DISEASE_NAMES):
        confusion[expected_name] = {'correct': 0, 'total': 0, 'predicted_as': {}}
    
    for result in results['disease_results']:
        expected = result['expected']
        predicted = result['predicted']
        
        if expected in confusion:
            confusion[expected]['total'] += 1
            if result['result'] == 'CORRECT':
                confusion[expected]['correct'] += 1
            
            if predicted not in confusion[expected]['predicted_as']:
                confusion[expected]['predicted_as'][predicted] = 0
            confusion[expected]['predicted_as'][predicted] += 1
    
    # Display per-class accuracy
    print(f"{'Disease':<20} {'Accuracy':<10} {'Correct':<8} {'Total':<6} {'Main Misclassification'}")
    print("-" * 80)
    
    for disease_name in DISEASE_NAMES:
        if disease_name in confusion and confusion[disease_name]['total'] > 0:
            correct = confusion[disease_name]['correct']
            total = confusion[disease_name]['total']
            accuracy = (correct / total) * 100 if total > 0 else 0
            
            # Find most common misclassification
            predicted_as = confusion[disease_name]['predicted_as']
            main_misclass = "None"
            if len(predicted_as) > 1:
                # Find most common incorrect prediction
                for pred, count in predicted_as.items():
                    if pred != disease_name and count > 0:
                        main_misclass = f"{pred} ({count}x)"
                        break
            
            print(f"{disease_name:<20} {accuracy:>6.1f}%   {correct:>6}/{total:<5} {main_misclass}")

def analyze_performance_metrics(results):
    """Analyze performance metrics"""
    if not results:
        return
    
    print("\n⚡ PERFORMANCE ANALYSIS")
    print("=" * 40)
    print(f"Overall Accuracy: {results['accuracy']:.1f}%")
    print(f"Total Tests: {results['total_tests']}")
    print(f"Correct Predictions: {results['correct_predictions']}")
    print(f"Failed Predictions: {results['total_tests'] - results['correct_predictions']}")
    print(f"Total Simulation Cycles: {results['total_cycles']:,}")
    print(f"Average Cycles per Test: {results['avg_cycles']:,}")
    
    # Performance rating
    if results['accuracy'] >= 90:
        rating = "🌟 Excellent"
    elif results['accuracy'] >= 80:
        rating = "✅ Good"
    elif results['accuracy'] >= 70:
        rating = "⚠️  Fair"
    elif results['accuracy'] >= 60:
        rating = "🔶 Poor"
    else:
        rating = "❌ Very Poor"
    
    print(f"Performance Rating: {rating}")

def check_missing_files():
    """Check which disease files are missing"""
    print("\n📁 DISEASE FILE STATUS")
    print("=" * 40)
    
    missing_files = []
    existing_files = []
    
    for i, filename in enumerate(DISEASE_FILES):
        if os.path.exists(filename):
            existing_files.append((filename, DISEASE_NAMES[i]))
            print(f"✅ {filename:<30} ({DISEASE_NAMES[i]})")
        else:
            missing_files.append((filename, DISEASE_NAMES[i]))
            print(f"❌ {filename:<30} ({DISEASE_NAMES[i]})")
    
    print(f"\nSummary: {len(existing_files)} files found, {len(missing_files)} missing")
    
    if missing_files:
        print(f"\n⚠️  Missing files need to be generated:")
        for filename, disease in missing_files:
            print(f"   {filename}")
        print(f"\nRun: ./convert_all_diseases_working.sh")
    
    return len(missing_files) == 0

def generate_recommendations(results):
    """Generate recommendations based on results"""
    if not results:
        return
    
    print("\n💡 RECOMMENDATIONS")
    print("=" * 40)
    
    accuracy = results['accuracy']
    
    if accuracy >= 85:
        print("✅ Model Performance: Excellent")
        print("   - The neural network is working very well")
        print("   - Consider deploying for medical screening")
        print("   - Monitor for edge cases")
    elif accuracy >= 75:
        print("✅ Model Performance: Good")
        print("   - The neural network shows good performance")
        print("   - Consider fine-tuning for better accuracy")
        print("   - Test with more diverse datasets")
    elif accuracy >= 65:
        print("⚠️  Model Performance: Needs Improvement")
        print("   - Consider retraining with more data")
        print("   - Check data preprocessing pipeline")
        print("   - Verify model architecture")
    else:
        print("❌ Model Performance: Poor")
        print("   - Model needs significant retraining")
        print("   - Check input data format and preprocessing")
        print("   - Consider different model architecture")
        print("   - Verify hardware implementation")
    
    # Cycle performance
    if results['avg_cycles'] > 1000000:
        print("\n⚠️  Performance Optimization:")
        print("   - High cycle count detected")
        print("   - Consider pipeline optimization")
        print("   - Check for timing bottlenecks")
    else:
        print("\n✅ Timing Performance: Good")
        print("   - Reasonable cycle count for medical AI")
    
    # Specific disease recommendations
    if results['disease_results']:
        low_accuracy_diseases = []
        for result in results['disease_results']:
            if result['result'] == 'INCORRECT':
                low_accuracy_diseases.append(result['expected'])
        
        if low_accuracy_diseases:
            print(f"\n🎯 Focus Areas for Improvement:")
            unique_diseases = list(set(low_accuracy_diseases))
            for disease in unique_diseases[:5]:  # Show top 5
                print(f"   - {disease}: Needs attention")

def main():
    """Main analysis function"""
    print("🏥 COMPREHENSIVE DISEASE CLASSIFICATION ANALYSIS")
    print("=" * 60)
    
    # Check if we're in the right directory
    if not os.path.exists("disease_classification_summary.txt"):
        print("⚠️  Summary file not found in current directory")
        print("   Make sure you're in the FULL_SYSTEM directory")
        print("   Run the simulation first: vsim -do FULL_TOP/run_all_diseases_test.do")
        return
    
    # Check file availability
    all_files_exist = check_missing_files()
    
    # Parse results
    results = parse_summary_file()
    
    if results:
        # Analyze results
        analyze_performance_metrics(results)
        analyze_confusion_matrix(results)
        generate_recommendations(results)
        
        print(f"\n📋 DETAILED LOGS:")
        print(f"   - disease_classification_summary.txt (Main Results)")
        print(f"   - all_diseases_diagnosis.txt (Detailed Analysis)")
        print(f"   - all_diseases_testbench.log (Technical Log)")
        
    else:
        print("❌ Could not parse results. Check if simulation completed successfully.")
    
    print(f"\n🎯 Analysis Complete!")

if __name__ == "__main__":
    main()
