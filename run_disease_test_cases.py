#!/usr/bin/env python3
"""
Run tests on the generated disease test cases
"""

import os
import sys
import glob
import shutil
import subprocess
import time
import json
from pathlib import Path
from prepare_disease_images_simple import DISEASE_PATTERNS

def run_test(test_file, output_dir):
    """Run a single test case and save results"""
    print(f"\n🔍 Testing {test_file}...")
    
    # Create output directory if it doesn't exist
    os.makedirs(output_dir, exist_ok=True)
    
    # Backup current test image if it exists
    if os.path.exists("test_image.mem"):
        shutil.copy("test_image.mem", "test_image_backup.mem")
    
    # Copy test case to test image
    shutil.copy(test_file, "test_image.mem")
    print(f"  ✓ Copied {test_file} to test_image.mem")
    
    # Extract disease name and case number from filename
    filename = os.path.basename(test_file)
    disease_name = filename.split('_')[0]
    case_info = filename.replace('.mem', '').split('_', 1)[1]
    
    # Run simulation
    print("  ⚙️ Running simulation...")
    sim_output_file = os.path.join(output_dir, f"{disease_name}_{case_info}_sim.log")
    
    try:
        result = subprocess.run(["vsim", "-c", "-do", "run_tb_full_system_top.do"], 
                               capture_output=True, text=True, timeout=300)
        
        # Save simulation output
        with open(sim_output_file, 'w') as f:
            f.write(result.stdout)
            f.write("\n\n--- STDERR ---\n\n")
            f.write(result.stderr)
        
        # Check if simulation was successful
        if result.returncode == 0:
            print(f"  ✓ Simulation completed successfully (log: {sim_output_file})")
            sim_success = True
        else:
            print(f"  ✗ Simulation failed (log: {sim_output_file})")
            print(f"  Error: {result.stderr[:100]}...")
            sim_success = False
            
    except subprocess.TimeoutExpired:
        print("  ✗ Simulation timed out after 5 minutes")
        with open(sim_output_file, 'w') as f:
            f.write("SIMULATION TIMEOUT")
        sim_success = False
    
    # Run analysis if simulation was successful
    if sim_success:
        print("  📊 Analyzing results...")
        analysis_output_file = os.path.join(output_dir, f"{disease_name}_{case_info}_analysis.log")
        
        try:
            analysis = subprocess.run(["python", "analyze_disease_hex_outputs.py"],
                                     capture_output=True, text=True, timeout=60)
            
            # Save analysis output
            with open(analysis_output_file, 'w') as f:
                f.write(analysis.stdout)
                f.write("\n\n--- STDERR ---\n\n")
                f.write(analysis.stderr)
            
            print(f"  ✓ Analysis completed (log: {analysis_output_file})")
            
            # Extract results (simplified - adapt to your actual output format)
            detected_disease = "unknown"
            confidence = 0.0
            
            # Parse the analysis output to extract detected disease and confidence
            # This is a placeholder - you'll need to adapt this to your actual output format
            for line in analysis.stdout.splitlines():
                if "Detected:" in line:
                    detected_disease = line.split("Detected:")[1].strip()
                if "Confidence:" in line:
                    try:
                        confidence = float(line.split("Confidence:")[1].strip().rstrip('%')) / 100.0
                    except:
                        confidence = 0.0
            
            analysis_success = True
            
        except subprocess.TimeoutExpired:
            print("  ✗ Analysis timed out")
            with open(analysis_output_file, 'w') as f:
                f.write("ANALYSIS TIMEOUT")
            analysis_success = False
            detected_disease = "timeout"
            confidence = 0.0
    else:
        analysis_success = False
        detected_disease = "simulation_failed"
        confidence = 0.0
    
    # Restore original test image if backup exists
    if os.path.exists("test_image_backup.mem"):
        shutil.copy("test_image_backup.mem", "test_image.mem")
        os.remove("test_image_backup.mem")
    
    # Return test results
    return {
        "test_file": test_file,
        "disease": disease_name,
        "case_info": case_info,
        "expected": disease_name,
        "detected": detected_disease,
        "confidence": confidence,
        "simulation_success": sim_success,
        "analysis_success": analysis_success,
        "correct_detection": disease_name.lower() in detected_disease.lower()
    }

