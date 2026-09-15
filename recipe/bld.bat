@echo on
setlocal EnableExtensions

REM our feedstock has four sources: nvcc, crt, nvvm, libnvptxcompiler

set "TARGET_NAME="
if /I "%TARGET_PLATFORM%" == "win-64" set "TARGET_NAME=x64"
if /I "%TARGET_PLATFORM%" == "win-arm64" set "TARGET_NAME=arm64"
if not defined TARGET_NAME (
    echo ERROR: Unsupported Windows target platform "%TARGET_PLATFORM%".
    exit /b 1
)

if not exist "%PREFIX%" mkdir "%PREFIX%"
if errorlevel 1 exit /b 1
if not exist "%LIBRARY_BIN%" mkdir "%LIBRARY_BIN%"
if errorlevel 1 exit /b 1
if not exist "%LIBRARY_INC%" mkdir "%LIBRARY_INC%"
if errorlevel 1 exit /b 1
if not exist "%LIBRARY_LIB%\%TARGET_NAME%" mkdir "%LIBRARY_LIB%\%TARGET_NAME%"
if errorlevel 1 exit /b 1

if not exist "nvcc\bin\nvcc.exe" (
    echo ERROR: Missing NVCC executables.
    exit /b 1
)
if not exist "nvcc\bin\crt\link.stub" (
    echo ERROR: Missing NVCC CRT stubs.
    exit /b 1
)
move /Y "nvcc\bin\crt" "%LIBRARY_BIN%\"
if errorlevel 1 exit /b 1
move /Y "nvcc\bin\*" "%LIBRARY_BIN%\"
if errorlevel 1 exit /b 1

if not exist "nvcc\include\fatbinary_section.h" (
    echo ERROR: Missing NVCC headers.
    exit /b 1
)
move /Y "nvcc\include\*" "%LIBRARY_INC%\"
if errorlevel 1 exit /b 1

if not exist "crt\include\crt\common_functions.h" (
    echo ERROR: Missing CUDA CRT headers.
    exit /b 1
)
move /Y "crt\include\crt" "%LIBRARY_INC%\"
if errorlevel 1 exit /b 1

if not exist "nvvm\nvvm\bin\cicc.exe" (
    echo ERROR: Missing NVVM tools.
    exit /b 1
)
if not exist "nvvm\nvvm\lib\%TARGET_NAME%\nvvm.lib" (
    echo ERROR: Missing NVVM import library for %TARGET_NAME%.
    exit /b 1
)
move /Y "nvvm\nvvm" "%LIBRARY_PREFIX%\"
if errorlevel 1 exit /b 1

if not exist "libnvptxcompiler\lib\%TARGET_NAME%\nvptxcompiler_static.lib" (
    echo ERROR: Missing NVPTX compiler library for %TARGET_NAME%.
    exit /b 1
)
move /Y "libnvptxcompiler\lib\%TARGET_NAME%\*" "%LIBRARY_LIB%\%TARGET_NAME%\"
if errorlevel 1 exit /b 1

if not exist "libnvptxcompiler\include\nvPTXCompiler.h" (
    echo ERROR: Missing NVPTX compiler headers.
    exit /b 1
)
move /Y "libnvptxcompiler\include\*" "%LIBRARY_INC%\"
if errorlevel 1 exit /b 1
