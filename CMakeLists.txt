cmake_minimum_required(VERSION 3.27)
project(assembly_minecraft ASM_NASM)

# Set custom output directories (relative to project root)
set(BUILD_DIR "${CMAKE_SOURCE_DIR}/build")
set(BIN_DIR "${BUILD_DIR}/bin")
set(OBJ_DIR "${BUILD_DIR}/tmp")
file(MAKE_DIRECTORY ${BIN_DIR})
file(MAKE_DIRECTORY ${OBJ_DIR})

# Define source and output paths
set(ASM_FILE "${CMAKE_SOURCE_DIR}/src/main/nasm/main.asm")
set(OBJ_FILE "${OBJ_DIR}/main.obj")
set(EXE_FILE "${BIN_DIR}/main.exe")

# Step 1: Assemble .asm to .obj
add_custom_command(
    OUTPUT  ${OBJ_FILE}
    COMMAND nasm -f win64 -i ${CMAKE_SOURCE_DIR}/include -Dx64 ${ASM_FILE} -o ${OBJ_FILE}
    DEPENDS ${ASM_FILE}
    COMMENT "[NASM] Assembling main.asm -> main.obj"
)

# Step 2: Link .obj to .exe
add_custom_command(
    OUTPUT  ${EXE_FILE}
    COMMAND gcc -nostartfiles -nostdlib -o ${EXE_FILE} ${OBJ_FILE} -lkernel32 -luser32
    DEPENDS ${OBJ_FILE}
    COMMENT "[GCC] Linking main.obj -> main.exe"
)

# Define the final build target
add_custom_target(hello ALL
    DEPENDS ${EXE_FILE}
    COMMENT "[CMake] Build complete: main.exe"
)

# Ensure CMake builds in the root-level build directory
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${BIN_DIR})
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${OBJ_DIR})
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${OBJ_DIR})
