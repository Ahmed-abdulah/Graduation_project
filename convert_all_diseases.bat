@echo off
echo ========================================
echo Converting All Disease Images to Memory Files
echo ========================================

echo.
echo Converting Atelectasis...
python convert_xray.py Atelectasis.png real_atelectasis_xray.mem

echo.
echo Converting Cardiomegaly...
python convert_xray.py Cardiomegaly.png real_cardiomegaly_xray.mem

echo.
echo Converting Consolidation...
python convert_xray.py Consolidation.png real_consolidation_xray.mem

echo.
echo Converting Edema...
python convert_xray.py Edema.png real_edema_xray.mem

echo.
echo Converting Effusion...
python convert_xray.py Effusion.png real_effusion_xray.mem

echo.
echo Converting Emphysema...
python convert_xray.py Emphysema.png real_emphysema_xray.mem

echo.
echo Converting Fibrosis...
python convert_xray.py Fibrosis.png real_fibrosis_xray.mem

echo.
echo Converting Hernia...
python convert_xray.py Hernia.png real_hernia_xray.mem

echo.
echo Converting Infiltration...
python convert_xray.py Infiltration.png real_infiltration_xray.mem

echo.
echo Converting Mass...
python convert_xray.py Mass.png real_mass_xray.mem

echo.
echo Converting Nodule...
python convert_xray.py Nodule.png real_nodule_xray.mem

echo.
echo Converting Normal...
python convert_xray.py normal.png real_normal_xray.mem

echo.
echo Converting Pleural Thickening...
python convert_xray.py "Pleural_Thickening.png" real_pleural_thickening_xray.mem

echo.
echo Converting Pneumonia...
python convert_xray.py Pneumonia.png real_pneumonia_xray.mem

echo.
echo Converting Pneumothorax...
python convert_xray.py Pneumothorax.png real_pneumothorax_xray.mem

echo.
echo ========================================
echo Conversion Complete!
echo ========================================
echo.
echo Checking created files...
dir real_*_xray.mem

echo.
echo To test a specific disease:
echo 1. Copy the disease file: copy real_pneumonia_xray.mem test_image.mem
echo 2. Run simulation: vsim -do run_tb_full_system_top.do
echo 3. Analyze results: python analyze_disease_hex_outputs.py

pause
