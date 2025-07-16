# 🏥 Manual Disease Testing Guide

This guide shows you how to test different disease patterns with your medical X-ray classification system.

## 📋 Available Disease Patterns

The following disease patterns have been created:

| Disease | File | Description |
|---------|------|-------------|
| `normal` | `disease_normal.mem` | Normal chest X-ray |
| `pneumonia` | `disease_pneumonia.mem` | Pneumonia - lung infection |
| `pneumothorax` | `disease_pneumothorax.mem` | Pneumothorax - collapsed lung |
| `atelectasis` | `disease_atelectasis.mem` | Atelectasis - partial lung collapse |
| `effusion` | `disease_effusion.mem` | Pleural effusion - fluid around lungs |
| `cardiomegaly` | `disease_cardiomegaly.mem` | Cardiomegaly - enlarged heart |
| `nodule` | `disease_nodule.mem` | Pulmonary nodule |
| `mass` | `disease_mass.mem` | Lung mass |
| `consolidation` | `disease_consolidation.mem` | Lung consolidation |
| `emphysema` | `disease_emphysema.mem` | Emphysema |

## 🔧 Manual Testing Steps

### Step 1: Choose a Disease to Test

```bash
# List available disease files
ls disease_*.mem
```

### Step 2: Copy Disease Pattern to Test Image

```bash
# Example: Test pneumonia
cp disease_pneumonia.mem test_image.mem

# Example: Test pneumothorax (urgent condition)
cp disease_pneumothorax.mem test_image.mem

# Example: Test normal X-ray
cp disease_normal.mem test_image.mem
```

### Step 3: Run Hardware Simulation

```bash
# Run the simulation
vsim -do run_tb_full_system_top.do
```

### Step 4: Analyze Results

```bash
# Analyze the hex outputs
python analyze_disease_hex_outputs.py
```

## 🧪 Testing Examples

### Example 1: Test Pneumonia

```bash
# 1. Copy pneumonia pattern
cp disease_pneumonia.mem test_image.mem

# 2. Run simulation
vsim -do run_tb_full_system_top.do

# 3. Analyze results
python analyze_disease_hex_outputs.py
```

**Expected Results:**
- Primary diagnosis should be "Pneumonia"
- High confidence in pneumonia detection
- Secondary findings may include consolidation
- Urgency: Standard urgency (schedule appointment within 1-2 weeks)

### Example 2: Test Pneumothorax (Urgent)

```bash
# 1. Copy pneumothorax pattern
cp disease_pneumothorax.mem test_image.mem

# 2. Run simulation
vsim -do run_tb_full_system_top.do

# 3. Analyze results
python analyze_disease_hex_outputs.py
```

**Expected Results:**
- Primary diagnosis should be "Pneumothorax"
- High confidence in pneumothorax detection
- Urgency: HIGH URGENCY - Seek emergency care immediately!

### Example 3: Test Normal X-ray

```bash
# 1. Copy normal pattern
cp disease_normal.mem test_image.mem

# 2. Run simulation
vsim -do run_tb_full_system_top.do

# 3. Analyze results
python analyze_disease_hex_outputs.py
```

**Expected Results:**
- Primary diagnosis should be "No Finding"
- Low confidence in any disease detection
- Urgency: LOW URGENCY - Normal findings, routine follow-up

## 📊 Understanding Results

### Medical Analysis Output

The analysis script provides:

1. **Primary Diagnosis**: The most likely condition
2. **Confidence Level**: Probability (0-100%)
3. **Secondary Findings**: Other conditions with >30% probability
4. **Urgency Assessment**: Medical urgency level
5. **Clinical Recommendations**: Medical advice

### Expected Disease Mappings

| Test Pattern | Expected Primary Diagnosis | Urgency Level |
|--------------|---------------------------|---------------|
| `normal` | No Finding | Low |
| `pneumonia` | Pneumonia | Standard |
| `pneumothorax` | Pneumothorax | High |
| `atelectasis` | Atelectasis | Moderate |
| `effusion` | Effusion | Standard |
| `cardiomegaly` | Cardiomegaly | Standard |
| `nodule` | Nodule | Standard |
| `mass` | Mass | Moderate |
| `consolidation` | Consolidation | Standard |
| `emphysema` | Emphysema | Standard |

## 🔍 Troubleshooting

### If Simulation Fails

1. **Check ModelSim Installation:**
   ```bash
   vsim -version
   ```

2. **Check Project Files:**
   ```bash
   ls *.sv
   ls *.do
   ```

3. **Check Memory Files:**
   ```bash
   ls *.mem
   wc -l test_image.mem  # Should be 50176 lines
   ```

### If Analysis Fails

1. **Check Output Files:**
   ```bash
   ls full_system_*.txt
   ls full_system_*.log
   ```

2. **Check Hex Values:**
   ```bash
   grep -i "0x" full_system_outputs.txt
   ```

## 📈 Performance Testing

### Test All Diseases

```bash
# Run comprehensive testing
python test_all_diseases.py --all
```

### Test Specific Disease

```bash
# Test a specific disease
python test_all_diseases.py --disease pneumonia
```

## 🎯 Advanced Testing

### Custom Image Testing

1. **Prepare your own X-ray image:**
   ```bash
   python prepare_disease_images_simple.py your_xray.jpg
   ```

2. **Test with custom image:**
   ```bash
   cp test_image.mem your_test.mem
   vsim -do run_tb_full_system_top.do
   python analyze_disease_hex_outputs.py
   ```

### Batch Testing

Create a script to test multiple images:

```bash
#!/bin/bash
# Test multiple diseases
for disease in pneumonia pneumothorax normal; do
    echo "Testing $disease..."
    cp disease_${disease}.mem test_image.mem
    vsim -do run_tb_full_system_top.do
    python analyze_disease_hex_outputs.py > results_${disease}.txt
done
```

## 📋 Quick Reference

### Common Commands

```bash
# List disease patterns
ls disease_*.mem

# Test specific disease
cp disease_pneumonia.mem test_image.mem
vsim -do run_tb_full_system_top.do
python analyze_disease_hex_outputs.py

# Check file sizes
wc -l disease_*.mem

# View results
cat medical_diagnosis_report.txt
```

### File Locations

- **Disease Patterns**: `disease_*.mem`
- **Test Image**: `test_image.mem`
- **Simulation Output**: `full_system_outputs.txt`
- **Analysis Report**: `medical_diagnosis_report.txt`
- **Individual Results**: `results_*.txt`

## ⚠️ Important Notes

1. **Medical Disclaimer**: This system is for research/educational purposes only
2. **ModelSim Required**: Hardware simulation requires ModelSim installation
3. **File Sizes**: All disease patterns should be 50,176 lines (224×224 pixels)
4. **Backup**: Always backup your original `test_image.mem` before testing

## 🆘 Getting Help

If you encounter issues:

1. Check the file exists: `ls disease_*.mem`
2. Verify file size: `wc -l disease_pneumonia.mem`
3. Check simulation logs: `cat full_system_testbench.log`
4. Review analysis output: `cat medical_diagnosis_report.txt`

---

**Happy Testing! 🏥** 