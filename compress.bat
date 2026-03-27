@echo off
setlocal EnableExtensions EnableDelayedExpansion
title UPX MAX COMPRESSION

echo ===============================
echo   UPX MAX COMPRESSION START
echo ===============================
echo.

rem Files stored beside this script
set "SCRIPT_DIR=%~dp0"
set "UPX_STORE=%SCRIPT_DIR%upx_path.txt"
set "HISTORY_STORE=%SCRIPT_DIR%packed_history.txt"
set "UPX_PATH="
set "TARGET="

rem -------------------------------
rem Load saved UPX path if present
rem -------------------------------
if exist "%UPX_STORE%" (
    set /p "UPX_PATH="<"%UPX_STORE%"
)

set "UPX_PATH=%UPX_PATH:"=%"

rem Ask for UPX path if missing/invalid
if not exist "%UPX_PATH%" (
    echo No valid saved UPX path found.
    set /p "UPX_PATH=Enter full path to upx.exe: "
    set "UPX_PATH=!UPX_PATH:"=!"

    if not exist "!UPX_PATH!" (
        echo.
        echo [ERROR] UPX not found:
        echo !UPX_PATH!
        pause
        exit /b 1
    )

    >"%UPX_STORE%" echo !UPX_PATH!
    echo [INFO] Saved UPX path for future use.
)

echo [INFO] Using UPX path: %UPX_PATH%
echo.

rem -------------------------------
rem Choose EXE from history or new
rem -------------------------------
set /a COUNT=0
set /a VISIBLE_COUNT=0

if exist "%HISTORY_STORE%" (
    for /f "usebackq delims=" %%H in ("%HISTORY_STORE%") do (
        set /a COUNT+=1
        set "HIST[!COUNT!]=%%H"
    )

    if !COUNT! GTR 0 (
        set /a START=1
        if !COUNT! GTR 5 set /a START=COUNT-4

        echo Previously packed EXEs:
        echo.
        for /l %%I in (!START!,1,!COUNT!) do (
            set /a VISIBLE_COUNT+=1
            set "VISIBLE[!VISIBLE_COUNT!]=!HIST[%%I]!"
            echo   !VISIBLE_COUNT!^) !HIST[%%I]!
        )
        echo.
    )
)

if %VISIBLE_COUNT% GTR 0 (
    echo N^) Enter a new EXE path
    echo.
    set /p "CHOICE=Select a number from history or press N for new: "
    set "CHOICE=!CHOICE:"=!"

    if /i "!CHOICE!"=="N" goto :ASK_NEW
    if not defined CHOICE goto :ASK_NEW

    set "NONNUM="
    for /f "delims=0123456789" %%X in ("!CHOICE!") do set "NONNUM=%%X"
    if defined NONNUM (
        echo.
        echo [ERROR] Invalid selection.
        pause
        exit /b 1
    )

    set "TARGET="
    for %%I in (!CHOICE!) do if defined VISIBLE[%%I] set "TARGET=!VISIBLE[%%I]!"
    if defined TARGET (
        goto :TARGET_CHOSEN
    ) else (
        echo.
        echo [ERROR] Invalid history number.
        pause
        exit /b 1
    )
)

:ASK_NEW
set /p "TARGET=Enter full path to the EXE you want compressed: "
set "TARGET=%TARGET:"=%"

:TARGET_CHOSEN
if not exist "%TARGET%" (
    echo.
    echo [ERROR] Target EXE not found:
    echo %TARGET%
    pause
    exit /b 1
)

rem -------------------------------
rem Save target to history if new
rem -------------------------------
call :ADD_TO_HISTORY "%TARGET%"

rem Break target into parts
for %%F in ("%TARGET%") do (
    set "TARGET_DIR=%%~dpF"
    set "TARGET_NAME=%%~nF"
    set "TARGET_EXT=%%~xF"
)

set "UNCOMPRESSED=%TARGET_DIR%%TARGET_NAME%-uncompressed%TARGET_EXT%"

echo.
echo [INFO] UPX path: %UPX_PATH%
echo [INFO] Target EXE: %TARGET%
echo [INFO] Backup EXE: %UNCOMPRESSED%

echo.
echo [1] Removing old uncompressed backup if it exists...
if exist "%UNCOMPRESSED%" del /f /q "%UNCOMPRESSED%"
if exist "%UNCOMPRESSED%" (
    echo [ERROR] Could not remove old backup!
    pause
    exit /b 1
)

echo.
echo [2] Renaming original EXE to backup...
ren "%TARGET%" "%TARGET_NAME%-uncompressed%TARGET_EXT%"
if errorlevel 1 (
    echo [ERROR] Rename failed!
    pause
    exit /b 1
)

if not exist "%UNCOMPRESSED%" (
    echo [ERROR] Backup file was not created!
    pause
    exit /b 1
)

echo.
echo [3] Copying backup back to original filename for compression...
copy "%UNCOMPRESSED%" "%TARGET%" >nul
if errorlevel 1 (
    echo [ERROR] Copy failed!
    pause
    exit /b 1
)

if not exist "%TARGET%" (
    echo [ERROR] Restored target file was not created!
    pause
    exit /b 1
)

echo.
echo [4] Running UPX compression ^(output stays original EXE name^)...
"%UPX_PATH%" ^
--best ^
--lzma ^
--ultra-brute ^
--compress-exports=1 ^
--strip-relocs=1 ^
--overlay=copy ^
--force ^
"%TARGET%"

if errorlevel 1 (
    echo [ERROR] UPX compression failed!
    pause
    exit /b 1
)

echo.
echo ===============================
echo   COMPRESSION COMPLETE
echo ===============================

for %%A in ("%UNCOMPRESSED%") do set "ORIG=%%~zA"
for %%A in ("%TARGET%") do set "NEW=%%~zA"

echo Original ^(uncompressed^): %ORIG% bytes
echo Compressed ^(%TARGET_NAME%%TARGET_EXT%^): %NEW% bytes

echo.
echo Done!
pause
exit /b 0

rem =====================================================
rem Adds target to history only if it is not already there
rem =====================================================
:ADD_TO_HISTORY
set "NEW_TARGET=%~1"
set /a HIST_COUNT=0

if exist "%HISTORY_STORE%" (
    for /f "usebackq delims=" %%H in ("%HISTORY_STORE%") do (
        if /i not "%%H"=="%NEW_TARGET%" (
            set /a HIST_COUNT+=1
            set "KEEP[!HIST_COUNT!]=%%H"
        )
    )
)

set /a START=1
if %HIST_COUNT% GTR 4 set /a START=HIST_COUNT-3

>"%HISTORY_STORE%" (
    for /l %%I in (%START%,1,%HIST_COUNT%) do echo !KEEP[%%I]!
    echo %NEW_TARGET%
)

exit /b
