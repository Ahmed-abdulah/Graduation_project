#!/usr/bin/env python3
"""
Simple SystemVerilog syntax checker for port connections
"""

import re
import os

def extract_module_ports(filename):
    """Extract module ports from SystemVerilog file"""
    with open(filename, 'r') as f:
        content = f.read()
    
    # Find module declaration
    module_match = re.search(r'module\s+(\w+)\s*#?\s*\([^)]*\)\s*\(([^)]*)\)', content, re.DOTALL)
    if not module_match:
        return None, []
    
    module_name = module_match.group(1)
    ports_text = module_match.group(2)
    
    # Parse ports
    ports = []
    lines = ports_text.split('\n')
    for line in lines:
        line = line.strip()
        if not line or line.startswith('//'):
            continue
        
        # Match input/output declarations
        port_match = re.search(r'(input|output)\s+(?:wire|reg|logic)?\s*(?:\[[^\]]+\])?\s*(\w+)', line)
        if port_match:
            direction = port_match.group(1)
            port_name = port_match.group(2)
            ports.append((direction, port_name))
    
    return module_name, ports

def check_connections():
    """Check port connections between modules"""
    
    print("=== Checking SystemVerilog Port Connections ===\n")
    
    # Check accelerator module
    print("1. Checking accelerator.sv:")
    acc_name, acc_ports = extract_module_ports("First_layer/accelerator.sv")
    if acc_name:
        print(f"   Module: {acc_name}")
        print("   Output ports:")
        for direction, port in acc_ports:
            if direction == "output":
                print(f"     - {port}")
    else:
        print("   ERROR: Could not parse accelerator module")
    
    print("\n2. Checking full_system_top.sv connections:")
    
    # Read full system top to check connections
    with open("FULL_TOP/full_system_top.sv", 'r') as f:
        content = f.read()
    
    # Find accelerator instantiation
    acc_inst = re.search(r'accelerator\s+#\s*\([^)]*\)\s*(\w+)\s*\(([^)]*)\)', content, re.DOTALL)
    if acc_inst:
        instance_name = acc_inst.group(1)
        connections = acc_inst.group(2)
        
        print(f"   Instance: {instance_name}")
        print("   Connections:")
        
        # Parse connections
        conn_lines = connections.split('\n')
        for line in conn_lines:
            line = line.strip()
            if not line or line.startswith('//'):
                continue
            
            conn_match = re.search(r'\.(\w+)\s*\(([^)]+)\)', line)
            if conn_match:
                port = conn_match.group(1)
                signal = conn_match.group(2).strip()
                print(f"     - {port} -> {signal}")
    else:
        print("   ERROR: Could not find accelerator instantiation")
    
    print("\n3. Checking BNeck module:")
    bneck_name, bneck_ports = extract_module_ports("BNECK/mobilenetv3_top_optimized.sv")
    if bneck_name:
        print(f"   Module: {bneck_name}")
        print("   Input ports:")
        for direction, port in bneck_ports:
            if direction == "input":
                print(f"     - {port}")
    else:
        print("   ERROR: Could not parse BNeck module")
    
    print("\n=== Syntax Check Complete ===")

if __name__ == "__main__":
    check_connections() 