@echo off
echo ========================================
echo Converting ALL Disease Images to Memory Files
echo ========================================

set PYTHON_PATH=C:/Users/lenovo/AppData/Local/Programs/Python/Python311/python.exe
set SCRIPT_PATH=c:/Users/lenovo/Downloads/FULL_SYSTEM/convert_xray.py

echo Using Python: %PYTHON_PATH%
echo Using Script: %SCRIPT_PATH%
echo.

echo [1/15] Converting Atelectasis...
%PYTHON_PATH% %SCRIPT_PATH% Atelectasis.png real_atelectasis_xray.mem

echo.
echo [2/15] Converting Cardiomegaly...
%PYTHON_PATH% %SCRIPT_PATH% Cardiomegaly.png real_cardiomegaly_xray.mem

echo.
echo [3/15] Converting Consolidation...
%PYTHON_PATH% %SCRIPT_PATH% Consolidation.png real_consolidation_xray.mem

echo.
echo [4/15] Converting Edema...
%PYTHON_PATH% %SCRIPT_PATH% Edema.png real_edema_xray.mem

echo.
echo [5/15] Converting Effusion...
%PYTHON_PATH% %SCRIPT_PATH% Effusion.png real_effusion_xray.mem

echo.
echo [6/15] Converting Emphysema...
%PYTHON_PATH% %SCRIPT_PATH% Emphysema.png real_emphysema_xray.mem

echo.
echo [7/15] Converting Fibrosis...
%PYTHON_PATH% %SCRIPT_PATH% Fibrosis.png real_fibrosis_xray.mem

echo.
echo [8/15] Converting Hernia...
%PYTHON_PATH% %SCRIPT_PATH% Hernia.png real_hernia_xray.mem

echo.
echo [9/15] Converting Infiltration...
%PYTHON_PATH% %SCRIPT_PATH% Infiltration.png real_infiltration_xray.mem

echo.
echo [10/15] Converting Mass...
%PYTHON_PATH% %SCRIPT_PATH% Mass.png real_mass_xray.mem

echo.
echo [11/15] Converting Nodule...
%PYTHON_PATH% %SCRIPT_PATH% Nodule.png real_nodule_xray.mem

echo.
echo [12/15] Converting Normal...
%PYTHON_PATH% %SCRIPT_PATH% normal.png real_normal_xray.mem

echo.
echo [13/15] Converting Pleural Thickening...
%PYTHON_PATH% %SCRIPT_PATH% "Pleural_Thickening.png" real_pleural_thickening_xray.mem

echo.
echo [14/15] Converting Pneumonia...
%PYTHON_PATH% %SCRIPT_PATH% Pneumonia.png real_pneumonia_xray.mem

echo.
echo [15/15] Converting Pneumothorax...
%PYTHON_PATH% %SCRIPT_PATH% Pneumothorax.png real_pneumothorax_xray.mem

echo.
echo ========================================
echo CONVERSION COMPLETE!
echo ========================================

echo.
echo Checking created files...
dir real_*_xray.mem

echo.
echo ========================================
echo SUMMARY: Expected Disease Classifications
echo ========================================
echo Class 0  - Normal (No Finding)
echo Class 1  - Infiltration
echo Class 2  - Atelectasis
echo Class 3  - Effusion
echo Class 4  - Nodule
echo Class 5  - Pneumothorax
echo Class 6  - Mass
echo Class 7  - Consolidation
echo Class 8  - Pleural Thickening
echo Class 9  - Cardiomegaly
echo Class 10 - Emphysema
echo Class 11 - Fibrosis
echo Class 12 - Edema
echo Class 13 - Pneumonia
echo Class 14 - Hernia

echo.
echo ========================================
echo NEXT STEPS:
echo ========================================
echo 1. Test each disease:
echo    copy real_hernia_xray.mem test_image.mem
echo    vsim -do run_tb_full_system_top.do
echo    %PYTHON_PATH% analyze_disease_hex_outputs.py
echo.
echo 2. Run systematic testing:
echo    %PYTHON_PATH% test_all_diseases.py
echo.

pause
