@echo off
REM Double-click to refresh ForeverXP quest data from Wowhead (needs Python 3 from python.org)
cd /d "%~dp0"
py -3 Tools\fxp_wowhead.py %*
if errorlevel 9009 python Tools\fxp_wowhead.py %*
echo.
pause
