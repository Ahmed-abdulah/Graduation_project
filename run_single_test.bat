@echo off
echo 🏥 SINGLE TEST MEDICAL AI SYSTEM
echo ================================
echo.

echo 📋 This script runs a single X-ray test through your MobileNetV3 neural network
echo.

echo 🔍 Checking for test image...
if exist "test_image.mem" (
    echo ✅ test_image.mem found
) else (
    echo ⚠️ test_image.mem not found - will create default pattern
)

echo.
echo 🚀 Starting ModelSim simulation...
echo.

cd FULL_TOP
vsim -c -do "do run_single_test.do; quit -f"
cd ..

echo.
echo ✅ Single test complete!
echo.
echo 📊 Check the ModelSim output above for:
echo   - Classification results for 15 diseases
echo   - Primary diagnosis and confidence
echo   - Medical recommendation
echo   - Performance metrics
echo.
pause
