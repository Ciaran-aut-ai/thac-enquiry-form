@echo off
cd /d %~dp0
set "CLIROOT=C:\Users\c2590\AppData\Local\Programs\nodejs-portable\node-v24.16.0-win-x64"
set "NODE=%CLIROOT%\node.exe"
set "SCRIPT=%CLIROOT%\node_modules\supabase\dist\supabase.js"

if not exist "%NODE%" (
  echo Error: node.exe not found at "%NODE%"
  exit /b 1
)
if not exist "%SCRIPT%" (
  echo Error: Supabase CLI script not found at "%SCRIPT%"
  exit /b 1
)
"%NODE%" "%SCRIPT%" %*
