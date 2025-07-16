@echo off
echo Setting up network drives for TrueNAS connection...

echo Clearing existing network connections...
net use * /delete /yes

echo Adding stored credentials for TrueNAS server...
cmdkey /add:"192.168.86.109" /user:"bill" /pass:"I4V69b^WOR!@8OxVD4mE"

echo Waiting for credentials to be stored...
timeout /t 2 /nobreak >nul

echo Mapping network drives...
net use H: "\\192.168.86.109\Documents" /persistent:yes
if %errorlevel% equ 0 (echo ✅ H: drive mapped successfully) else (echo ❌ H: drive mapping failed)

net use I: "\\192.168.86.109\Downloads" /persistent:yes  
if %errorlevel% equ 0 (echo ✅ I: drive mapped successfully) else (echo ❌ I: drive mapping failed)

net use M: "\\192.168.86.109\media" /persistent:yes
if %errorlevel% equ 0 (echo ✅ M: drive mapped successfully) else (echo ❌ M: drive mapping failed)

net use P: "\\192.168.86.109\paper" /persistent:yes
if %errorlevel% equ 0 (echo ✅ P: drive mapped successfully) else (echo ❌ P: drive mapping failed)

net use S: "\\192.168.86.109\shared_files" /persistent:yes
if %errorlevel% equ 0 (echo ✅ S: drive mapped successfully) else (echo ❌ S: drive mapping failed)

net use W: "\\192.168.86.109\workouts" /persistent:yes
if %errorlevel% equ 0 (echo ✅ W: drive mapped successfully) else (echo ❌ W: drive mapping failed)

echo.
echo Network drive setup complete!
echo Checking final status...
net use

echo.
echo If drives show as 'Unavailable', try:
echo 1. Open File Explorer
echo 2. Click on each drive to authenticate  
echo 3. Use username: bill
echo 4. Use password: I4V69b^WOR!@8OxVD4mE
echo 5. Check 'Remember my credentials'

pause
