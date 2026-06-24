@echo off
cd /d %~dp0
"C:\Users\c2590\AppData\Local\Programs\nodejs-portable\node-v24.16.0-win-x64\node.exe" "C:\Users\c2590\AppData\Local\Programs\nodejs-portable\npm-global\node_modules\supabase\dist\supabase.js" --version > direct-version3.log 2>&1
echo %ERRORLEVEL% > direct-version3.exit
