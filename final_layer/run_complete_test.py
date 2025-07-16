#!/usr/bin/env python3
"""
Complete Test Workflow Script
This script automates the entire testing process:
1. Runs the SystemVerilog testbench
2. Generates software reference outputs
3. Performs comprehensive analysis
"""

import subprocess
import os
import sys
import argparse

def run_command(cmd, description):
    """Run a command and handle errors"""
    print(f"\n=== {description} ===")
    print(f"Running: {cmd}")
    
    try:
        result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
        if result.returncode != 0:
            print(f"ERROR: Command failed with return code {result.returncode}")
            print(f"STDOUT: {result.stdout}")
            print(f"STDERR: {result.stderr}")
            return False
        else:
            print(f"SUCCESS: {description}")
            if result.stdout:
                print(f"Output: {result.stdout}")
            return True
    except Exception as e:
        print(f"ERROR: Failed to run command: {e}")
        return False

def main():
    parser = argparse.ArgumentParser(description="Run complete test workflow for final layer")
    parser.add_argument('--simulator', type=str, default='vsim', 
                       choices=['vsim', 'vsim-gui', 'questa', 'questa-gui'],
                       help='Simulator to use (default: vsim)')
    parser.add_argument('--do-file', type=str, default='run_tb_final_layer_top.do',
                       help='DO file to run (default: run_tb_final_layer_top.do)')
    parser.add_argument('--skip-simulation', action='store_true',
                       help='Skip simulation step (useful for analysis only)')
    parser.add_argument('--skip-analysis', action='store_true',
                       help='Skip analysis step (useful for simulation only)')
    args = parser.parse_args()

    print("=== FINAL LAYER COMPLETE TEST WORKFLOW ===")
    print(f"Simulator: {args.simulator}")
    print(f"DO file: {args.do_file}")
    
    # Step 1: Run simulation (if not skipped)
    if not args.skip_simulation:
        if not os.path.exists(args.do_file):
            print(f"ERROR: DO file {args.do_file} not found!")
            return False
            
        # Run ModelSim/Questa simulation
        sim_cmd = f"{args.simulator} -c -do {args.do_file}"
        if not run_command(sim_cmd, "Running SystemVerilog simulation"):
            print("Simulation failed! Check the DO file and SystemVerilog files.")
            return False
    
    # Step 2: Generate software reference (if needed)
    if not args.skip_analysis:
        if not os.path.exists("sw_output.mem"):
            print("\n=== GENERATING SOFTWARE REFERENCE ===")
            print("Note: Software reference file 'sw_output.mem' not found.")
            print("You can generate it using your PyTorch model with the same input.")
            print("For now, analysis will proceed without software reference.")
    
    # Step 3: Run analysis
    if not args.skip_analysis:
        analysis_cmd = "python analyze_final_layer_results.py"
        if not run_command(analysis_cmd, "Running comprehensive analysis"):
            print("Analysis failed! Check the Python script and output files.")
            return False
    
    # Step 4: Display results summary
    print("\n=== WORKFLOW COMPLETED ===")
    print("Generated files:")
    
    files_to_check = [
        ("testbench.log", "Detailed testbench log"),
        ("all_test_outputs.txt", "All testcase outputs"),
        ("comprehensive_analysis.png", "Analysis plots"),
        ("sw_output.mem", "Software reference (if available)")
    ]
    
    for filename, description in files_to_check:
        if os.path.exists(filename):
            size = os.path.getsize(filename)
            print(f"  ✓ {filename} ({size} bytes) - {description}")
        else:
            print(f"  ✗ {filename} - {description} (not found)")
    
    print("\nNext steps:")
    print("1. Check testbench.log for detailed test results")
    print("2. View comprehensive_analysis.png for visual analysis")
    print("3. Compare hardware outputs with software reference")
    
    return True

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1) 