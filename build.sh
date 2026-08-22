#!/usr/bin/env bash

# ============================================================
#  Project layout
# ============================================================

#
# The project has pretty simple structure:
# '$BUILD_DIR/tmp/' - temporal storage for object files compiled by the script
#     '.../libs/<lib>/' - directory for temporal storage of the library object files
# '$LIBS_DIR/<lib>/src/main/<language>/' - directory with source files for library implementation on the <language>
# '$SOURCE_DIR/<target>/<language>/' - directory with source files for target implementation on the <language>
# '$TESTS_DIR/<target>/' - directory with tests sources for the target (can be almost any structure)
#
BUILD_DIR="build/"  # Directory the project is build into
LIBS_DIR="libs/"    # Directory the local libraries are located in
SOURCE_DIR="src/"   # Directory the target's source code is located in
TESTS_DIR="tests/"  # Directory the tests are located in

LIBS_INCLUDES="include/libs/"
MAIN_INCLUDES="include/"

BASE_OPTIMIZATIONS_x64="SSE SSE2 SSE4.1 AVX"

VERSION="1.0"

# ============================================================
#  Host detection
# ============================================================

host_os() {
    case "$(uname -s)" in
        Linux*)  echo "Linux" ;;
        Darwin*) echo "macOS" ;;
        *)       echo "Linux" ;;  # Anything else running build script is unusual; guess Linux
    esac
}


# ============================================================
#  Name normalization
# ============================================================

# Takes architecture name and returns normalized value for functions to use
normalize_arch() {
    local key
    key=$(printf '%s' "$1" | tr -d '._ -' | tr '[:lower:]' '[:upper:]')

    case "$key" in
        X64|X8664|AMD64) echo "x64" ;;
        *) return 1 ;;  # ARM64 etc. isn't a thing yet
    esac
}

# Takes OS name and returns normalized value for functions to use
normalize_os() {
    local key
    key=$(printf '%s' "$1" | tr -d '._ -' | tr '[:lower:]' '[:upper:]')

    case "$key" in
        WINDOWS|WIN|WIN32|WIN64) echo "Windows" ;;
        LINUX|LIN|LNX|LIN32|LIN64|DEBIAN|ARCH|UBUNTU)
                                 echo "Linux" ;;
        # MACOS|MAC|OSX|DARWIN)    echo "macOS" ;;
        *) return 1 ;;
    esac
}

# Takes the target name or alias and converts it into conventional target name
normalize_target() {
    case "$1" in
        main|client) echo "main" ;;
        # Unknown target alias
        *) return 1 ;;
    esac
}

canonical_optimization() {
    local key
    key=$(printf '%s' "$1" | tr -d '._-' | tr '[:lower:]' '[:upper:]')

    case "$key" in
        SSE)   echo "SSE"    ;;
        SSE2)  echo "SSE2"   ;;
        SSE41) echo "SSE4_1" ;;
        AVX)   echo "AVX"    ;;
        # Unsupported optimizations for now
        *) return 1 ;;
    esac
}

# Takes the list of optimizations and normalizes it
normalize_optimizations() {
    local result=""

    for flag in $1 ; do
        # Pass empty flags
        [ -z "$flag" ] && continue
        canon=$(canonical_optimization "$flag") || {
            echo "error: unrecognized optimization '$flag'" >&2
            return 1
        }

        case " $result " in
            *" $canon "*) ;;  # Already active
            *) result="$result $canon" ;;
        esac
    done

    echo "$result"
}

# Returns the prefix for the OS-specific files
os_prefix() {
    case "$1" in
        Windows) echo "win" ;;
        Linux)   echo "lin" ;;
        # macOS)   echo "mac" ;;
        # Unsupported OS
        *) return 1 ;;
    esac
}

# Returns the NASM define identifier from the normalized OS name given
os_define() {
    case "$1" in
        Windows) echo "WINDOWS" ;;
        Linux)   echo "LINUX"   ;;
        # macOS)   echo "MACOS"   ;;
        # Unsupported OS
        *) return 1 ;;
    esac
}

# Returns "0" if the filename is OS-specific (has OS-prefix)
is_os_specific() {
    case "$1" in
        # OS-specific prefixes
        "$(os_prefix "Windows")."*) return 0 ;;
        "$(os_prefix "Linux")."*)   return 0 ;;
        # "$(os_prefix "macOS")."*)   return 0 ;;
        # No prefix / Unsupported OS
        *) return 1 ;;
    esac
}


# ============================================================
#  Target registry
# ============================================================

