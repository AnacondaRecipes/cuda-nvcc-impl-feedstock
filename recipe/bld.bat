if not exist %PREFIX% mkdir %PREFIX%
if not exist %LIBRARY_LIB%\x64 mkdir %LIBRARY_LIB%\x64

REM our feedstock has four sources: nvcc, crt, nvvm, libnvptxcompiler

move nvcc\bin\* %LIBRARY_BIN%
move nvcc\bin\crt %LIBRARY_BIN%
move nvcc\include\* %LIBRARY_INC%

move crt\include\crt %LIBRARY_INC%

move nvvm\nvvm %PREFIX%\Library

move libnvptxcompiler\lib\x64\* %LIBRARY_LIB%\x64
move libnvptxcompiler\include\* %LIBRARY_INC%