def run_disease_tests(disease_name, output_dir="test_results"):
    """Run tests for all test cases of a specific disease"""
    print(f"\n🏥 Running tests for {disease_name.upper()}")
    print("=" * 50)
    
    # Find all test cases for this disease
    test_dir = Path("test_cases/numbered")
    test_files = list(test_dir.glob(f"{disease_name}_case*.mem"))
    
    if not test_files:
        print(f"No test cases found for {disease_name}")
        print("Run: python generate_disease_test_cases.py --disease " + disease_name)
        return []
    
    print(f"Found {len(test_files)} test cases")
    
    # Run tests for each case
    results = []
    for test_file in sorted(test_files):
        result = run_test(str(test_file), output_dir)
        results.append(result)
        time.sleep(1)  # Small delay between tests
    
    # Save results to JSON
    results_file = os.path.join(output_dir, f"{disease_name}_results.json")
    with open(results_file, 'w') as f:
        json.dump(results, f, indent=2)
    
    print(f"\n✓ Results saved to {results_file}")
    
    # Print summary
    correct = sum(1 for r in results if r["correct_detection"])
    print(f"\n📊 Summary: {correct}/{len(results)} correct detections")
    
    return results

def run_all_disease_tests(output_dir="test_results"):
    """Run tests for all diseases"""
    print("🏥 RUNNING TESTS FOR ALL DISEASES")
    print("=" * 50)
    
    # Create output directory
    os.makedirs(output_dir, exist_ok=True)
    
    all_results = {}
    for disease in DISEASE_PATTERNS.keys():
        results = run_disease_tests(disease, output_dir)
        all_results[disease] = results
    
    # Calculate overall statistics
    total_tests = sum(len(results) for results in all_results.values())
    total_correct = sum(sum(1 for r in results if r["correct_detection"]) 
                        for results in all_results.values())
    
    # Save overall results
    summary = {
        "total_tests": total_tests,
        "total_correct": total_correct,
        "accuracy": total_correct / total_tests if total_tests > 0 else 0,
        "results_by_disease": {
            disease: {
                "total": len(results),
                "correct": sum(1 for r in results if r["correct_detection"]),
                "accuracy": sum(1 for r in results if r["correct_detection"]) / len(results) if results else 0
            }
            for disease, results in all_results.items()
        }
    }
    
    summary_file = os.path.join(output_dir, "overall_summary.json")
    with open(summary_file, 'w') as f:
        json.dump(summary, f, indent=2)
    
    # Print summary
    print("\n📊 OVERALL SUMMARY:")
    print("=" * 50)
    print(f"Total test cases: {total_tests}")
    print(f"Correct detections: {total_correct}")
    print(f"Overall accuracy: {total_correct/total_tests:.2%}")
    print(f"\nDetailed results saved to {summary_file}")
    
    # Print per-disease summary
    print("\n📊 RESULTS BY DISEASE:")
    for disease, stats in summary["results_by_disease"].items():
        print(f"  {disease:15} | {stats['correct']}/{stats['total']} correct | {stats['accuracy']:.2%} accuracy")

def main():
    """Main function"""
    print("🏥 Disease Test Runner")
    print("=" * 40)
    
    if len(sys.argv) < 2:
        print("\nUsage:")
        print("  python run_disease_test_cases.py --all")
        print("  python run_disease_test_cases.py --disease <disease_name>")
        print("\nAvailable diseases:")
        for disease in DISEASE_PATTERNS.keys():
            print(f"  - {disease}")
        return
    
    if sys.argv[1] == "--all":
        run_all_disease_tests()
    elif sys.argv[1] == "--disease" and len(sys.argv) >= 3:
        disease_name = sys.argv[2]
        run_disease_tests(disease_name)
    else:
        print("Invalid command. Use --all or --disease <name>")

if __name__ == "__main__":
    main()