ALL_TARGETS="main"
DEFAULT_TARGET="main"

# Checks if the target exists
target_exists() {
    local target
    for target in $ALL_TARGETS; do [ "$target" = "$(normalize_target "$1")" ] && return 0; done
    return 1
}

# Descriptions for target listing on 'build targets'
target_description() {
    case "$1" in
        main) echo "The main project binary" ;;
        *) return 1 ;;
    esac
}

# Libraries this target links against (see library below)
# Uses local libraries' implementations in 'libs/'
target_libraries() {
    case "$1" in
        main)  # Main target libraries
            echo "window"
            echo "opengl"
            ;;
        *) return 1 ;;
    esac
}

# Dependencies for this target on other targets
# Tells you exactly what other targets to compile before your main one
target_dependencies() {
    case "$1" in
        main) ;;
        *) return 1 ;;
    esac
}

# Files with actual entry points for the target
target_entry() {
    case "$1" in
        main)
            # NASM language
            echo "nasm/lin.entry.x64.code.asm"
            echo "nasm/win.entry.x64.code.asm"
            ;;
        *) return 1 ;;
    esac
}

# Logical source files for this target
# Contains relative paths omitting the 'src/<target>/'
target_sources() {
    case "$1" in
        main)
            # NASM language
            echo "nasm/com/mojang/rubydung/RubyDung.x64.code.asm"
            echo "nasm/com/mojang/rubydung/RubyDung.x64.data.asm"
            ;;
        *) return 1 ;;
    esac
}


# ============================================================
#  Library registry
# ============================================================

# System libraries to link against
link_libraries() {
    case "$1" in
        Windows)  # Windows-specific system libraries
            echo "kernel32"  # Windows Base API (core OS capabilities)
            echo "user32"    # User Interface Manager (window system)
            echo "gdi32"     # Graphics Device Interface (window system)
            echo "opengl32"  # OpenGL system library
            ;;
        Linux)  # Linux-specific system libraries
            echo "X11"  # X11 window system
            echo "GL"   # OpenGL system library
            ;;
        # OS is not supported
        *) return 1 ;;
    esac
}

# Source files for a library on a given OS, relative to
# '$LIBS_DIR/<lib>/main/', since every lib-target is 'main'
library_sources() {
    case "$1" in
        opengl)  # OpenGL library sources
            # NASM language
            # OpenGL implementation doesn't have Linux sources
            echo "nasm/win.opengl.x64.code.asm"
            ;;
        window)  # Window library sources
            # NASM language
            echo "nasm/lin.window.x64.asm"
            echo "nasm/win.window.x64.asm"
            ;;
        # Unknown library implementation
        *) return 1 ;;
    esac
}

# Zig target OS
zig_target() {
    case "$1" in
        Windows) echo -n "x86_64-windows-gnu" ;;
        Linux)   echo -n "x86_64-linux-gnu"   ;;
        # macOS)   echo -n "x86_64-macos-gnu"   ;;
        # Unsupported OS
        *) return 1 ;;
    esac
}

# Format for NASM assembly
nasm_format() {
    case "$1" in
        Windows) echo -n "win64"   ;;
        Linux)   echo -n "elf64"   ;;
        # macOS)   echo -n "macho64" ;;
        # Unsupported OS
        *) return 1 ;;
    esac
}

# OS-specific entry-point
entry_point() {
    case "$1" in
        Windows) echo "win.entry" ;;
        Linux)   echo "lin.entry" ;;
        # Unsupported OS
        *) return 1 ;;
    esac
}

# Object file extension
object_extension() {
    case "$1" in
        Windows) echo -n "obj" ;;
        Linux)   echo -n "o"   ;;
        # Unsupported OS
        *) return 1 ;;
    esac
}

# Execution file extension (for auto-generated output file names)
execution_extension() {
    case "$1" in
        Windows) echo -n ".exe" ;;
        Linux)   echo -n ""     ;;
        # Unsupported OS
        *) return 1 ;;
    esac
}


# ============================================================
#  Tests registry
# ============================================================

ALL_TESTS=""


# ============================================================
#  Build instruments
# ============================================================

require() {
    command -v "$1" >/dev/null 2>&1 || {
        echo "error: '$1' was not found on PATH - install it (or fix PATH) and try again" >&2
        return 1
    }
}

