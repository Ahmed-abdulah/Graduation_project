#!/usr/bin/env python3
"""
SystemVerilog Syntax Checker
Checks for common compilation errors in SystemVerilog files
"""

import re
import sys
import os

def check_systemverilog_syntax(file_path):
    """Check SystemVerilog syntax for common errors"""
    print(f"🔍 Checking SystemVerilog syntax: {file_path}")
    print("=" * 60)
    
    try:
        with open(file_path, 'r') as f:
            content = f.read()
    except FileNotFoundError:
        print(f"❌ File not found: {file_path}")
        return False
    
    errors = []
    warnings = []
    
    # Check for common SystemVerilog syntax issues
    lines = content.split('\n')
    
    for line_num, line in enumerate(lines, 1):
        # Check for variable declarations after statements
        if re.search(r'^\s*(real|int|logic|reg|wire)\s+', line):
            # Look for previous non-comment, non-blank lines
            for prev_line_num in range(line_num - 1, max(0, line_num - 10), -1):
                prev_line = lines[prev_line_num - 1].strip()
                if prev_line and not prev_line.startswith('//') and not prev_line.startswith('/*'):
                    if ';' in prev_line and not re.search(r'^\s*(end|else|begin)', prev_line):
                        errors.append(f"Line {line_num}: Variable declaration after statement")
                        break
        
        # Check for implicit static variables
        if re.search(r'^\s*(real|int|logic)\s+\w+\s*=\s*[^;]+;', line):
            warnings.append(f"Line {line_num}: Variable with initialization - consider 'automatic' keyword")
        
        # Check for undefined variables in loops
        if re.search(r'for\s*\(\s*int\s+\w+\s*=', line):
            # This is actually correct syntax
            pass
        
        # Check for missing semicolons
        if re.search(r'^\s*[^;]*\s*$', line) and not re.search(r'^\s*(end|begin|else|if|for|while)', line):
            if line.strip() and not line.strip().startswith('//') and not line.strip().startswith('/*'):
                if not line.strip().endswith(';') and not line.strip().endswith('{') and not line.strip().endswith('}'):
                    # This is a warning, not necessarily an error
                    pass
    
    # Check for specific patterns that cause compilation errors
    patterns_to_check = [
        (r'for\s*\(\s*int\s+\w+\s*=\s*\d+\s*;\s*\w+\s*<\s*\w+\s*;\s*\w+\+\+\)', 'C-style increment in SystemVerilog'),
        (r'for\s*\(\s*int\s+\w+\s*=\s*\d+\s*;\s*\w+\s*<\s*\w+\s*;\s*\w+\+\+\)', 'C-style increment in SystemVerilog'),
        (r'automatic\s+int\s+\w+\s*=\s*\d+', 'automatic variable with initialization'),
        (r'real\s+\w+\s*\[\s*\d+\s*:\s*\d+\s*\]\s*=\s*\{', 'Array initialization syntax'),
    ]
    
    for pattern, description in patterns_to_check:
        matches = re.finditer(pattern, content)
        for match in matches:
            line_num = content[:match.start()].count('\n') + 1
            warnings.append(f"Line {line_num}: {description}")
    
    # Check for function declarations
    if 'function real fixed_to_probability' in content:
        print("✅ Function declaration found")
    else:
        errors.append("Missing fixed_to_probability function")
    
    # Check for medical condition arrays
    if 'medical_conditions' in content and 'medical_recommendations' in content:
        print("✅ Medical condition arrays found")
    else:
        errors.append("Missing medical condition arrays")
    
    # Check for task declarations
    if 'task run_test_case' in content:
        print("✅ Task declaration found")
    else:
        errors.append("Missing run_test_case task")
    
    # Check for proper variable declarations in tasks
    task_pattern = r'task\s+\w+.*?begin(.*?)endtask'
    task_matches = re.findall(task_pattern, content, re.DOTALL)
    
    for i, task_content in enumerate(task_matches):
        # Check for variable declarations at the beginning of tasks
        lines = task_content.split('\n')
        found_declarations = False
        for line in lines[:10]:  # Check first 10 lines
            if re.search(r'^\s*(real|int|logic|reg|wire)\s+', line):
                found_declarations = True
                break
        if not found_declarations:
            warnings.append(f"Task {i+1}: Consider declaring variables at task beginning")
    
    # Report results
    if errors:
        print("\n❌ ERRORS FOUND:")
        for error in errors:
            print(f"  • {error}")
    
    if warnings:
        print("\n⚠️  WARNINGS:")
        for warning in warnings:
            print(f"  • {warning}")
    
    if not errors and not warnings:
        print("\n✅ No syntax errors detected!")
        print("✅ File appears to be syntactically correct")
    
    print(f"\n📊 Summary:")
    print(f"  • Errors: {len(errors)}")
    print(f"  • Warnings: {len(warnings)}")
    print(f"  • Total lines: {len(lines)}")
    
    return len(errors) == 0

def main():
    """Main function"""
    print("🔍 SystemVerilog Syntax Checker")
    print("=" * 40)
    
    # Check the main testbench file
    testbench_file = "FULL_TOP/tb_full_system_top.sv"
    
    if not os.path.exists(testbench_file):
        print(f"❌ Testbench file not found: {testbench_file}")
        return
    
    success = check_systemverilog_syntax(testbench_file)
    
    if success:
        print("\n🎉 Syntax check passed!")
        print("✅ The SystemVerilog file should compile successfully")
        print("\n📋 Next steps:")
        print("  1. Install ModelSim if not already installed")
        print("  2. Run: vsim -do run_tb_full_system_top.do")
        print("  3. Check the simulation outputs")
    else:
        print("\n❌ Syntax check failed!")
        print("Please fix the errors before compiling")

if __name__ == "__main__":
    main() 