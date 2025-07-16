#!/bin/bash

echo "========================================"
echo "Converting All Disease Images to Memory Files"
echo "========================================"

# Function to convert image with error checking
convert_disease() {
    local input_file="$1"
    local output_file="$2"
    local disease_name="$3"
    
    echo ""
    echo "Converting $disease_name..."
    
    if [ -f "$input_file" ]; then
        python convert_xray.py "$input_file" "$output_file"
        if [ $? -eq 0 ]; then
            echo "✅ Successfully converted $input_file to $output_file"
        else
            echo "❌ Failed to convert $input_file"
        fi
    else
        echo "❌ Image not found: $input_file"
    fi
}

# Convert all disease images
convert_disease "Atelectasis.png" "real_atelectasis_xray.mem" "Atelectasis"
convert_disease "Cardiomegaly.png" "real_cardiomegaly_xray.mem" "Cardiomegaly"
convert_disease "Consolidation.png" "real_consolidation_xray.mem" "Consolidation"
convert_disease "Edema.png" "real_edema_xray.mem" "Edema"
convert_disease "Effusion.png" "real_effusion_xray.mem" "Effusion"
convert_disease "Emphysema.png" "real_emphysema_xray.mem" "Emphysema"
convert_disease "Fibrosis.png" "real_fibrosis_xray.mem" "Fibrosis"
convert_disease "Hernia.png" "real_hernia_xray.mem" "Hernia"
convert_disease "Infiltration.png" "real_infiltration_xray.mem" "Infiltration"
convert_disease "Mass.png" "real_mass_xray.mem" "Mass"
convert_disease "Nodule.png" "real_nodule_xray.mem" "Nodule"
convert_disease "normal.png" "real_normal_xray.mem" "Normal"
convert_disease "Pleural_Thickening.png" "real_pleural_thickening_xray.mem" "Pleural Thickening"
convert_disease "Pneumonia.png" "real_pneumonia_xray.mem" "Pneumonia"
convert_disease "Pneumothorax.png" "real_pneumothorax_xray.mem" "Pneumothorax"

echo ""
echo "========================================"
echo "Conversion Complete!"
echo "========================================"

echo ""
echo "Checking created files..."
ls -la real_*_xray.mem 2>/dev/null || echo "No real disease memory files found"

echo ""
echo "📋 To test a specific disease:"
echo "1. Copy the disease file: cp real_pneumonia_xray.mem test_image.mem"
echo "2. Run simulation: vsim -do run_tb_full_system_top.do"
echo "3. Analyze results: python analyze_disease_hex_outputs.py"

echo ""
echo "📊 Disease Classification Expected Results:"
echo "- Normal: Class 0"
echo "- Infiltration: Class 1"
echo "- Atelectasis: Class 2"
echo "- Effusion: Class 3"
echo "- Nodule: Class 4"
echo "- Pneumothorax: Class 5"
echo "- Mass: Class 6"
echo "- Consolidation: Class 7"
echo "- Pleural Thickening: Class 8"
echo "- Cardiomegaly: Class 9"
echo "- Emphysema: Class 10"
echo "- Fibrosis: Class 11"
echo "- Edema: Class 12"
echo "- Pneumonia: Class 13"
echo "- Hernia: Class 14"
