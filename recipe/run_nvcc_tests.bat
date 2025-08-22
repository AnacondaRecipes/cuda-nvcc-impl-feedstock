@echo on

nvcc --version
if errorlevel 1 exit 1

nvcc --verbose test.cu
if errorlevel 1 exit 1

cmake -S . -B ./build -G=Ninja && cmake --build ./build -v
if errorlevel 1 exit 1

REM Get CMake version for cloning the right branch
for /f "tokens=3" %%i in ('cmake --version ^| findstr version') do set CMAKE_VERSION=%%i

REM Clone and build CMake's test suite
md cmake-tests
git clone -b v%CMAKE_VERSION% --depth 1 https://gitlab.kitware.com/cmake/cmake.git cmake-tests
if errorlevel 1 exit 1

cmake -S cmake-tests -B cmake-tests/build -DCMake_TEST_HOST_CMAKE=ON -DCMake_TEST_CUDA=nvcc -G "Ninja"
if errorlevel 1 exit 1

REM Change to the CMake test build directory and run CUDA tests
cd cmake-tests\build
ctest -L CUDA --output-on-failure -E "(Architecture|CompileFlags|DeviceLTO|ProperDeviceLibraries|SharedRuntime|ObjectLibrary|WithC|StubRPATH|ArchSpecial|GPUDebugFlag|SeparateCompilationPTX|WithDefs|CUBIN|Fatbin|OptixIR|CUDA_architectures|Toolkit|Cuda.Complex)"
if errorlevel 1 exit 1
