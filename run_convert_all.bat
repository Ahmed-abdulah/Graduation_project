@echo off
echo Running Disease Image Converter...
python convert_all_disease_images.py
if errorlevel 1 (
    echo Trying with python3...
    python3 convert_all_disease_images.py
)
if errorlevel 1 (
    echo Trying with py...
    py convert_all_disease_images.py
)
pause
