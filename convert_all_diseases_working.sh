#!/bin/bash

echo "========================================"
echo "Converting ALL Disease Images to Memory Files"
echo "========================================"

PYTHON_PATH="C:/Users/lenovo/AppData/Local/Programs/Python/Python311/python.exe"
SCRIPT_PATH="c:/Users/lenovo/Downloads/FULL_SYSTEM/convert_xray.py"

echo "Using Python: $PYTHON_PATH"
echo "Using Script: $SCRIPT_PATH"
echo ""

# Function to convert with progress tracking
convert_disease() {
    local input_file="$1"
    local output_file="$2"
    local disease_name="$3"
    local progress="$4"
    
    echo "[$progress] Converting $disease_name..."
    
    if [ -f "$input_file" ]; then
        "$PYTHON_PATH" "$SCRIPT_PATH" "$input_file" "$output_file"
        if [ $? -eq 0 ]; then
            echo "✅ Successfully converted $input_file"
        else
            echo "❌ Failed to convert $input_file"
        fi
    else
        echo "❌ Image not found: $input_file"
    fi
    echo ""
}

# Convert all disease images with progress tracking
convert_disease "Atelectasis.png" "real_atelectasis_xray.mem" "Atelectasis" "1/15"
convert_disease "Cardiomegaly.png" "real_cardiomegaly_xray.mem" "Cardiomegaly" "2/15"
convert_disease "Consolidation.png" "real_consolidation_xray.mem" "Consolidation" "3/15"
convert_disease "Edema.png" "real_edema_xray.mem" "Edema" "4/15"
convert_disease "Effusion.png" "real_effusion_xray.mem" "Effusion" "5/15"
convert_disease "Emphysema.png" "real_emphysema_xray.mem" "Emphysema" "6/15"
convert_disease "Fibrosis.png" "real_fibrosis_xray.mem" "Fibrosis" "7/15"
convert_disease "Hernia.png" "real_hernia_xray.mem" "Hernia" "8/15"
convert_disease "Infiltration.png" "real_infiltration_xray.mem" "Infiltration" "9/15"
convert_disease "Mass.png" "real_mass_xray.mem" "Mass" "10/15"
convert_disease "Nodule.png" "real_nodule_xray.mem" "Nodule" "11/15"
convert_disease "normal.png" "real_normal_xray.mem" "Normal" "12/15"
convert_disease "Pleural_Thickening.png" "real_pleural_thickening_xray.mem" "Pleural Thickening" "13/15"
convert_disease "Pneumonia.png" "real_pneumonia_xray.mem" "Pneumonia" "14/15"
convert_disease "Pneumothorax.png" "real_pneumothorax_xray.mem" "Pneumothorax" "15/15"

echo "========================================"
echo "CONVERSION COMPLETE!"
echo "========================================"

echo ""
echo "Checking created files..."
ls -la real_*_xray.mem 2>/dev/null | wc -l | xargs echo "Total memory files created:"
ls -la real_*_xray.mem 2>/dev/null || echo "No files found"

echo ""
echo "========================================"
echo "SUMMARY: Expected Disease Classifications"
echo "========================================"
echo "Class 0  - Normal (No Finding)"
echo "Class 1  - Infiltration"
echo "Class 2  - Atelectasis"
echo "Class 3  - Effusion"
echo "Class 4  - Nodule"
echo "Class 5  - Pneumothorax"
echo "Class 6  - Mass"
echo "Class 7  - Consolidation"
echo "Class 8  - Pleural Thickening"
echo "Class 9  - Cardiomegaly"
echo "Class 10 - Emphysema"
echo "Class 11 - Fibrosis"
echo "Class 12 - Edema"
echo "Class 13 - Pneumonia"
echo "Class 14 - Hernia"

echo ""
echo "========================================"
echo "NEXT STEPS:"
echo "========================================"
echo "1. Test each disease:"
echo "   cp real_hernia_xray.mem test_image.mem"
echo "   vsim -do run_tb_full_system_top.do"
echo "   \"$PYTHON_PATH\" analyze_disease_hex_outputs.py"
echo ""
echo "2. Run systematic testing:"
echo "   \"$PYTHON_PATH\" test_all_diseases.py"
echo ""
