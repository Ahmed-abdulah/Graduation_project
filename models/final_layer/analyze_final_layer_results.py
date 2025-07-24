import numpy as np
import matplotlib.pyplot as plt
import argparse
import os
import re

# Helper to read .mem file (hex, one value per line)
def read_mem_file(filename, width=16, num_classes=15):
    with open(filename, 'r') as f:
        lines = f.readlines()
    arr = np.array([int(line.strip(), 16) for line in lines], dtype=np.uint16)
    # Convert to signed
    arr = arr.astype(np.int16)
    if len(arr) != num_classes:
        print(f"Warning: Expected {num_classes} classes, got {len(arr)} values in {filename}")
    return arr

# Helper to read testbench output file with multiple testcases
def read_testbench_output(filename, num_tests=8, num_classes=15):
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

def main():
    parser = argparse.ArgumentParser(description="Analyze and compare hardware and software outputs for final layer.")
    parser.add_argument('--hw', type=str, default='all_test_outputs.txt', help='Hardware output file from testbench')
    parser.add_argument('--sw', type=str, default='sw_output.mem', help='Software (PyTorch) output .mem file')
    parser.add_argument('--width', type=int, default=16, help='Bit width (default: 16)')
    parser.add_argument('--num_classes', type=int, default=15, help='Number of classes (default: 15)')
    parser.add_argument('--num_tests', type=int, default=8, help='Number of testcases (default: 8)')
    parser.add_argument('--report', type=str, default='comprehensive_analysis.png', help='Output plot/report file')
    args = parser.parse_args()

    # Read hardware outputs (multiple testcases)
    if os.path.exists(args.hw):
        hw_outputs, test_names = read_testbench_output(args.hw, args.num_tests, args.num_classes)
        print(f"Loaded {len(hw_outputs)} hardware testcases")
    else:
        print(f"Warning: Hardware output file {args.hw} not found")
        hw_outputs = []
        test_names = []

    # Read software output (single reference)
    if os.path.exists(args.sw):
        sw_output = read_mem_file(args.sw, width=args.width, num_classes=args.num_classes)
        print(f"Loaded software reference output")
    else:
        print(f"Warning: Software output file {args.sw} not found")
        sw_output = np.zeros(args.num_classes, dtype=np.int16)

    # Analysis for each testcase
    if hw_outputs:
        print("\n=== COMPREHENSIVE ANALYSIS ===")
        
        # Create comprehensive plot
        fig, axs = plt.subplots(2, 2, figsize=(15, 12))
        
        # Plot 1: All testcase outputs comparison
        x = np.arange(args.num_classes)
        for i, (hw_out, test_name) in enumerate(zip(hw_outputs, test_names)):
            axs[0,0].plot(x, hw_out, marker='o', label=f'Test {i}: {test_name[:20]}...')
        if len(sw_output) > 0:
            axs[0,0].plot(x, sw_output, marker='s', linewidth=3, label='Software Reference')
        axs[0,0].set_title('All Testcase Outputs Comparison')
        axs[0,0].set_xlabel('Class Index')
        axs[0,0].set_ylabel('Score (quantized)')
        axs[0,0].legend(bbox_to_anchor=(1.05, 1), loc='upper left')
        axs[0,0].grid(True, alpha=0.3)

        # Plot 2: Error analysis (if software reference available)
        if len(sw_output) > 0:
            errors = []
            for hw_out in hw_outputs:
                abs_err = np.abs(hw_out - sw_output)
                errors.append(np.mean(abs_err))
            
            axs[0,1].bar(range(len(errors)), errors)
            axs[0,1].set_title('Mean Absolute Error per Testcase')
            axs[0,1].set_xlabel('Testcase Index')
            axs[0,1].set_ylabel('Mean Absolute Error')
            axs[0,1].set_xticks(range(len(errors)))
            axs[0,1].set_xticklabels([f'Test {i}' for i in range(len(errors))], rotation=45)
            axs[0,1].grid(True, alpha=0.3)

        # Plot 3: Output range analysis
        all_outputs = np.array(hw_outputs)
        output_ranges = np.ptp(all_outputs, axis=0)  # Peak-to-peak range per class
        axs[1,0].bar(x, output_ranges)
        axs[1,0].set_title('Output Range per Class (across all testcases)')
        axs[1,0].set_xlabel('Class Index')
        axs[1,0].set_ylabel('Range (max - min)')
        axs[1,0].grid(True, alpha=0.3)

        # Plot 4: Testcase performance summary
        testcase_stats = []
        for i, hw_out in enumerate(hw_outputs):
            stats = {
                'mean': np.mean(hw_out),
                'std': np.std(hw_out),
                'max': np.max(hw_out),
                'min': np.min(hw_out)
            }
            testcase_stats.append(stats)
        
        means = [s['mean'] for s in testcase_stats]
        stds = [s['std'] for s in testcase_stats]
        
        axs[1,1].bar(range(len(means)), means, yerr=stds, capsize=5)
        axs[1,1].set_title('Output Statistics per Testcase')
        axs[1,1].set_xlabel('Testcase Index')
        axs[1,1].set_ylabel('Mean Score ± Std Dev')
        axs[1,1].set_xticks(range(len(means)))
        axs[1,1].set_xticklabels([f'Test {i}' for i in range(len(means))], rotation=45)
        axs[1,1].grid(True, alpha=0.3)

        plt.tight_layout()
        plt.savefig(args.report, dpi=300, bbox_inches='tight')
        print(f"\nComprehensive analysis plot saved to {args.report}")

        # Print detailed statistics
        print("\n=== DETAILED STATISTICS ===")
        for i, (hw_out, test_name) in enumerate(zip(hw_outputs, test_names)):
            print(f"\nTest {i}: {test_name}")
            print(f"  Mean: {np.mean(hw_out):.2f}")
            print(f"  Std:  {np.std(hw_out):.2f}")
            print(f"  Min:  {np.min(hw_out)}")
            print(f"  Max:  {np.max(hw_out)}")
            if len(sw_output) > 0:
                abs_err = np.abs(hw_out - sw_output)
                print(f"  Mean Abs Error vs SW: {np.mean(abs_err):.2f}")
                print(f"  Max Abs Error vs SW: {np.max(abs_err)}")

    else:
        print("No hardware outputs found for analysis")

    plt.show()

if __name__ == "__main__":
    main() 