#
# Source code filenames carry a payload. Since they have a format of
# "[<os-prefix>.]<filename>.<arch>[.<section>[.<optimizations>]].<ext>"
# It alone can tell you a lot about the source file:
# If <os-prefix> is present, this file is OS-specific, and must be compiled
# only for the specified OS.
# <arch> shows what architecture the file is written for: x64, ARM, etc. (it's only 'x64' for now)
# If <section> is present, that shows you exactly what section the whole file is.
# If it isn't, that means the file contains more than one section.
# <optimizations> only present on "code" sections and contain more specific
# optimizations that are possible with additional CPU extensions
# not covered by Specification's minimum requirements.
# Extension <ext> shows you the type of the file: "asm" for assembly, "wat" for WebAssembly text representation etc.
#

# Assembles the file with given parameters
assemble_file() {
    local filename="$1"
    local build_dir="$2"
    local includes="$3"
    local target_arch="$4"
    local target_os="$5"
    local optimizations="$6"
    local type="$7"

    local output
    local tmp_filename

    # If it's the library file, we add the prefix to the output
    if [[ "$type" == "library" ]]; then
        tmp_filename="${filename#$LIBS_DIR}"  # Cut off the $LIBS_DIR
        output="libs/${tmp_filename%%/*}/"
        tmp_filename="${tmp_filename#*/}"      # Cut off the lib-name
    else
        tmp_filename="$filename"
    fi

    # "tmp_filename" contains the path in format "<source>/<target>/<lang>/<path>/<filename>"
    tmp_filename="${tmp_filename#*/}"  # Get rid of <source>
    tmp_filename="${tmp_filename#*/}"  # Get rid of <target>
    tmp_filename="${tmp_filename#*/}"  # Get rid of <lang>

    local package=""
    local name

    [[ "$tmp_filename" == *"/"* ]] && package=$(printf '%s' "${tmp_filename%/*}@" | tr '/' '.')
    name="${tmp_filename##*/}"
    name="${name%.*}"  # Cut off the extension

    output="${build_dir}tmp/$output$package$name.$(object_extension "$target_os")"

    local def_optimizations=""
    for flag in $optimizations ; do def_optimizations="$def_optimizations -D$flag" ; done

    # Assemble the file
    nasm -f "$(nasm_format "$target_os")" -i "$includes" "-D$target_arch" "-D$(os_define "$target_os")" $def_optimizations "$filename" -o $output

    # 'Return' the object file name
    echo $output
}

# Returns '0' if an array contains an item given
array_contains() {
    for item in $1 ; do [ "$item" = "$2" ] && return 0 ; done
    return 1
}

# Helper function for visiting the dependency tree node
visit() {
    local target="$1"

    # Skip if already fully processed and ordered
    if array_contains "$VISITED" "$target"; then return 0 ; fi
    # Detect cycle in current call stack
    if array_contains "$VISITING" "$target"; then echo "[ERROR] Circular dependency detected involving target '$target'" >&2 ; return 1 ; fi

    # Dynamic local variable scoping passes VISITING down the call stack
    # and automatically unwinds when the function frame exits.
    local VISITING="$VISITING $target"
    local dependencies
    local dependency

    dependencies=$(target_dependencies "$target")
    for dependency in $dependencies ; do
        visit "$dependency" || return 1
    done

    VISITED="$VISITED $target"
    RESULT="$RESULT $target"
}

# Takes list of targets, and returns the list of all the dependencies with no repetitions
dependency_flatten() {
    local targets="$1"
    VISITED=""
    RESULT=""

    local target
    for target in $targets ; do
        local VISITING=""
        visit "$target" || return 1
    done

    # Unquoted echo strips excess leading/trailing whitespaces
    echo $RESULT
}

# Returns the list of libraries from the flattened dependency tree
load_libraries() {
    local libraries=""

    for target in $1 ; do
        for library in $(target_libraries "$target") ; do
            # Add library to the list only if it isn't there already
            if ! array_contains "$libraries" "$library" ; then
                libraries="$libraries $library"
            fi
        done
    done

    echo $libraries
}

# Takes list of sources, and filters them using the parameters
filter_sources() {
    local sources="$2"
#    local results=""
    local source

    local prefix="$1"

    local language="$3"
    local target_arch="$4"
    local target_os="$5"
#    local optimizations="$6"

    for source in $sources ; do
        # Check if language of the source match the requested one
        [[ "$source" == "$language/"* ]] || continue

        local filename

        filename=$(basename "$source")  # Get the basename

        # If the file is OS-specific, we need to check if OS is match
        if is_os_specific "$filename" ; then
            # Ignore the file if the OS is wrong
            [[ "$filename" == "$(os_prefix "$target_os")."* ]] || continue
            filename="${filename#*.}"  # Cut off the OS-prefix
        fi

        filename="${filename#*.}"  # Cut off the filename itself leaving "<architecture>[.<section>[.<flags>]].<ext>"

        # Skip the file if it's wrong architecture
        [[ "$filename" == "$target_arch."* ]] || continue

        # Since we don't have optimization usage in files yet
        # We just return spit the path for the file
        # @TODO Optimizations flag checker

        echo "$prefix$source"
    done
}

