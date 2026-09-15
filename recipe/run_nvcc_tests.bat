@echo on
setlocal EnableExtensions

set "TEST_PLATFORM="
set "SYSTEM_TYPE="
REM Query the native Windows system type independently of process emulation.
for /f "delims=" %%A in ('powershell -NoProfile -NonInteractive -Command "(Get-CimInstance Win32_ComputerSystem).SystemType"') do set "SYSTEM_TYPE=%%A"
if /I "%SYSTEM_TYPE:~0,3%" == "x64" set "TEST_PLATFORM=win-64"
if /I "%SYSTEM_TYPE:~0,5%" == "ARM64" set "TEST_PLATFORM=win-arm64"

if not defined TEST_PLATFORM (
    echo ERROR: Unsupported Windows system type "%SYSTEM_TYPE%".
    exit /b 1
)

set "CAN_RUN_NVCC="
if /I "%TEST_PLATFORM%" == "%TARGET_PLATFORM%" set "CAN_RUN_NVCC=1"
REM Windows ARM64 can run x64 host tools through Prism.
if /I "%TEST_PLATFORM%" == "win-arm64" (
    if /I "%TARGET_PLATFORM%" == "win-64" (
        set "CAN_RUN_NVCC=1"
    )
)
if not defined CAN_RUN_NVCC (
    echo Skipping NVCC execution tests: host is %TEST_PLATFORM%, target is %TARGET_PLATFORM%.
    exit /b 0
)

nvcc --version
if errorlevel 1 exit /b 1

nvcc --verbose test.cu -o test_nvcc.exe
if errorlevel 1 exit /b 1

if /I "%TARGET_PLATFORM%" == "win-arm64" (
    dumpbin /headers test_nvcc.exe | findstr /I /C:"AA64 machine" >nul
) else (
    dumpbin /headers test_nvcc.exe | findstr /I /C:"8664 machine" >nul
)
if errorlevel 1 (
    echo ERROR: test_nvcc.exe does not match %TARGET_PLATFORM%.
    exit /b 1
)

REM test_nvcc.exe contains device code but does not launch a kernel, so it can
REM run on GPU-less CI hosts.
test_nvcc.exe
if errorlevel 1 exit /b 1

cmake -S . -B .\build -G Ninja
if errorlevel 1 exit /b 1
cmake --build .\build -v
if errorlevel 1 exit /b 1

REM run verify.exe from cmake
.\build\verify.exe
if errorlevel 1 exit /b 1
