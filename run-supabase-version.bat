@ECHO OFF
SET "NODE=C:\Users\c2590\AppData\Local\Programs\nodejs-portable\node-v24.16.0-win-x64\node.exe"
SET "CLI=C:\Users\c2590\AppData\Local\Programs\nodejs-portable\npm-global\node_modules\supabase\dist\supabase.js"
"%NODE%" "%CLI%" --version > "%~dp0\supabase-cli-version3.txt" 2>&1
