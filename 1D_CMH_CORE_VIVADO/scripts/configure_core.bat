@echo off
setlocal
cd /d "%~dp0.."
set "M=%~1"
if "%M%"=="" set "M=9"
set "PYTHONHOME="
set "PYTHONPATH="
if defined CMH_PYTHON (
    "%CMH_PYTHON%" -E -B scripts\configure_core.py --branches %M%
    exit /b %errorlevel%
)
where py >nul 2>nul
if not errorlevel 1 (
    py -3 -E -B scripts\configure_core.py --branches %M%
    exit /b %errorlevel%
)
where python3 >nul 2>nul
if not errorlevel 1 (
    python3 -E -B scripts\configure_core.py --branches %M%
    exit /b %errorlevel%
)
where python >nul 2>nul
if not errorlevel 1 (
    python -E -B scripts\configure_core.py --branches %M%
    exit /b %errorlevel%
)
echo A working external Python 3 interpreter was not found.
exit /b 1
