@echo off
REM 백엔드 창
start "Backend" cmd /k "cd /d C:\01WorkSpace\BankSalad_SideProject\backend && venv\Scripts\python.exe -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000"

REM 프론트 창
set FRONTEND_DIR=C:\01WorkSpace\BankSalad_SideProject\frontend
start "Frontend" cmd /k "cd /d %FRONTEND_DIR% && flutter emulators --launch Pixel_7 && echo waiting emulator start... && for /l %%i in (1,1,40) do @(flutter devices | findstr emulator-5554 && (echo [completed] emulator started... && flutter run && exit) || timeout /t 3 /nobreak)"