# Takes the (target, target_arch, target_os, optimizations, build_directory, sys_libs, output)
# and builds the selected target
target_build() {
    local TARGET="$1"

    local TARGET_ARCH="$2"
    local TARGET_OS="$3"

    local OPTIMIZATIONS="$4"

    local BUILD_DIRECTORY="$5"
    local SYS_LIBS="$6"
    local OUTPUT="$7"

    # --- Building process ---
    local libraries
    local dependencies

    echo "[INFO] Flattening the target dependency tree..."
    dependencies=$(dependency_flatten "$TARGET")
    [ $? = 0 ] || return 1  # Return if some error occurred

    echo "[INFO] Resolving target libraries..."
    libraries=$(load_libraries "$dependencies")

    # Loading source filenames
    local lib_sources
    local dep_sources
    local entry_sources
    local sources
    local source

    echo "[INFO] Resolving library source files..."
    for library in $libraries ; do
        sources=$(library_sources "$library")

        # Library does not exist
        if [ ! $? = 0 ]; then echo "[ERROR] Apparently, '$library' library is not in Library Registry" >&2 ; return 1 ; fi

        sources=$(filter_sources "$LIBS_DIR$library/src/main/" "$sources" "nasm" "$TARGET_ARCH" "$TARGET_OS" "$OPTIMIZATIONS")
        [ -z "$sources" ] || {
            lib_sources="$lib_sources $sources"  # Save if not empty
            mkdir -p "${BUILD_DIRECTORY}tmp/libs/$library"  # Create the temp directory for the library
        }
    done

    echo "[INFO] Resolving target source files..."
    for target in $dependencies ; do
        sources=$(target_sources "$target")
        # Target does not exist
        if [ ! $? = 0 ]; then echo "[ERROR] Apparently, '$target' target is not in Target Registry" >&2 ; return 1 ; fi

        sources=$(filter_sources "$SOURCE_DIR$target/" "$sources" "nasm" "$TARGET_ARCH" "$TARGET_OS" "$OPTIMIZATIONS")
        [ -z "$sources" ] || dep_sources="$dep_sources $sources"  # Save if not empty
    done

    echo "[INFO] Resolving the entry point code..."
    entry_sources=$(filter_sources "$SOURCE_DIR$target/" "$(target_entry "$TARGET")" "nasm" "$TARGET_ARCH" "$TARGET_OS" "$OPTIMIZATIONS")

    # Convert strings into arrays
    lib_sources=($lib_sources)
    entry_sources=($entry_sources)
    dep_sources=($dep_sources)

    local libs_count="${#lib_sources[@]}"
    local entry_count="${#entry_sources[@]}"
    local deps_count="${#dep_sources[@]}"

    # List of all object files
    local lib_objs=""
    local entry_objs=""
    local dep_objs=""

    local lib_obj
    local entry_obj
    local dep_obj

    # Library Sources Assembling
    for index in "${!lib_sources[@]}" ; do
        source="${lib_sources[index]}"

        echo -ne "\r[STEP $((index + 1)) / $libs_count] Assembling library source files..."
        lib_obj=$(assemble_file "$source" "$BUILD_DIRECTORY" "$LIBS_INCLUDES" "$TARGET_ARCH" "$TARGET_OS" "$OPTIMIZATIONS" "library") || return 1
        lib_objs="$lib_objs $lib_obj"
    done
    echo ""  # New line

    # Main Source Assembling
    for index in "${!dep_sources[@]}" ; do
        source="${dep_sources[index]}"

        echo -ne "\r[STEP $((index + 1)) / $deps_count] Assembling target source files..."
        dep_obj=$(assemble_file "$source" "$BUILD_DIRECTORY" "$MAIN_INCLUDES" "$TARGET_ARCH" "$TARGET_OS" "$OPTIMIZATIONS" "main") || return 1
        dep_objs="$dep_objs $dep_obj"
    done
    echo ""  # New line

    # Entry Sources Assembling
    for index in "${!entry_sources[@]}" ; do
        source="${entry_sources[index]}"

        echo -ne "\r[STEP $((index + 1)) / $entry_count] Assembling target entry-point sources..."
        entry_obj=$(assemble_file "$source" "$BUILD_DIRECTORY" "$MAIN_INCLUDES" "$TARGET_ARCH" "$TARGET_OS" "$OPTIMIZATIONS" "entry") || return 1
        entry_objs="$entry_objs $entry_obj"
    done
    echo ""  # New line

    lib_objs=($lib_objs)
    entry_objs=($entry_objs)
    dep_objs=($dep_objs)

    local sys_libs=( $(link_libraries "$TARGET_OS") )
    sys_libs=("${sys_libs[@]/#/-l}")  # Add '-l' prefix

    echo "[INFO] Linking the object files..."

    zig cc -target "$(zig_target "$TARGET_OS")" -nostartfiles -nostdlib "-Wl,--entry=$(entry_point "$TARGET_OS")" "-Wl,--strip-all" $SYS_LIBS -o "${BUILD_DIRECTORY}bin/$OUTPUT" ${lib_objs[@]} ${entry_objs[@]} ${dep_objs[@]} "${sys_libs[@]}" || return 1

    echo "[INFO] Saving executable as '${BUILD_DIRECTORY}bin/$OUTPUT'..."
}

