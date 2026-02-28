@echo off
setlocal enabledelayedexpansion

:: Set your project path here
set "PROJECT_PATH=C:\Users\hoffe\GameMakerProjects\Caravan"
set "OUTPUT_FILE=%PROJECT_PATH%\project_snapshot.txt"

echo GameMaker Project Snapshot > "%OUTPUT_FILE%"
echo Generated: %date% %time% >> "%OUTPUT_FILE%"
echo ================================================ >> "%OUTPUT_FILE%"
echo. >> "%OUTPUT_FILE%"

:: This section holds metadata for LLM Review
echo. >> "%OUTPUT_FILE%"
echo [SNAPSHOT METADATA] >> "%OUTPUT_FILE%"
echo =================== >> "%OUTPUT_FILE%"
echo Snapshot Date: %date% %time% >> "%OUTPUT_FILE%"
echo Project Path: %PROJECT_PATH% >> "%OUTPUT_FILE%"
echo Total Files Captured: [manually count or add counter] >> "%OUTPUT_FILE%"
echo. >> "%OUTPUT_FILE%"

:: Collect .yyp project file
echo [PROJECT CONFIGURATION] >> "%OUTPUT_FILE%"
echo ======================== >> "%OUTPUT_FILE%"
if exist "%PROJECT_PATH%\*.yyp" (
    for %%f in ("%PROJECT_PATH%\*.yyp") do (
        echo File: %%~nxf >> "%OUTPUT_FILE%"
        type "%%f" >> "%OUTPUT_FILE%"
        echo. >> "%OUTPUT_FILE%"
    )
)

:: Collect all objects
echo. >> "%OUTPUT_FILE%"
echo [OBJECTS] >> "%OUTPUT_FILE%"
echo ========= >> "%OUTPUT_FILE%"
if exist "%PROJECT_PATH%\objects" (
    for /r "%PROJECT_PATH%\objects" %%f in (*.yy) do (
        echo. >> "%OUTPUT_FILE%"
        echo --- Object: %%~nxf --- >> "%OUTPUT_FILE%"
        type "%%f" >> "%OUTPUT_FILE%"
        echo. >> "%OUTPUT_FILE%"
    )
    for /r "%PROJECT_PATH%\objects" %%f in (*.gml) do (
        echo. >> "%OUTPUT_FILE%"
        echo --- Event Code: %%~nxf --- >> "%OUTPUT_FILE%"
        type "%%f" >> "%OUTPUT_FILE%"
        echo. >> "%OUTPUT_FILE%"
    )
)

:: Collect all scripts
echo. >> "%OUTPUT_FILE%"
echo [SCRIPTS] >> "%OUTPUT_FILE%"
echo ========= >> "%OUTPUT_FILE%"
if exist "%PROJECT_PATH%\scripts" (
    for /r "%PROJECT_PATH%\scripts" %%f in (*.gml) do (
        echo. >> "%OUTPUT_FILE%"
        echo --- Script: %%~nxf --- >> "%OUTPUT_FILE%"
        type "%%f" >> "%OUTPUT_FILE%"
        echo. >> "%OUTPUT_FILE%"
    )
    for /r "%PROJECT_PATH%\scripts" %%f in (*.yy) do (
        echo. >> "%OUTPUT_FILE%"
        echo --- Script Definition: %%~nxf --- >> "%OUTPUT_FILE%"
        type "%%f" >> "%OUTPUT_FILE%"
        echo. >> "%OUTPUT_FILE%"
    )
)

:: Collect rooms
echo. >> "%OUTPUT_FILE%"
echo [ROOMS] >> "%OUTPUT_FILE%"
echo ======= >> "%OUTPUT_FILE%"
if exist "%PROJECT_PATH%\rooms" (
    for /r "%PROJECT_PATH%\rooms" %%f in (*.yy) do (
        echo. >> "%OUTPUT_FILE%"
        echo --- Room: %%~nxf --- >> "%OUTPUT_FILE%"
        type "%%f" >> "%OUTPUT_FILE%"
        echo. >> "%OUTPUT_FILE%"
    )
)

:: Collect notes
echo. >> "%OUTPUT_FILE%"
echo [NOTES] >> "%OUTPUT_FILE%"
echo ======= >> "%OUTPUT_FILE%"
if exist "%PROJECT_PATH%\notes" (
    for /r "%PROJECT_PATH%\notes" %%f in (*.txt *.yy) do (
        echo. >> "%OUTPUT_FILE%"
        echo --- Note: %%~nxf --- >> "%OUTPUT_FILE%"
        type "%%f" >> "%OUTPUT_FILE%"
        echo. >> "%OUTPUT_FILE%"
    )
)


:: Collect design doc
echo. >> "%OUTPUT_FILE%"
echo [DESIGN DOCUMENTATION] >> "%OUTPUT_FILE%"
echo ====================== >> "%OUTPUT_FILE%"
if exist "%PROJECT_PATH%\DESIGN.md" (
    type "%PROJECT_PATH%\DESIGN.md" >> "%OUTPUT_FILE%"
    echo. >> "%OUTPUT_FILE%"
)


echo. >> "%OUTPUT_FILE%"
echo ================================================ >> "%OUTPUT_FILE%"
echo Snapshot complete! >> "%OUTPUT_FILE%"

echo.
echo Project snapshot created at: %OUTPUT_FILE%
echo.
pause