# Assembly Minecraft

Minecraft written entirely in NASM Assembly, using CMake as a building script.

This project was created with the aim of studying assembly and the principles of how games work.
The project structure tries to replicate the original Java Edition of the game without using
third-party libraries.
All libraries in the process of project development will be developed manually and will be explained
in the code comments or in the documentation.

Current version consist of "Hello, World!" example, written entirely in NASM, using Windows API for
printing the phrase. There is no exception handling in code or build script: they will be added later
during development.

## Features

+ Basic "Hello, World!" example
+ CMake-based build system

## Build Instructions

To build a project you can basically open it in an IDE, and it'll do its think, creating targets
for you. If you want to make your day harder, doing all the heavy lifting yourself, you can run
something like this CMake-wretchedness in terminal:

```shell
cmake -DCMAKE_BUILD_TYPE=Debug \    # CMake Profile: Debug or Release
      -DCMAKE_MAKE_PROGRAM=ninja \  # Path to 'Ninja' build tool
      -G Ninja \                    # to set it to be generator
      -S assembly-minecraft \       # Source directory: basically, the directory, where CMakeLists.txt is located
      -B assembly-minecraft/build   # Build directory: this is where final binaries will be stored
```

I could make a mistake – I don't really know much about CMake, and it's weird and...weird.
If you'd like to compile project yourself, there is simpler (maybe just for me) solution.
All you need is `nasm` assembler, and `gcc` compiler for linking:

```shell
# Make sure you're in the project directory
cd assembly-minecraft

# Create all necessary directories
mkdir -p build/{bin,tmp}

# Then assemble .asm to .obj (because Windows-only execution file)
nasm -f win64 -i ./include -Dx64 src/main/nasm/hello.asm -o build/tmp/hello.obj

# And link object file to the application
# Of course, we're using only 'kernel32' Windows library, and no other standard libs at al
gcc -nostartfiles -nostdlib -o build/bin/hello.exe build/tmp/hello.obj -lkernel32

# There will be the `hello.exe` executable file in `build/bin` you can run, and see "Hello, World!" in the terminal
```

Later in the development pipeline, I'll try to provide scripts for building the project completely without
CMake for developers who do not want/can use it.
