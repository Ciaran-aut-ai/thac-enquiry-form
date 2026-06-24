@echo off
cd /d %~dp0
"C:\Users\c2590\AppData\Local\Programs\nodejs-portable\node-v24.16.0-win-x64\node.exe" -e "console.log('NODE_OK')" > node-test2.log 2>&1
echo %ERRORLEVEL% > node-test2.exit