# ============================================================
#  Command handlers
# ============================================================

cmd_help() {
    # There's more than one parameter for 'help'
    if [ $# -gt 1 ]; then echo "error: 'help' command takes only one parameter (try 'build help')" >&2 ; exit 1 ; fi

    local topic="${1:-}"
    case "$topic" in
        "")  # 'build help' with no parameters
            echo "Assembly-Minecraft build script"
            echo ""
            echo "Usage:"
            echo "  build help [<topic>]                 Print this manual, or detail for one topic"
            echo "  build clean [<dir>]                  Delete the build directory (default: '$BUILD_DIR') and everything in it"
            echo "  build targets                        List available build targets"
            echo "  build tests                          List available tests"
            echo "  build build [<target>] [<params>]    Build the given target (default target if omitted)"
            echo "  build test [<tests>]                 Build and run the given test(-s) (all tests if omitted)"
            echo ""
            echo "Parameters:"
            echo "  --build            directory to use as the build directory (default: '$BUILD_DIR')"
            echo "  --optimizations    comma-separated CPU extension list, e.g. '--optimizations=sse4.2,avx512f'"
            echo "  --output, -o       output file name"
            echo "  --sys-libs         directory to use as the system includes when cross-compiling"
            echo "  --target-arch      target architecture to build for (x64; only option for now)"
            echo "  --target-os        target OS to build for (Windows | Linux, default: Host OS)"
            echo ""
            echo "Run 'build help <topic>' for more info" ;;
        # Topics
        help)
            echo "Ugh...try 'build help', it already shows you everything..." ;;
        clean)
            echo "build clean [<dir>]    cleans the building directory by deleting it."
            echo "                       By default the build directory is in '$BUILD_DIR', but you can rewrite it with the optional parameter." ;;
        targets)
            echo "build targets    lists all the available targets to build."
            echo "                 Just try to run 'build targets'." ;;
        tests)
            echo "build tests    lists all the available tests to run."
            echo "               Just try to run 'build tests'." ;;
        build)
            echo "build build [<target>] [<params>]    builds the target with the given parameters."
            echo "                                     If target is omitted, the default one is used (default target: '$DEFAULT_TARGET')."
            echo "                                     If parameters are omitted, the default ones are used." ;;
        test)
            echo "build test [<tests>]    builds and runs the given test for the project."
            echo "                        If tests are omitted, all tests are executed." ;;

        --build)
            echo "--build  <dir>    overrides the default build directory name for the target build (default: '$BUILD_DIR')." ;;
        --optimizations)
            echo "--optimizations  <flags>    comma-separated optimization names you're allowing the program to use."
            echo "                            For \"x64\" it's the CPU extensions you're promising the program to have."
            echo "                            By default '$BASE_OPTIMIZATIONS_x64' extensions are available (project minimum), "
            echo "                            all the optimizations are added, not replaced." ;;
        --output|-o)
            echo "--output  <filename>    overrides the default binary name for the target being built." ;;
        --sys-libs)
            echo "--sys-libs  <dir>    uses the directory as the system library include directory for linker"
            echo "                     in case you cross-compile the project for a platform other than your host one." ;;
        --target-arch)
            echo "--target-arch  <x64>    Architecture you're building the project for (aliases like \"x86-64\", \"amd64\" work)."
            echo "                        The \"x64\" is the only supported value right now." ;;
        --target-os)
            echo "--target-os  <Windows|Linux>    Operating System you're building the project for (aliases like \"win64\", \"WIN\" work)."
            echo "                                Defaults to the OS running this script (may be inaccurate, please use this parameter to specify the OS)." ;;
        *) echo "error: no help manual for '$topic'. Try 'build help'." >&2 ; exit 1 ;;
    esac
}

