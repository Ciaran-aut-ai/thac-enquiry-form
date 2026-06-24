@ECHO OFF
cd /d %~dp0
SET "NODE=C:\Users\c2590\AppData\Local\Programs\nodejs-portable\node-v24.16.0-win-x64\node.exe"
SET "CLI=C:\Users\c2590\AppData\Local\Programs\nodejs-portable\npm-global\node_modules\supabase\dist\supabase.js"

if not exist "%CLI%" (
  SET "CLI=C:\Users\c2590\AppData\Local\Programs\nodejs-portable\node-v24.16.0-win-x64\node_modules\supabase\dist\supabase.js"
)

if not exist "%NODE%" (
  echo Error: node.exe not found at "%NODE%"
  exit /b 1
)
if not exist "%CLI%" (
  echo Error: Supabase CLI script not found at "%CLI%"
  exit /b 1
)

"%NODE%" "%CLI%" %*
