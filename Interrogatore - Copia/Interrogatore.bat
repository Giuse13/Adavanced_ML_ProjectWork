@echo off
cd /d "%~dp0"
python source\RuotaDellaFortunaWeb.py
if errorlevel 1 pause
