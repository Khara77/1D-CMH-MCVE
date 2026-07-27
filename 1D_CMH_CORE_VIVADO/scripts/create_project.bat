@echo off
setlocal
cd /d "%~dp0.."
set "M=%~1"
if "%M%"=="" set "M=9"
vivado -mode batch -source scripts/create_project.tcl -tclargs %M%
exit /b %errorlevel%
