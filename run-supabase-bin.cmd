@echo off
cd /d %~dp0
"C:\Users\c2590\AppData\Local\Programs\nodejs-portable\npm-global\node_modules\supabase\node_modules\@supabase\cli-windows-x64\bin\supabase.exe" --version > supabase-bin-version.log 2>&1
echo %ERRORLEVEL% > supabase-bin-version.exit
