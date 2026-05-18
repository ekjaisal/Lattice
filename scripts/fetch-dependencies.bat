@echo off
setlocal enabledelayedexpansion

set "MSYS2_PATH=C:\msys64"
set "BIN_DIR=%~dp0..\bin"
set "NTLDD_EXE=%MSYS2_PATH%\mingw64\bin\ntldd.exe"

if not exist "%MSYS2_PATH%" (
    echo MSYS2 not found at %MSYS2_PATH%. Please install MSYS2.
    exit /b 1
)

if not exist "%BIN_DIR%" mkdir "%BIN_DIR%"

echo Fetching dependencies from MSYS2...
set "LIBS=libpango-1.0-0.dll libpangocairo-1.0-0.dll libcairo-2.dll libsqlite3-0.dll"
for %%L in (%LIBS%) do (
    if exist "%MSYS2_PATH%\mingw64\bin\%%L" (
        echo Copying %%L and its dependencies...
        copy /y "%MSYS2_PATH%\mingw64\bin\%%L" "%BIN_DIR%" >nul
        
        "%NTLDD_EXE%" -R "%MSYS2_PATH%\mingw64\bin\%%L" > "%TEMP%\lattice_deps.txt" 2>nul
        
        for /f "tokens=3" %%D in ('findstr /i "mingw64" "%TEMP%\lattice_deps.txt"') do (
            if not exist "%BIN_DIR%\%%~nxD" (
                copy /y "%%D" "%BIN_DIR%" >nul
            )
        )
    ) else (
        echo Warning: %%L not found in MSYS2.
    )
)
if exist "%TEMP%\lattice_deps.txt" del "%TEMP%\lattice_deps.txt"

if exist "%BIN_DIR%\libsqlite3-0.dll" (
    echo Renaming libsqlite3-0.dll to sqlite3.dll...
    move /y "%BIN_DIR%\libsqlite3-0.dll" "%BIN_DIR%\sqlite3.dll" >nul
)

echo Fetching PDFium (x64, No V8)...
curl -L -o pdfium.tgz "https://github.com/bblanchon/pdfium-binaries/releases/latest/download/pdfium-win-x64.tgz"

tar -xf pdfium.tgz bin/pdfium.dll
move /y bin\pdfium.dll "%BIN_DIR%\pdfium.dll" >nul
rmdir /s /q bin
del pdfium.tgz

echo Dependency fetch complete.
pause