cmd_clean() {
    # There's more than one parameter for 'clean'
    if [ $# -gt 1 ]; then echo "error: 'clean' command takes only one optional parameter (try 'build help clean' for more info)." >&2 ; exit 1 ; fi

    local build_dir="${1:-$BUILD_DIR}"
    if [ -d "$build_dir" ]; then
        rm -fr "$build_dir"
        echo "Removed '$build_dir' build directory"
    else
        echo "Nothing to clean ('$build_dir' doesn't exist)"
    fi
}

cmd_targets() {
    echo "Available targets:"
    local target
    for target in $ALL_TARGETS; do
        printf '  %-12s  %s\n' "$target" "$(target_description "$target")"
    done
    echo "Default target: $DEFAULT_TARGET"
}

cmd_tests() {
    # There are no tests
    if [ -z "$ALL_TESTS" ]; then
        echo "No tests available yet."
        return 0
    fi

    echo "Available tests:"
    local t
    for t in $ALL_TESTS; do echo "  $t"; done
}

cmd_test() {
    # There are no tests
    if [ -z "$ALL_TESTS" ]; then
        echo "No tests to run yet - come back once there's something in 'tests/'."
        exit 0
    fi

    echo "error: named test running isn't wired up yet." >&2
    exit 1
}

cmd_build() {
    local OPT_TARGET=""

    local OPT_BUILD_DIR=""
    local OPT_SYS_LIBS=""
    local OPT_TARGET_ARCH=""
    local OPT_TARGET_OS=""
    local OPT_OPTIMIZATIONS=""
    local OPT_OUTPUT=""

    # Get the parameters / target
    while [ $# -gt 0 ]; do
        case "$1" in
            # Build directory
            --build=*)
                # The build directory was already assigned
                if [ -n "$OPT_BUILD_DIR" ]; then echo "error: ambiguous assignment. You tried to reassign the build directory, although it was already assigned to '$OPT_BUILD_DIR'" >&2 ; exit 1 ; fi

                OPT_BUILD_DIR="${1#*=}"

                # If it's the file, we can't do nothing
                if [ -f "$OPT_BUILD_DIR" ]; then echo "error: can't use '$OPT_BUILD_DIR', because it's a file" >&2 ; exit 1 ; fi ;;
            --build)
                # The build directory was already assigned
                if [ -n "$OPT_BUILD_DIR" ]; then echo "error: ambiguous assignment. You tried to reassign the build directory, although it was already assigned to '$OPT_BUILD_DIR'" >&2 ; exit 1 ; fi
                # If number of parameters is 1, we can't have a path
                if [ $# -eq 1 ]; then echo "error: no build directory was specified, although the parameter '$1' was mentioned" >&2 ; exit 1 ; fi

                shift ; OPT_BUILD_DIR="$1"

                # If it's the file, we can't do nothing
                if [ -f "$OPT_BUILD_DIR" ]; then echo "error: can't use '$OPT_BUILD_DIR' as the build directory, since it's a file" >&2 ; exit 1 ; fi ;;
            # Project optimizations
            --optimizations=*)
                # Optimizations were already assigned
                if [ -n "$OPT_OPTIMIZATIONS" ]; then echo "error: ambiguous assignment. You tried to reassign the optimizations, although they were already assigned to '$OPT_OPTIMIZATIONS'" >&2 ; exit 1 ; fi

                OPT_OPTIMIZATIONS="${1#*=}"
                OPT_OPTIMIZATIONS="${OPT_OPTIMIZATIONS// /}" ;;
            --optimizations)
                # Optimizations were already assigned
                if [ -n "$OPT_OPTIMIZATIONS" ]; then echo "error: ambiguous assignment. You tried to reassign the optimizations, although they were already assigned to '$OPT_OPTIMIZATIONS'" >&2 ; exit 1 ; fi
                # If number of parameters is 1, we can't have optimizations
                if [ $# -eq 1 ]; then echo "error: no optimizations was specified, although the parameter '$1' was mentioned" >&2 ; exit 1 ; fi

                shift ; OPT_OPTIMIZATIONS="$1"
                OPT_OPTIMIZATIONS="${OPT_OPTIMIZATIONS// /}" ;;
            # Output file
            --output=*|-o=*)
                # Output file was already assigned
                if [ -n "$OPT_OUTPUT" ]; then echo "error: ambiguous assignment. You tried to reassign the output file, although it was already assigned to '$OPT_OUTPUT'" >&2 ; exit 1 ; fi

                OPT_OUTPUT="${1#*=}"

                # If it's the directory, we can't rewrite it
                if [ -d "$OPT_OUTPUT" ]; then echo "error: can't use '$OPT_OUTPUT' as output file, since it's a directory" >&2 ; exit 1 ; fi ;;
            --output|-o)
                # Output file was already assigned
                if [ -n "$OPT_OUTPUT" ]; then echo "error: ambiguous assignment. You tried to reassign the output file, although it was already assigned to '$OPT_OUTPUT'" >&2 ; exit 1 ; fi
                # If number of parameters is 1, we can't have a path
                if [ $# -eq 1 ]; then echo "error: no output file was specified, although the parameter '$1' was mentioned" >&2 ; exit 1 ; fi

                shift ; OPT_OUTPUT="$1"

                # If it's the directory, we can't rewrite it
                if [ -d "$OPT_OUTPUT" ]; then echo "error: can't use '$OPT_OUTPUT' as output file, since it's a directory" >&2 ; exit 1 ; fi ;;
            # System library include directory
            --sys-libs=*)
                # System Library includes was already assigned
                if [ -n "$OPT_SYS_LIBS" ]; then echo "error: ambiguous assignment. You tried to reassign the system libraries include directory, although it was already assigned to '$OPT_SYS_LIBS'" >&2 ; exit 1 ; fi

                OPT_SYS_LIBS="${1#*=}"

                # If it's not the directory, we can't use it
                if [ ! -d "$OPT_SYS_LIBS" ]; then echo "error: can't use '$OPT_SYS_LIBS' as the system libraries include directory, since it doesn't exist" >&2 ; exit 1 ; fi ;;
            --sys-libs)
                # System Library includes was already assigned
                if [ -n "$OPT_SYS_LIBS" ]; then echo "error: ambiguous assignment. You tried to reassign the system libraries include directory, although it was already assigned to '$OPT_SYS_LIBS'" >&2 ; exit 1 ; fi
                # If number of parameters is 1, we can't have a path
                if [ $# -eq 1 ]; then echo "error: no system libraries include directory was specified, although the parameter '$1' was mentioned" >&2 ; exit 1 ; fi

                shift ; OPT_SYS_LIBS="${1#*=}"

                # If it's not the directory, we can't use it
                if [ ! -d "$OPT_SYS_LIBS" ]; then echo "error: can't use '$OPT_SYS_LIBS' as the system libraries include directory, since it doesn't exist" >&2 ; exit 1 ; fi ;;
            # Target Architecture
            --target-arch=*)
                # Architecture was already assigned
                if [ -n "$OPT_TARGET_ARCH" ]; then echo "error: ambiguous assignment. You tried to reassign the target architecture, although it was already assigned to '$OPT_TARGET_ARCH'" >&2 ; exit 1 ; fi

                OPT_TARGET_ARCH=$(normalize_arch "${1#*=}")

                # Couldn't recognize the architecture
                if [ $? -ne 0 ]; then echo "error: unknown or unsupported architecture '${1#*=}'" >&2 ; exit 1 ; fi ;;
            --target-arch)
                # Architecture was already assigned
                if [ -n "$OPT_TARGET_ARCH" ]; then echo "error: ambiguous assignment. You tried to reassign the target architecture, although it was already assigned to '$OPT_TARGET_ARCH'" >&2 ; exit 1 ; fi
                # If number of parameters is 1, we can't have an architecture
                if [ $# -eq 1 ]; then echo "error: no architecture was specified, although the parameter '$1' was mentioned" >&2 ; exit 1 ; fi

                shift ; OPT_TARGET_ARCH=$(normalize_arch "$1")
                # Couldn't recognize the architecture
                if [ $? -ne 0 ]; then echo "error: unknown or unsupported architecture '$1'" >&2 ; exit 1 ; fi ;;
            # Target OS
            --target-os=*)
                # OS was already assigned
                if [ -n "$OPT_TARGET_OS" ]; then echo "error: ambiguous assignment. You tried to reassign the target operating system, although it was already assigned to '$OPT_TARGET_OS'" >&2 ; exit 1 ; fi

                OPT_TARGET_OS=$(normalize_os "${1#*=}")

                # Couldn't recognize the operating system
                if [ $? -ne 0 ]; then echo "error: unknown or unsupported operating system '${1#*=}'" >&2 ; exit 1 ; fi ;;
            --target-os)
                # OS was already assigned
                if [ -n "$OPT_TARGET_OS" ]; then echo "error: ambiguous assignment. You tried to reassign the target operating system, although it was already assigned to '$OPT_TARGET_OS'" >&2 ; exit 1 ; fi
                # If number of parameters is 1, we can't have an operating system
                if [ $# -eq 1 ]; then echo "error: no operating system was specified, although the parameter '$1' was mentioned" >&2 ; exit 1 ; fi

                shift ; OPT_TARGET_OS=$(normalize_os "$1")

                # Couldn't recognize the operating system
                if [ $? -ne 0 ]; then echo "error: unknown or unsupported operating system '$1'" >&2 ; exit 1 ; fi ;;
            -*)  # Any other parameters that start dash is unknown flag
                echo "error: unknown flag '$1'" >&2
                exit 1 ;;
            *)
                if [ -z "$OPT_TARGET" ]; then
                    # Target does not exist
                    if ! target_exists "$1"; then echo "error: target '$1' specified does not exist" >&2 ; exit 1 ; fi

                    OPT_TARGET="$1"
                elif target_exists "$1"; then
                    echo "error: you already set the target to '$OPT_TARGET', can't add '$1' as a second target. Try to build them separately" >&2
                    exit 1
                else
                    echo "error: unexpected extra argument '$1'" >&2
                    exit 1
                fi ;;
        esac
        shift
    done

    local TARGET="$(normalize_target "${OPT_TARGET:-$DEFAULT_TARGET}")"

    local BUILD_DIRECTORY="${OPT_BUILD_DIR:-$BUILD_DIR}"
    local SYS_LIBS="${OPT_SYS_LIBS:+"-L $OPT_SYS_LIBS"}"
    local TARGET_ARCH="${OPT_TARGET_ARCH:-"x64"}"
    local TARGET_OS="${OPT_TARGET_OS:-$(host_os)}"
    local OPTIMIZATIONS="$BASE_OPTIMIZATIONS_x64 ${OPT_OPTIMIZATIONS//,/ }"
    local OUTPUT="${OPT_OUTPUT:-"$TARGET-$VERSION$(execution_extension "$TARGET_OS")"}"

    # Normalize the optimization flags
    OPTIMIZATIONS=$(normalize_optimizations "$OPTIMIZATIONS") || return 1

    # Require the tools for assembling and linking
    require "nasm" || return 1
    require "zig"  || return 1

    echo "[INFO] Starting the '$TARGET' target build..."

    # If no building directory found
    if [ ! -d "$BUILD_DIRECTORY" ]; then
        echo "[INFO] Creating build directories..."

        mkdir -p "${BUILD_DIRECTORY}tmp/"
        mkdir -p "${BUILD_DIRECTORY}bin/"
    fi

    local start_time
    local end_time

    start_time=$(date +%s)

    target_build "$TARGET" "$TARGET_ARCH" "$TARGET_OS" "$OPTIMIZATIONS" "$BUILD_DIRECTORY" "$SYS_LIBS" "$OUTPUT"
    [ $? = 0 ] || return 1  # Some error occurred

    end_time=$(date +%s)
    local elapsed=$((end_time - start_time))

    echo "[SUCCESS] Build completed successfully in $elapsed seconds"
}


# ============================================================
#  Argument parsing
# ============================================================

# Get the command and shift all the parameters if any
COMMAND="${1:-help}"  # Default command: 'help'
[ $# -ge 1 ] && shift

case "$COMMAND" in
    help)    cmd_help  "$@" ;;
    build)   cmd_build "$@" ;;
    clean)   cmd_clean "$@" ;;
    "test")  cmd_test  "$@" ;;
    targets)
        # Targets don't need any parameters
        if [ $# -eq 0 ]; then cmd_targets ;
        # If there are some parameters
        else echo "error: 'targets' command does not support any parameters (try 'build targets')" >&2 ; exit 1 ; fi ;;
    tests)
        # Tests don't need any parameters
        if [ $# -eq 0 ]; then cmd_tests ;
        # If there are some parameters
        else echo "error: 'tests' command does not support any parameters (try 'build tests')" >&2 ; exit 1 ; fi ;;
    *) echo "error: unknown command '$COMMAND' (try 'build help')" >&2 ; exit 1 ;;
esac
