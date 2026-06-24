@echo off
cd /d %~dp0
"C:\Users\c2590\AppData\Local\Programs\nodejs-portable\node-v24.16.0-win-x64\npm.cmd" exec -- supabase --version > npm-supabase-version.log 2>&1
echo %ERRORLEVEL% > npm-supabase-version.exit
