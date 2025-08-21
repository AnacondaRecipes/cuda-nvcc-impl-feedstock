@echo on

nvcc --version
if errorlevel 1 exit 1

nvcc --verbose test.cu
if errorlevel 1 exit 1

cmake -S . -B ./build -G=Ninja && cmake --build ./build -v
if errorlevel 1 exit 1

cd build
ctest -VV --output-on-failure
if errorlevel 1 exit 1