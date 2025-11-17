@echo on

nvcc --version
if errorlevel 1 exit 1

nvcc --verbose test.cu
if errorlevel 1 exit 1

REM run a.exe from test.cu
a.exe
if %ERRORLEVEL% neq 0 exit %ERRORLEVEL%

cmake -S . -B ./build -G=Ninja && cmake --build ./build -v
if errorlevel 1 exit 1

REM run verify.exe from cmake
.\build\verify.exe
if %ERRORLEVEL% neq 0 exit %ERRORLEVEL%
