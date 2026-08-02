cmake_minimum_required(VERSION 3.20)
project(assembly_minecraft LANGUAGES C ASM_NASM)

# Set custom output directories (relative to project root)
#set(BUILD_DIR "${CMAKE_SOURCE_DIR}/build")
#set(BIN_DIR "${BUILD_DIR}/bin")
#set(OBJ_DIR "${BUILD_DIR}/tmp")
#file(MAKE_DIRECTORY ${BIN_DIR})
#file(MAKE_DIRECTORY ${OBJ_DIR})

set(WINDOW_LIB_SOURCES)

if ((NOT TARGET_OS AND WIN32) OR (TARGET_OS STREQUAL "WINDOWS"))
    set(TARGET_OS "WINDOWS")
    set(STD_LIBS
        kernel32 user32 gdi32 opengl32
    )
    set(LINKER_PARAMS "-nostdlib" "-nostartfiles" "-Wl,--entry=main" "-Wl,--strip-all")
    list(APPEND WINDOW_LIB_SOURCES
        libs/window/src/main/nasm/win.window.x64.asm
    )

elseif ((NOT TARGET_OS AND UNIX AND NOT APPLE) OR (TARGET_OS STREQUAL "LINUX"))
    set(TARGET_OS "LINUX")
    set(STD_LIBS)
    set(LINKER_PARAMS "-nostdlib" "-nostartfiles" "-Wl,-e=main" "-Wl,--strip-all")
    list(APPEND WINDOW_LIB_SOURCES
        libs/window/src/main/nasm/lin.window.x64.asm
    )

elseif (NOT TARGET_OS)
    message(FATAL_ERROR "This OS is not supported yet")
endif()

message(STATUS ${TARGET_OS})
message(STATUS ${WINDOW_LIB_SOURCES})

add_library(Window STATIC
    ${WINDOW_LIB_SOURCES}
)

add_executable(hello_triangle
    src/main/nasm/com/mojang/rubydung/RubyDung.x64.code.asm
    src/main/nasm/com/mojang/rubydung/RubyDung.x64.data.asm
)

target_link_libraries(hello_triangle PRIVATE Window ${STD_LIBS})


set_target_properties(hello_triangle PROPERTIES LINKER_LANGUAGE C)

add_compile_definitions("${TARGET_OS}" "x64" "SSE" "SSE2" "SSE4_1" "AVX")
target_compile_options(Window PRIVATE "-i ${CMAKE_SOURCE_DIR}/include/libs/")
target_compile_options(hello_triangle PRIVATE "-i ${CMAKE_SOURCE_DIR}/include/")
target_link_options(hello_triangle PRIVATE ${LINKER_PARAMS})
