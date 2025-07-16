# Manual Disease Image Conversion Guide

## Overview
This guide helps you convert all your real X-ray disease images to memory files for neural network testing.

## Available Disease Images
Based on your directory, you have these real X-ray images:

1. **Atelectasis.png** → should create `real_atelectasis_xray.mem`
2. **Cardiomegaly.png** → should create `real_cardiomegaly_xray.mem`
3. **Consolidation.png** → should create `real_consolidation_xray.mem`
4. **Edema.png** → should create `real_edema_xray.mem`
5. **Effusion.png** → should create `real_effusion_xray.mem`
6. **Emphysema.png** → should create `real_emphysema_xray.mem`
7. **Fibrosis.png** → should create `real_fibrosis_xray.mem`
8. **Hernia.png** → should create `real_hernia_xray.mem`
9. **Infiltration.png** → should create `real_infiltration_xray.mem`
10. **Mass.png** → should create `real_mass_xray.mem`
11. **Nodule.png** → should create `real_nodule_xray.mem`
12. **normal.png** → should create `real_normal_xray.mem`
13. **Pleural_Thickening.png** → should create `real_pleural_thickening_xray.mem`
14. **Pneumonia.png** → should create `real_pneumonia_xray.mem` ✅ (Already exists)
15. **Pneumothorax.png** → should create `real_pneumothorax_xray.mem`

## Method 1: Using the Existing convert_xray.py Script

### Step-by-Step Process:

For each disease image, follow these steps:

#### 1. Convert Atelectasis.png
```bash
# Edit convert_xray.py to change the input/output filenames
# Change line 70: input_image = "Atelectasis.png"
# Change line 71: output_mem = "real_atelectasis_xray.mem"
# Then run: python convert_xray.py
```

#### 2. Convert Cardiomegaly.png
```bash
# Edit convert_xray.py to change the input/output filenames
# Change line 70: input_image = "Cardiomegaly.png"
# Change line 71: output_mem = "real_cardiomegaly_xray.mem"
# Then run: python convert_xray.py
```

#### 3. Continue for all other diseases...

## Method 2: Batch Conversion Commands

Here are the exact commands to convert each image:

### Windows Command Prompt Commands:
```cmd
REM Copy and modify convert_xray.py for each disease
copy convert_xray.py convert_atelectasis.py
REM Edit convert_atelectasis.py to use "Atelectasis.png" and "real_atelectasis_xray.mem"
python convert_atelectasis.py

copy convert_xray.py convert_cardiomegaly.py
REM Edit convert_cardiomegaly.py to use "Cardiomegaly.png" and "real_cardiomegaly_xray.mem"
python convert_cardiomegaly.py

REM Continue for all diseases...
```

## Method 3: Quick Verification

### Check what you currently have:
```bash
ls -la *.png | grep -E "(Atelectasis|Cardiomegaly|Consolidation|Edema|Effusion|Emphysema|Fibrosis|Hernia|Infiltration|Mass|Nodule|normal|Pleural|Pneumonia|Pneumothorax)"
```

### Check what memory files exist:
```bash
ls -la *real*.mem
ls -la disease_*.mem
```

## Expected Output Files

After conversion, you should have these memory files:
- real_atelectasis_xray.mem (50,176 lines, ~301KB)
- real_cardiomegaly_xray.mem (50,176 lines, ~301KB)
- real_consolidation_xray.mem (50,176 lines, ~301KB)
- real_edema_xray.mem (50,176 lines, ~301KB)
- real_effusion_xray.mem (50,176 lines, ~301KB)
- real_emphysema_xray.mem (50,176 lines, ~301KB)
- real_fibrosis_xray.mem (50,176 lines, ~301KB)
- real_hernia_xray.mem (50,176 lines, ~301KB)
- real_infiltration_xray.mem (50,176 lines, ~301KB)
- real_mass_xray.mem (50,176 lines, ~301KB)
- real_nodule_xray.mem (50,176 lines, ~301KB)
- real_normal_xray.mem (50,176 lines, ~301KB)
- real_pleural_thickening_xray.mem (50,176 lines, ~301KB)
- real_pneumonia_xray.mem (50,176 lines, ~301KB) ✅ Already exists
- real_pneumothorax_xray.mem (50,176 lines, ~301KB)

## Testing Each Disease

After creating the memory files, test each one:

```bash
# Copy the disease memory file to test_image.mem
cp real_atelectasis_xray.mem test_image.mem

# Run the simulation
vsim -do run_tb_full_system_top.do

# Analyze results
python analyze_disease_hex_outputs.py
```

## Disease Classification Mapping

The neural network should classify these diseases with these expected class indices:
- No Finding (normal.png): Class 0
- Infiltration: Class 1  
- Atelectasis: Class 2
- Effusion: Class 3
- Nodule: Class 4
- Pneumothorax: Class 5
- Mass: Class 6
- Consolidation: Class 7
- Pleural_Thickening: Class 8
- Cardiomegaly: Class 9
- Emphysema: Class 10
- Fibrosis: Class 11
- Edema: Class 12
- Pneumonia: Class 13
- Hernia: Class 14

## Next Steps

1. Convert all disease images to memory files
2. Test each disease systematically
3. Verify the neural network produces different outputs for different diseases
4. Document which diseases are correctly classified
5. Identify any diseases that need model retraining
