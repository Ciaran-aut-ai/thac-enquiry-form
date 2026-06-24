@echo off
cd /d %~dp0
if exist "C:\Users\c2590\AppData\Local\Programs\nodejs-portable\node-v24.16.0-win-x64\node.exe" (
  echo NODEFOUND > node-check.log
) else (
  echo NODENOTFOUND > node-check.log
)
if exist "C:\Users\c2590\AppData\Local\Programs\nodejs-portable\npm-global\node_modules\supabase\dist\supabase.js" (
  echo CLIFOUND >> node-check.log
) else (
  echo CLINOTFOUND >> node-check.log
)
"C:\Users\c2590\AppData\Local\Programs\nodejs-portable\node-v24.16.0-win-x64\node.exe" "C:\Users\c2590\AppData\Local\Programs\nodejs-portable\npm-global\node_modules\supabase\dist\supabase.js" --help > direct-check.log 2>&1
echo %ERRORLEVEL% > direct-check.exit
