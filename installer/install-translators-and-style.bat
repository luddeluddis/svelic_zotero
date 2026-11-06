@echo off
setlocal
rem Use an adjacent PowerShell script when downloaded together; otherwise fetch it.
rem No administrator privileges are needed.
if exist "%~dp0install-translators-and-style.ps1" goto local_installer
set "SVELIC_INSTALLER=%TEMP%\svelic-zotero-%RANDOM%-%RANDOM%.ps1"
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; try { [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -UseBasicParsing -Uri 'https://raw.githubusercontent.com/luddeluddis/svelic_zotero/main/installer/install-translators-and-style.ps1' -OutFile $env:SVELIC_INSTALLER -TimeoutSec 60 } catch { Write-Error $_; exit 1 }"
if errorlevel 1 goto download_failed
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%SVELIC_INSTALLER%" %*
set "SVELIC_EXIT=%ERRORLEVEL%"
del /q "%SVELIC_INSTALLER%" >nul 2>&1
if not "%SVELIC_EXIT%"=="0" echo Installation failed. Review the message above, then try again.
pause
exit /b %SVELIC_EXIT%
:local_installer
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0install-translators-and-style.ps1" %*
set "SVELIC_EXIT=%ERRORLEVEL%"
if not "%SVELIC_EXIT%"=="0" echo Installation failed. Review the message above, then try again.
pause
exit /b %SVELIC_EXIT%
:download_failed
if exist "%SVELIC_INSTALLER%" del /q "%SVELIC_INSTALLER%" >nul 2>&1
echo Could not download the installer. Check your connection and try again.
pause
exit /b 1
