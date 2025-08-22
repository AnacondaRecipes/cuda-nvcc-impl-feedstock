#!/bin/bash
set -ex

echo "Checking RPATH configuration..."

# Function to validate a library's RPATH
check_rpath() {
    local lib=$1
    local name=$(basename "$lib")
    
    # Skip symlinks
    [ -L "$lib" ] && return 0
    
    # Check if it's an ELF file
    file "$lib" | grep -q "ELF" || return 0
    
    echo "Checking: $name"
    
    # Get RPATH/RUNPATH
    local rpath_info=$(readelf -d "$lib" 2>/dev/null | grep -E "(RPATH|RUNPATH)")
    
    # Check for $ORIGIN
    if ! echo "$rpath_info" | grep -q '\$ORIGIN'; then
        echo "ERROR: $name missing \$ORIGIN in RPATH/RUNPATH"
        return 1
    fi
    
    # Check for problematic absolute paths
    if echo "$rpath_info" | grep -E "(/usr/local/cuda|/tmp|/home)"; then
        echo "ERROR: $name contains absolute build paths"
        return 1
    fi
    
    # Check for unresolved dependencies (excluding driver libs)
    local missing_deps=$(ldd "$lib" 2>&1 | grep "not found" | grep -v "libcuda.so" | grep -v "libnvidia-ml.so")
    if [ -n "$missing_deps" ]; then
        echo "ERROR: $name has unresolved dependencies:"
        echo "$missing_deps"
        return 1
    fi
    
    echo "  ✓ $name RPATH is correct"
    return 0
}

# Check all libraries
exit_code=0
for lib in $PREFIX/lib/*.so*; do
    [ -f "$lib" ] && check_rpath "$lib" || exit_code=$?
done

exit $exit_code
