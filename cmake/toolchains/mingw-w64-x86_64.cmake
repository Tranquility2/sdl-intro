# mingw-w64-x86_64.cmake — CMake toolchain for cross-compiling from Linux to
# 64-bit Windows with MinGW-w64.
#
# This file only describes the target platform and toolchain (compilers, target
# triple, sysroot search policy, static runtime linkage). It intentionally does
# not set project warning, optimization, or dependency options — those stay in
# CMakeLists.txt / CMakePresets.json so the toolchain is the single source of
# cross-compilation truth and nothing else is duplicated.
#
# Usage:
#     cmake --preset mingw-release          # via CMakePresets.json
#     cmake -DCMAKE_TOOLCHAIN_FILE=cmake/toolchains/mingw-w64-x86_64.cmake ...

set(CMAKE_SYSTEM_NAME Windows)
set(CMAKE_SYSTEM_PROCESSOR x86_64)

# The target triple prefix. Allow an override so users on distributions with a
# differently named toolchain can point at it without editing this file.
if(NOT DEFINED MINGW_TARGET_TRIPLE)
    set(MINGW_TARGET_TRIPLE x86_64-w64-mingw32)
endif()

set(CMAKE_C_COMPILER   ${MINGW_TARGET_TRIPLE}-gcc)
set(CMAKE_CXX_COMPILER ${MINGW_TARGET_TRIPLE}-g++)
set(CMAKE_RC_COMPILER  ${MINGW_TARGET_TRIPLE}-windres)

# Search for target headers/libraries under the MinGW sysroot, but keep host
# programs (compilers, code generators) discoverable from the host paths.
set(CMAKE_FIND_ROOT_PATH /usr/${MINGW_TARGET_TRIPLE})
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)

# Link the GCC and C++ runtimes plus winpthread statically so the resulting
# executable is self-contained and does not depend on MinGW runtime DLLs. This
# matches the project's static-SDL philosophy for the produced binary; it is not
# a compiler/optimization flag and is not duplicated elsewhere.
set(CMAKE_EXE_LINKER_FLAGS_INIT
    "-static -static-libgcc -static-libstdc++")
