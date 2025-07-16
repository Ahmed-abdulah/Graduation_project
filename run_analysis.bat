@echo off
echo 🏥 EMERGENCY MEDICAL AI RESULTS ANALYZER
echo ========================================
echo.

echo 📦 Installing required Python packages...
echo Installing matplotlib and numpy for full visualization support...
pip install matplotlib numpy

echo.
echo 🚀 Running analysis...
python analyze_emergency_results.py

echo.
echo ✅ Analysis complete! Check the generated files:
echo   📄 emergency_medical_ai_report.txt
echo   📊 emergency_medical_ai_analysis.png (if matplotlib available)
echo.
pause
