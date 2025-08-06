#!/bin/bash

# Install to conda style directories
[[ -d lib64 ]] && mv lib64 lib

[[ ${target_platform} == "linux-64" ]] && targetsDir="targets/x86_64-linux"
[[ ${target_platform} == "linux-ppc64le" ]] && targetsDir="targets/ppc64le-linux"
# https://docs.nvidia.com/cuda/cuda-compiler-driver-nvcc/index.html?highlight=tegra#cross-compilation
[[ ${target_platform} == "linux-aarch64" && ${arm_variant_type} == "sbsa" ]] && targetsDir="targets/sbsa-linux"
#[[ ${target_platform} == "linux-aarch64" && ${arm_variant_type} == "tegra" ]] && targetsDir="targets/aarch64-linux"

if [ -z "${targetsDir+x}" ]; then
    echo "target_platform: ${target_platform} is unknown! targetsDir must be defined!" >&2
    exit 1
fi

mkdir -p ${PREFIX}/${targetsDir}

for i in `ls`; do
    [[ $i == "LICENSE" ]] && continue
    [[ $i == "build_env_setup.sh" ]] && continue
    [[ $i == "conda_build.sh" ]] && continue
    [[ $i == "metadata_conda_debug.yaml" ]] && continue
    if [[ $i == "bin" ]] || [[ $i == "lib" ]] || [[ $i == "include" ]] || [[ $i == "nvvm" ]]; then
        # Headers and libraries are installed to targetsDir
        mkdir -p ${PREFIX}/$i
        if [[ $i == "bin" ]]; then
            for j in `ls "${i}"`; do
                [[ -f "bin/${j}" ]] || continue

                # Check if this file should be excluded from patchelf processing
                should_skip=false
                while IFS= read -r exclude_pattern; do
                    # Skip empty lines and comments
                    [[ -z "$exclude_pattern" || "$exclude_pattern" =~ ^[[:space:]]*# ]] && continue
                    if [[ "$j" == $exclude_pattern ]]; then
                        should_skip=true
                        break
                    fi
                done < ${RECIPE_DIR}/patchelf_exclude.txt
                
                if [[ "$should_skip" == "true" ]]; then
                    echo "Skipping bin/${j} as it matches an exclusion pattern."
                    continue
                fi

                echo patchelf --force-rpath --set-rpath "\$ORIGIN/../lib:\$ORIGIN/../${targetsDir}/lib" "${i}/${j}" ...
                patchelf --force-rpath --set-rpath "\$ORIGIN/../lib:\$ORIGIN/../${targetsDir}/lib" "${i}/${j}"
            done

            mkdir -p ${PREFIX}/${targetsDir}/bin
            cp -rv $i ${PREFIX}
            ln -sv ${PREFIX}/bin/nvcc ${PREFIX}/${targetsDir}/bin/nvcc
        elif [[ $i == "lib" ]]; then
            cp -rv $i ${PREFIX}/${targetsDir}
            for j in "$i"/*.a*; do
                # Static libraries are symlinked in $PREFIX/lib
                ln -sv ${PREFIX}/${targetsDir}/$j ${PREFIX}/$j
            done
            ln -sv ${PREFIX}/${targetsDir}/lib ${PREFIX}/${targetsDir}/lib64
        elif [[ $i == "include" ]]; then
            cp -rv $i ${PREFIX}/${targetsDir}
        elif [[ $i == "nvvm" ]]; then
            for j in `find "${i}"`; do
                if [[ "${j}" =~ /bin/.*$ ]]; then
                    # Adds the following paths relative to `$PREFIX` to the `RPATH`: `nvvm/lib64`, `lib`, `${targetsDir}/lib`
                    echo patchelf --force-rpath --set-rpath "\$ORIGIN/../lib64:\$ORIGIN/../../lib:\$ORIGIN/../../${targetsDir}/lib" "${j}" ...
                    patchelf --force-rpath --set-rpath "\$ORIGIN/../lib64:\$ORIGIN/../../lib:\$ORIGIN/../../${targetsDir}/lib" "${j}"
                elif [[ "${j}" =~ /lib.*/.*\.so($|\.) && ! -L "${j}" ]]; then
                    # Check if this file should be excluded from patchelf processing
                    should_skip=false
                    while IFS= read -r exclude_pattern; do
                        # Skip empty lines and comments
                        [[ -z "$exclude_pattern" || "$exclude_pattern" =~ ^[[:space:]]*# ]] && continue
                        # Use basename for pattern matching
                        filename=$(basename "$j")
                        if [[ "$filename" == $exclude_pattern ]]; then
                            should_skip=true
                            break
                        fi
                    done < ${RECIPE_DIR}/patchelf_exclude.txt
                    
                    if [[ "$should_skip" == "true" ]]; then
                        echo "Skipping ${j} as it matches an exclusion pattern."
                        continue
                    fi
                    echo patchelf --force-rpath --set-rpath "\$ORIGIN" "${j}" ...
                    patchelf --force-rpath --set-rpath "\$ORIGIN" "${j}"
                fi
            done

            cp -rv $i ${PREFIX}
            ln -sv ${PREFIX}/nvvm ${PREFIX}/${targetsDir}/nvvm

        fi
    else
        cp -rv $i ${PREFIX}/${targetsDir}
    fi
done

# Copy the [de]activate scripts to $PREFIX/etc/conda/[de]activate.d.
# This will allow them to be run on environment activation.
# Name this script starting with `~` so it is run after all other compiler activation scripts.
# At the point of running this, $CXX must be defined.
# for CHANGE in "activate" "deactivate"
# do
#     mkdir -p "${PREFIX}/etc/conda/${CHANGE}.d"
#     cp "${RECIPE_DIR}/${CHANGE}.sh" "${PREFIX}/etc/conda/${CHANGE}.d/~cuda-nvcc_${CHANGE}.sh"
# done

check-glibc ${PREFIX}/{bin,lib}*/* ${PREFIX}/${targetsDir}/{bin,lib}*/* ${PREFIX}/nvvm/{bin,lib}*/*
