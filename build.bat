@echo off
setlocal EnableDelayedExpansion

:: ============================================================
::  Project layout
:: ============================================================

set "BUILD_DIR=build/"
set "LIBS_DIR=libs/"
set "SOURCE_DIR=src/"
set "TESTS_DIR=tests/"

set "LIBS_INCLUDES=include/libs/"
set "MAIN_INCLUDES=include/"

set "BASE_OPTIMIZATIONS_x64=SSE SSE2 SSE4_1 AVX"

set "VERSION=1.0"

:: ============================================================
::  Host detection
:: ============================================================

:: We assume Windows for host in batch script
set "HOST_OS=Windows"

:: ============================================================
::  Name normalization
:: ============================================================

goto :skip_functions

:: Takes architecture and returns normalized values for functions to use
:normalize_arch
setlocal EnableDelayedExpansion

set "key=%~1"
set "key=!key:.=!"
set "key=!key:_=!"
set "key=!key:-=!"
set "key=!key: =!"

:: Uppercase conversion hack via path substitution (not strictly needed since 'if /I' works, but matching bash)
if /I "!key!"=="X64"   (endlocal & set "%~2=x64" & exit /b 0)
if /I "!key!"=="X8664" (endlocal & set "%~2=x64" & exit /b 0)
if /I "!key!"=="AMD64" (endlocal & set "%~2=x64" & exit /b 0)

endlocal & exit /b 1

:: Takes OS name and returns normalized value for functions to use
:normalize_os
setlocal EnableDelayedExpansion

set "key=%~1"
set "key=!key:.=!"
set "key=!key:_=!"
set "key=!key:-=!"
set "key=!key: =!"

:: Windows
if /I "!key!"=="WINDOWS" (endlocal & set "%~2=Windows" & exit /b 0)
if /I "!key!"=="WIN"     (endlocal & set "%~2=Windows" & exit /b 0)
if /I "!key!"=="WIN32"   (endlocal & set "%~2=Windows" & exit /b 0)
if /I "!key!"=="WIN64"   (endlocal & set "%~2=Windows" & exit /b 0)

:: Linux
if /I "!key!"=="LINUX"  (endlocal & set "%~2=Linux" & exit /b 0)
if /I "!key!"=="LIN"    (endlocal & set "%~2=Linux" & exit /b 0)
if /I "!key!"=="LNX"    (endlocal & set "%~2=Linux" & exit /b 0)
if /I "!key!"=="LIN32"  (endlocal & set "%~2=Linux" & exit /b 0)
if /I "!key!"=="LIN64"  (endlocal & set "%~2=Linux" & exit /b 0)
if /I "!key!"=="DEBIAN" (endlocal & set "%~2=Linux" & exit /b 0)
if /I "!key!"=="ARCH"   (endlocal & set "%~2=Linux" & exit /b 0)
if /I "!key!"=="UBUNTU" (endlocal & set "%~2=Linux" & exit /b 0)

:: :: MacOS
:: if /I "!key!"=="MACOS"  (endlocal & set "%~2=macOS" & exit /b 0)
:: if /I "!key!"=="MAC"    (endlocal & set "%~2=macOS" & exit /b 0)
:: if /I "!key!"=="OSX"    (endlocal & set "%~2=macOS" & exit /b 0)
:: if /I "!key!"=="DARWIN" (endlocal & set "%~2=macOS" & exit /b 0)

endlocal & exit /b 1

:: Takes the target name or alias and converts it into conventional target name
:normalize_target
if /I "%~1"=="main"   (set "%~2=main" & exit /b 0)
if /I "%~1"=="client" (set "%~2=main" & exit /b 0)
exit /b 1

:canonical_optimization
setlocal EnableDelayedExpansion

set "key=%~1"
set "key=!key:.=!"
set "key=!key:_=!"
set "key=!key:-=!"

if /I "!key!"=="SSE"   (endlocal & set "%~2=SSE"    & exit /b 0)
if /I "!key!"=="SSE2"  (endlocal & set "%~2=SSE2"   & exit /b 0)
if /I "!key!"=="SSE41" (endlocal & set "%~2=SSE4_1" & exit /b 0)
if /I "!key!"=="AVX"   (endlocal & set "%~2=AVX"    & exit /b 0)

endlocal & exit /b 1

:: Takes the list of optimizations and normalizes it
:normalize_optimizations
setlocal EnableDelayedExpansion

set "result="

for %%F in (%~1) do (
    call :canonical_optimization "%%F" canon
    if errorlevel 1 (
        echo error: unrecognized optimization '%%F' 1>&2
        endlocal & exit /b 1
    )
    :: Check if already active
    echo:!result! | findstr /i /c:" !canon! " >nul
    if errorlevel 1 (
        if "!result!"=="" (
            set "result= !canon! "
        ) else (
            set "result=!result!!canon! "
        )
    )
)

:: Trim trailing/leading spaces gracefully
if not "!result!"=="" (
    set "result=!result:~1,-1!"
)

endlocal & set "%~2=%result%"
exit /b 0

:: Returns the prefix for the OS-specific files
:os_prefix
if /I "%~1"=="Windows" (set "%~2=win" & exit /b 0)
if /I "%~1"=="Linux"   (set "%~2=lin" & exit /b 0)
:: if /I "%~1"=="macOS"   (set "%~2=mac" & exit /b 0)
exit /b 1

:: Returns the NASM define identifier from the normalized OS name given
:os_define
if /I "%~1"=="Windows" (set "%~2=WINDOWS" & exit /b 0)
if /I "%~1"=="Linux"   (set "%~2=LINUX"   & exit /b 0)
:: if /I "%~1"=="macOS"   (set "%~2=MACOS"   & exit /b 0)
exit /b 1

:: Returns "0" if the filename is OS-specific (has OS-prefix)
:is_os_specific
setlocal

set "fn=%~1"

:: Windows-specific prefix
echo:%fn%| findstr /b /c:"win." >nul
if not errorlevel 1 (endlocal & exit /b 0)

:: Linux-specific prefix
echo:%fn%| findstr /b /c:"lin." >nul
if not errorlevel 1 (endlocal & exit /b 0)

:: :: macOS-specific prefix
:: echo:%fn%| findstr /b /c:"mac." >nul
:: if not errorlevel 1 (endlocal & exit /b 0)

endlocal & exit /b 1

:: ============================================================
::  Target registry
:: ============================================================

:: Checks if the target exists
:target_exists
setlocal

for %%T in (%ALL_TARGETS%) do (
    call :normalize_target "%~1" normed
    if not errorlevel 1 (
        if "%%T"=="!normed!" (endlocal & exit /b 0)
    )
)

endlocal & exit /b 1

:: Descriptions for target listing on 'build targets'
:target_description
if /I "%~1"=="main" (set "%~2=The main project binary" & exit /b 0)
exit /b 1

:: Libraries this target links against (see library below)
:: Uses local libraries' implementations in 'libs/'
:target_libraries
if /I "%~1"=="main" (set "%~2=window opengl" & exit /b 0)
exit /b 1

:: Dependencies for this target on other targets
:: Tells you exactly what other targets to compile before your main one
:target_dependencies
if /I "%~1"=="main" (set "%~2=" & exit /b 0)
exit /b 1

:: Files with actual entry points for the target
:target_entry
setlocal EnableDelayedExpansion

set "entries="
if /I "%~1"=="main" (
    set "entries=!entries! nasm/lin.entry.x64.code.asm"
    set "entries=!entries! nasm/win.entry.x64.code.asm"
)

:: Trim the leading space
if not "!entries!"=="" (set "entries=!entries:~1!") else (endlocal & exit /b 1)

endlocal & set "%~2=%entries%"
exit /b 0

:: Logical source files for this target
:: Contains relative paths omitting the 'src/<target>/'
:target_sources
setlocal EnableDelayedExpansion

set "sources="
if /I "%~1"=="main" (
    set "sources=!sources! nasm/com/mojang/rubydung/RubyDung.x64.code.asm"
    set "sources=!sources! nasm/com/mojang/rubydung/RubyDung.x64.data.asm"
)

:: Trim the leading space
if not "!sources!"=="" (set "sources=!sources:~1!") else (endlocal & exit /b 1)

endlocal & set "%~2=%sources%"
exit /b 0


:: ============================================================
::  Library registry
:: ============================================================

:: System libraries to link against
:link_libraries
if /I "%~1"=="Windows" (set "%~2=kernel32 user32 gdi32 opengl32" & exit /b 0)
if /I "%~1"=="Linux"   (set "%~2=X11 GL" & exit /b 0)
exit /b 1

:: Source files for a library on a given OS, relative to
:: '%LIBS_DIR%/<lib>/<main>/', since every lib-target is 'main'
:library_sources
setlocal EnableDelayedExpansion

set "sources="
if /I "%~1"=="opengl" (
    set "sources=!sources! nasm/win.opengl.x64.code.asm"
)
if /I "%~1"=="window" (
    set "sources=!sources! nasm/lin.window.x64.asm"
    set "sources=!sources! nasm/win.window.x64.asm"
)

:: Trim the leading space
if not "!sources!"=="" (set "sources=!sources:~1!") else (endlocal & exit /b 1)

endlocal & set "%~2=%sources%"
exit /b 0

:: Zig target OS
:zig_target
if /I "%~1"=="Windows" (set "%~2=x86_64-windows-gnu" & exit /b 0)
if /I "%~1"=="Linux"   (set "%~2=x86_64-linux-gnu"   & exit /b 0)
:: if /I "%~1"=="macOS"   (set "%~2=x86_64-macos-gnu"   & exit /b 0)
exit /b 1

:: Format for NASM assembly
:nasm_format
if /I "%~1"=="Windows" (set "%~2=win64"   & exit /b 0)
if /I "%~1"=="Linux"   (set "%~2=elf64"   & exit /b 0)
:: if /I "%~1"=="macOS"   (set "%~2=macho64" & exit /b 0)
exit /b 1

:: OS-specific entry-point
:entry_point
if /I "%~1"=="Windows" (set "%~2=win.entry" & exit /b 0)
if /I "%~1"=="Linux"   (set "%~2=lin.entry" & exit /b 0)
:: if /I "%~1"=="macOS"   (set "%~2=mac.entry" & exit /b 0)
exit /b 1

:: Object file extension
:object_extension
if /I "%~1"=="Windows" (set "%~2=obj" & exit /b 0)
if /I "%~1"=="Linux"   (set "%~2=o" & exit /b 0)
:: if /I "%~1"=="macOS"   (set "%~2=o" & exit /b 0)
exit /b 1

:: Execution file extension (for auto-generated output file names)
:execution_extension
if /I "%~1"=="Windows" (set "%~2=.exe" & exit /b 0)
if /I "%~1"=="Linux"   (set "%~2=" & exit /b 0)
:: if /I "%~1"=="macOS"   (set "%~2=" & exit /b 0)
exit /b 1


:: ============================================================
::  Build instruments
:: ============================================================

:require
where "%~1" >nul 2>&1
if errorlevel 1 (
    echo error: '%~1' was not found on PATH - install it ^(or fix PATH^) and try again 1>&2
    exit /b 1
)
exit /b 0

:: Assembles the file with given parameters
:assemble_file
setlocal EnableDelayedExpansion

set "filename=%~1"
set "build_dir=%~2"
set "includes=%~3"
set "target_arch=%~4"
set "target_os=%~5"
set "optimizations=%~6"
set "type=%~7"

set "tmp_filename=%filename%"

:: If it's the library file, we add the prefix to the output
if "%type%"=="library" (
    @rem Cut off %LIBS_DIR%
    set "tmp_filename=!tmp_filename:%LIBS_DIR%=!"
    @rem Extract library name
    for /f "tokens=1* delims=/" %%A in ("!tmp_filename!") do (
        set "output=libs/%%A/"
        set "tmp_filename=%%B"
    )
) else (
    set "output="
)

:: Get rid of "<source>/<target>/<lang>" by skipping first 3 tokens
for /f "tokens=3* delims=/" %%A in ("!tmp_filename!") do (
    set "tmp_filename=%%B"
)

set "package="

:: Check if path still contains "/"
echo:!tmp_filename!| findstr /c:"/" >nul
if not errorlevel 1 (
    @rem Get the absolute path of the current working directory (ends with a backslash)
    set "current_dir=%~dp0"

    @rem Convert forward slashes to backslashes temporarily for native Batch parsing
    set "fixed_path=!tmp_filename:/=\!"

    @rem Extract the filename and the absolute folder path cleanly
    for %%F in ("!fixed_path!") do (
        set "name=%%~nxF"
        set "dirpart=%%~dpF"
    )

    @rem Dynamically strip the current working directory path from 'dirpart'
    @rem This instantly isolates the relative folder structure
    for /f "delims=" %%A in ("!current_dir!") do (
        set "package=!dirpart:%%A=!"
    )

    @rem Convert the backslashes to dots and append the '@' symbol
    set "package=!package:\=.!"
    set "package=!package:~0,-1!@"
) else (
    set "name=!tmp_filename!"
)

:: Cut off extension
for %%F in ("!name!") do set "name=%%~nF"

call :object_extension "!target_os!" ext
set "output=!build_dir!tmp/!output!!package!!name!.!ext!"

set "def_optimizations="
for %%O in (%optimizations%) do (
    set "def_optimizations=!def_optimizations! -D%%O"
)

call :nasm_format "!target_os!" fmt
call :os_define   "!target_os!" osdef

:: Make sure output directory exists
for %%I in ("!output!") do if not exist "%%~dpI" mkdir "%%~dpI"

nasm -f !fmt! -i !includes! -D!target_arch! -D!osdef! !def_optimizations! "!filename!" -o "!output!"
if errorlevel 1 (endlocal & exit /b 1)

endlocal & set "%~8=%output%"
exit /b 0

:: Returns '0' if an array contains an item given
:array_contains
for %%I in (%~1) do (
    if "%%I"=="%~2" exit /b 0
)
exit /b 1

:: Returns the number of elements in space-separated array
:array_count
setlocal EnableDelayedExpansion

set "items=%~1"
set "count=0"

for %%I in (!items!) do (
    set /a count+=1
)

endlocal & set "%~2=%count%"
exit /b 0

:: Helper function for visiting the dependency tree node
:visit
setlocal EnableDelayedExpansion

set "target=%~1"
set "visiting_stack=%~2"

:: Skip if already fully processed and ordered
call :array_contains "!VISITED!" "!target!"
if not errorlevel 1 (endlocal & exit /b 0)
:: Detect cycle in current call stack
call :array_contains "!visiting_stack!" "!target!"
if not errorlevel 1 (
    echo [ERROR] Circular dependency detected involving target '!target!' 1>&2
    endlocal & exit /b 1
)

set "new_visiting=!visiting_stack! !target!"
call :target_dependencies "!target!" deps

for %%D in (!deps!) do (
    call :visit "%%D" "!new_visiting!"
    if errorlevel 1 (endlocal & exit /b 1)
)

set "RET_V=!VISITED! %target%"
set "RET_R=!RESULT! %target%"

endlocal & set "VISITED=%RET_V%" & set "RESULT=%RET_R%"
exit /b 0

:: Takes list of targets, and returns the list of all the dependencies with no repetitions
:dependency_flatten
setlocal EnableDelayedExpansion

set "VISITED="
set "RESULT="

for %%T in (%~1) do (
    call :visit "%%T" ""
    if errorlevel 1 (endlocal & exit /b 1)
)

:: Trim leading space
if not "!RESULT!"=="" set "RESULT=!RESULT:~1!"

endlocal & set "%~2=%RESULT%"
exit /b 0

:: Returns the list of libraries from the flattened dependency tree
:load_libraries
setlocal EnableDelayedExpansion

set "libraries="

for %%T in (%~1) do (
    call :target_libraries "%%T" libs

    for %%L in (!libs!) do (
        call :array_contains "!libraries!" "%%L"
        if errorlevel 1 (set "libraries=!libraries! %%L")
    )
)

endlocal & set "%~2=%libraries%"
exit /b 0

:: Takes list of sources, and filters them using the parameters
:filter_sources
setlocal EnableDelayedExpansion

set "prefix=%~1"
set "sources=%~2"
set "language=%~3"
set "target_arch=%~4"
set "target_os=%~5"
:: set "optimizations=%~6"

set "results="
call :os_prefix "%target_os%" os_pref

for %%S in (%sources%) do (
    set "source=%%S"

    @rem Check if language of the source match the requested one
    echo:!source!| findstr /b /c:"%language%/" >nul
    if not errorlevel 1 (
        for %%F in ("!source!") do set "filename=%%~nxF"

        call :is_os_specific "!filename!"
        if not errorlevel 1 (
            echo:!filename!| findstr /b /c:"!os_pref!." >nul

            if not errorlevel 1 (
                @rem Strip OS prefix for next check
                set "filename=!filename:*.=!"

                echo:!filename!| findstr /i /c:".%target_arch%." >nul
                if not errorlevel 1 (
                    set "results=!results! %prefix%!source!"
                )
            )
        ) else (
            echo:!filename!| findstr /i /c:".%target_arch%." >nul
            if not errorlevel 1 (
                set "results=!results! %prefix%!source!"
            )
        )
    )
)

:: Fail safe for empty strings
if not "!result!"=="" set "results=!results:~1!"

endlocal & set "%~7=%results%"
exit /b 0

:: Takes the (target, target_arch, target_os, optimizations, build_directory, sys_libs, output)
:: and builds the selected target
:target_build
setlocal EnableDelayedExpansion

set "TARGET=%~1"
set "TARGET_ARCH=%~2"
set "TARGET_OS=%~3"
set "OPTIMIZATIONS=%~4"
set "BUILD_DIRECTORY=%~5"
set "SYS_LIBS=%~6"
set "OUTPUT=%~7"

echo [INFO] Flattening the target dependency tree...

call :dependency_flatten "%TARGET%" dependencies
if errorlevel 1 (endlocal & exit /b 1)

echo [INFO] Resolving target libraries...

call :load_libraries "%dependencies%" libraries

set "lib_sources="
set "dep_sources="

echo [INFO] Resolving library source files...

for %%L in (%libraries%) do (
    call :library_sources "%%L" sources
    if errorlevel 1 (
        echo [ERROR] Apparently, '%%L' library is not in Library Registry 1>&2
        endlocal & exit /b 1
    )

    call :filter_sources "%LIBS_DIR%%%L/src/main/" "!sources!" "nasm" "%TARGET_ARCH%" "%TARGET_OS%" "%OPTIMIZATIONS%" filtered
    if not "!filtered!"=="" (
        set "lib_sources=!lib_sources! !filtered!"
        if not exist "%BUILD_DIRECTORY%tmp\libs\%%L\" mkdir "%BUILD_DIRECTORY%tmp\libs\%%L"
    )
)
:: Empty string failsafe
if not "!lib_sources!"=="" set "lib_sources=!lib_sources:~1!"

echo [INFO] Resolving target source files...

for %%T in (%dependencies%) do (
    call :target_sources "%%T" sources
    if errorlevel 1 (
        echo [ERROR] Apparently, '%%T' target is not in Target Registry 1>&2
        endlocal & exit /b 1
    )

    call :filter_sources "%SOURCE_DIR%%%T/" "!sources!" "nasm" "%TARGET_ARCH%" "%TARGET_OS%" "%OPTIMIZATIONS%" filtered
    if not "!filtered!"=="" set "dep_sources=!dep_sources! !filtered!"
)
:: Empty string failsafe
if not "!dep_sources!"=="" set "dep_sources=!dep_sources:~1!"

echo [INFO] Resolving the entry point code...

call :target_entry "%TARGET%" entry_raw
call :filter_sources "%SOURCE_DIR%%TARGET%/" "%entry_raw%" "nasm" "%TARGET_ARCH%" "%TARGET_OS%" "%OPTIMIZATIONS%" entry_sources

call :array_count "%lib_sources%" libs_count
call :array_count "%entry_sources%" entry_count
call :array_count "%dep_sources%" deps_count

set "lib_objs="
set "entry_objs="
set "dep_objs="

set "count=0"

:: Generate a true Escape character
for /F %%A in ('echo prompt $E ^| cmd') do set "ESC=%%A"

:: Library Sources Assembling
for %%S in (%lib_sources%) do (
    set /a count+=1
    <nul set /p ="!ESC![1G[STEP !count! / !libs_count!] Assembling library source files..."

    call :assemble_file "%%S" "%BUILD_DIRECTORY%" "%LIBS_INCLUDES%" "%TARGET_ARCH%" "%TARGET_OS%" "%OPTIMIZATIONS%" "library" obj
    if errorlevel 1 (endlocal & exit /b 1)

    set "lib_objs=!lib_objs! !obj!"
)
echo.
set "count=0"

:: Main Source Assembling
for %%S in (%dep_sources%) do (
    set /a count+=1
    <nul set /p ="!ESC![1G[STEP !count! / !deps_count!] Assembling target source files..."

    call :assemble_file "%%S" "%BUILD_DIRECTORY%" "%MAIN_INCLUDES%" "%TARGET_ARCH%" "%TARGET_OS%" "%OPTIMIZATIONS%" "main" obj
    if errorlevel 1 (endlocal & exit /b 1)

    set "dep_objs=!dep_objs! !obj!"
)
echo.
set "count=0"

:: Entry Sources Assembling
for %%S in (%entry_sources%) do (
    set /a count+=1
    <nul set /p ="!ESC![1G[STEP !count! / !entry_count!] Assembling target entry-point sources..."

    call :assemble_file "%%S" "%BUILD_DIRECTORY%" "%MAIN_INCLUDES%" "%TARGET_ARCH%" "%TARGET_OS%" "%OPTIMIZATIONS%" "entry" obj
    if errorlevel 1 (endlocal & exit /b 1)

    set "entry_objs=!entry_objs! !obj!"
)
echo.

call :link_libraries "%TARGET_OS%" sys_libs_raw
set "sys_libs_flags="
for %%L in (%sys_libs_raw%) do set "sys_libs_flags=!sys_libs_flags! -l%%L"

echo [INFO] Linking the object files...

call :zig_target "%TARGET_OS%" zig_tgt
call :entry_point "%TARGET_OS%" entry

zig cc -target "!zig_tgt!" -nostartfiles -nostdlib "-Wl,--entry=!entry!" "-Wl,--strip-all" %SYS_LIBS% -o "%BUILD_DIRECTORY%bin\%OUTPUT%" %lib_objs% %entry_objs% %dep_objs% %sys_libs_flags%
if errorlevel 1 (endlocal & exit /b 1)

echo [INFO] Saving executable as '%BUILD_DIRECTORY%bin/%OUTPUT%'...

endlocal & exit /b 0

:: ============================================================
::  Command handlers
:: ============================================================
:skip_functions

set "ALL_TARGETS=main"
set "DEFAULT_TARGET=main"
set "ALL_TESTS="

set "COMMAND=%~1"
if "%COMMAND%"=="" set "COMMAND=help"
if not "%~1"=="" shift

if /I "%COMMAND%"=="help"    goto :cmd_help
if /I "%COMMAND%"=="build"   goto :cmd_build
if /I "%COMMAND%"=="clean"   goto :cmd_clean
if /I "%COMMAND%"=="test"    goto :cmd_test
if /I "%COMMAND%"=="targets" goto :cmd_targets
if /I "%COMMAND%"=="tests"   goto :cmd_tests

echo error: unknown command '%COMMAND%' ^(try 'build help'^) 1>&2
exit /b 1


:cmd_help

:: There's more than one parameter for 'help'
if not "%~2"=="" (
    echo error: 'help' command takes only one parameter ^(try 'build help'^) 1>&2
    exit /b 1
)

set "topic=%~1"

if "%topic%"=="" (
    echo Assembly-Minecraft build script
    echo(
    echo Usage:
    echo   build help [^<topic^>]                 Print this manual, or detail for one topic
    echo   build clean [^<dir^>]                  Delete the build directory ^(default: '%BUILD_DIR%'^) and everything in it
    echo   build targets                        List available build targets
    echo   build tests                          List available tests
    echo   build build [^<target^>] [^<params^>]    Build the given target ^(default target if omitted^)
    echo   build test [^<tests^>]                 Build and run the given test^(-s^) ^(all tests if omitted^)
    echo(
    echo Parameters:
    echo   --build            directory to use as the build directory ^(default: '%BUILD_DIR%'^)
    echo   --optimizations    comma-separated CPU extension list, e.g. '--optimizations=sse4.2,avx512f'
    echo   --output, -o       output file name
    echo   --sys-libs         directory to use as the system includes when cross-compiling
    echo   --target-arch      target architecture to build for ^(x64; only option for now^)
    echo   --target-os        target OS to build for ^(Windows ^| Linux, default: Host OS^)
    echo(
    echo Run 'build help ^<topic^>' for more info"
    exit /b 0
)

:: Topics
if /I "%topic%"=="help" (
    echo Ugh...try 'build help', it already shows you everything...
    exit /b 0
)
if /I "%topic%"=="clean" (
    echo build clean [^<dir^>]    cleans the building directory by deleting it.
    echo                        By default the build directory is in '%BUILD_DIR%', but you can rewrite it with the optional parameter.
    exit /b 0
)
if /I "%topic%"=="targets" (
    echo build targets    lists all the available targets to build.
    echo                  Just try to run 'build targets'.
    exit /b 0
)
if /I "%topic%"=="tests" (
    echo build tests    lists all the available tests to run.
    echo                Just try to run 'build tests'.
    exit /b 0
)
if /I "%topic%"=="build" (
    echo build build [^<target^>] [^<params^>]    builds the target with the given parameters.
    echo                                      If target is omitted, the default one is used ^(default target: '%DEFAULT_TARGET%'^).
    echo                                      If parameters are omitted, the default ones are used.
    exit /b 0
)
if /I "%topic%"=="test" (
    echo build test [^<tests^>]    builds and runs the given test for the project.
    echo                         If tests are omitted, all tests are executed.
    exit /b 0
)

if /I "%topic%"=="--build" (
    echo --build  ^<dir^>    overrides the default build directory name for the target build ^(default: '%BUILD_DIR%'^).
    exit /b 0
)
if /I "%topic%"=="--optimizations" (
    echo --optimizations  ^<flags^>    comma-separated optimization names you're allowing the program to use.
    echo                             For "x64" it's the CPU extensions you're promising the program to have.
    echo                             By default '%BASE_OPTIMIZATIONS_x64%' extensions are available ^(project minimum^),
    echo                             all the optimizations are added, not replaced.
    exit /b 0
)
if /I "%topic%"=="--output" (
    echo --output  ^<filename^>    overrides the default binary name for the target being built.
    exit /b 0
)
if /I "%topic%"=="-o" (
    echo --output  ^<filename^>    overrides the default binary name for the target being built.
    exit /b 0
)
if /I "%topic%"=="--sys-libs" (
    echo --sys-libs  ^<dir^>    uses the directory as the system library include directory for linker
    echo                      in case you cross-compile the project for a platform other than your host one.
    exit /b 0
)
if /I "%topic%"=="--target-arch" (
    echo --target-arch  ^<x64^>    Architecture you're building the project for ^(aliases like "x86-64", "amd64" work^).
    echo                         The "x64" is the only supported value right now.
    exit /b 0
)
if /I "%topic%"=="--target-os" (
    echo --target-os  ^<Windows^|Linux^>    Operating System you're building the project for ^(aliases like "win64", "WIN" work^).
    echo                                 Defaults to the OS running this script ^(may be inaccurate, please use this parameter to specify the OS^).
    exit /b 0
)

echo error: no help manual for '%topic%'. Try 'build help'. 1>&2
exit /b 1


:cmd_clean

:: There's more than one parameter for 'clean'
if not "%~2"=="" (
    echo error: 'clean' command takes only one optional parameter ^(try 'build help clean' for more info^). 1>&2
    exit /b 1
)

set "target_dir=%~1"
if "%target_dir%"=="" set "target_dir=%BUILD_DIR%"

if exist "%target_dir%\" (
    rmdir /s /q "%target_dir%"
    echo Removed '%target_dir%' build directory
) else (
    echo Nothing to clean ^('%build_dir%' doesn't exist^)
)
exit /b 0


:cmd_targets

:: Targets don't need any parameters
if not "%~1"=="" (
    echo error: 'targets' command does not support any parameters ^(try 'build targets'^) 1>&2
    exit /b 1
)

echo Available targets:

for %%T in (%ALL_TARGETS%) do (
    call :target_description "%%T" desc

    @rem Padding formatting is limited in batch, doing a simple output
    echo   %%T    !desc!
)

echo Default target: %DEFAULT_TARGET%
exit /b 0


:cmd_tests

:: Tests don't need any parameters
if not "%~1"=="" (
    echo error: 'tests' command does not support any parameters ^(try 'build tests'^) 1>&2
    exit /b 1
)

:: There are no tests
if "%ALL_TESTS%"=="" (
    echo No tests available yet.
    exit /b 0
)

echo Available tests:
for %%T in (%ALL_TESTS%) do echo   %%T
exit /b 0


:cmd_test

:: There are no tests
if "%ALL_TESTS%"=="" (
    echo No tests to run yet - come back once there's something in 'tests/'.
    exit /b 0
)

echo error: named test running isn't wired up yet. 1>&2
exit /b 1


:cmd_build

set "OPT_TARGET="

set "OPT_BUILD_DIR="
set "OPT_SYS_LIBS="
set "OPT_TARGET_ARCH="
set "OPT_TARGET_OS="
set "OPT_OPTIMIZATIONS="
set "OPT_OUTPUT="

:: Get the parameters / target
:cmd_build_loop

if "%~1"=="" goto :cmd_build_exec
set "arg=%~1"

:: Build directory
:: --build[=<dir>]
if "!arg!"=="--build" (
    shift
    @rem We can't have a path
    if "%~2"=="" (
        echo error: no build directory was specified, although the parameter '!arg!' was mentioned 1>&2
        endlocal & exit /b 1
    )
    @rem If it's the file, we can't do nothing
    if exist "%~2" if not exist "%~2\" (
        echo error: can't use '%OPT_BUILD_DIR%' as the build directory, since it's a file 1>&2
        endlocal & exit /b 1
    )

    @rem Assign the 'OPT_BUILD' parameter
    call :opt_assign "OPT_BUILD_DIR" "%~2" "build directory"
    if errorlevel 1 (endlocal & exit /b 1)

    shift & goto :cmd_build_loop
)

:: Project optimizations
:: --optimizations[=<optimizations>]
if "!arg!"=="--optimizations" (
    shift
    @rem We can't have optimizations
    if "%~2"=="" (
        echo error: no optimizations was specified, although the parameter '!arg!' was mentioned 1>&2
        endlocal & exit /b 1
    )

    set "val=%~2"
    set "val=!val:,= !"

    @rem Assign the 'OPT_OPTIMIZATIONS' parameter
    call :opt_assign "OPT_OPTIMIZATIONS" "!val!" "optimizations"
    if errorlevel 1 (endlocal & exit /b 1)

    shift & goto :cmd_build_loop
)

:: Output file
:: --output/-o[=<output>]
if "!arg!"=="--output" (
    shift
    @rem We can't have a path
    if "%~2"=="" (
        echo error: no output file was specified, although the parameter '!arg!' was mentioned 1>&2
        endlocal & exit /b 1
    )
    @rem Can't rewrite a directory
    if exist "%~2\" (
        echo error: can't use '%~2' as output file, since it's a directory 1>&2
        endlocal & exit /b 1
    )

    @rem Assign the 'OPT_OUTPUT' parameter
    call :opt_assign "OPT_OUTPUT" "%~2" "output file"
    if errorlevel 1 (endlocal & exit /b 1)

    shift & goto :cmd_build_loop
)
if "!arg!"=="-o" (
    shift
    @rem We can't have a path
    if "%~2"=="" (
        echo error: no output file was specified, although the parameter '!arg!' was mentioned 1>&2
        endlocal & exit /b 1
    )
    @rem Can't rewrite a directory
    if exist "%~2\" (
        echo error: can't use '%~2' as output file, since it's a directory 1>&2
        endlocal & exit /b 1
    )

    @rem Assign the 'OPT_OUTPUT' parameter
    call :opt_assign "OPT_OUTPUT" "%~2" "output file"
    if errorlevel 1 (endlocal & exit /b 1)

    shift & goto :cmd_build_loop
)

:: System library include directory
:: --sys-libs[=<dir>]
if "!arg!"=="--sys-libs" (
    shift
    @rem We can't have a path
    if "%~2"=="" (
        echo error: no system libraries include directory was specified, although the parameter '--sys-libs' was mentioned 1>&2
        endlocal & exit /b 1
    )
    @rem We can't use unexisting directory
    if not exist "%~2\" (
        echo error: can't use '%~2' as the system libraries include directory, since it doesn't exist 1>&2
        endlocal & exit /b 1
    )

    @rem Assign the 'OPT_SYS_LIBS' parameter
    call :opt_assign "OPT_SYS_LIBS" "%~2" "system libraries include directory"
    if errorlevel 1 (endlocal & exit /b 1)

    shift & goto :cmd_build_loop
)

:: Target Architecture
:: --target-arch[=<arch>]
if "!arg!"=="--target-arch" (
    shift
    @rem We can't have an architecture
    if "%~2"=="" (
        echo error: no architecture was specified, although the parameter '--target-arch' was mentioned 1>&2
        endlocal & exit /b 1
    )

    @rem Normalize the architecture
    call :normalize_arch "%~2" normed
    if errorlevel 1 (
        echo error: unknown or unsupported architecture '%~2' 1>&2
        endlocal & exit /b 1
    )

    @rem Assign the 'OPT_TARGET_ARCH' parameter
    call :opt_assign "OPT_TARGET_ARCH" "!normed!" "target architecture"
    if errorlevel 1 (endlocal & exit /b 1)

    shift & goto :cmd_build_loop
)

:: Target OS
:: --target-os
if "!arg!"=="--target-os" (
    shift
    @rem We can't have
    if "%~2"=="" (
        echo error: no operating system was specified, although the parameter '--target-os' was mentioned 1>&2
        endlocal & exit /b 1
    )

    @rem Normalize the Operating System
    call :normalize_os "%~2" normed
    if errorlevel 1 (
        echo error: unknown or unsupported operating system '%~2' 1>&2
        endlocal & exit /b 1
    )

    @rem Assign the 'OPT_TARGET_OS' parameter
    call :opt_assign "OPT_TARGET_OS" "!normed!" "target operating system"
    if errorlevel 1 (endlocal & exit /b 1)

    shift & goto :cmd_build_loop
)

:: Unknown flag or target
echo:!arg!| findstr /b /c:"-" >nul
if not errorlevel 1 (
    echo error: unknown flag '!arg!' 1>&2
    exit /b 1
)

:: Target
if "%OPT_TARGET%"=="" (
    call :target_exists "!arg!"
    if errorlevel 1 (
        echo error: target '!arg!' specified does not exist 1>&2
        exit /b 1
    )

    set "OPT_TARGET=!arg!"

    shift & goto :cmd_build_loop
) else (
    call :target_exists "!arg!"
    if not errorlevel 1 (
        echo error: you already set the target to '%OPT_TARGET%', can't add '!arg!' as a second target. Try to build them separately 1>&2
    ) else (
        echo error: unexpected extra argument '!arg!' 1>&2
    )
    exit /b 1
)


:cmd_build_exec

if "%OPT_TARGET%"=="" set "OPT_TARGET=%DEFAULT_TARGET%"
call :normalize_target "%OPT_TARGET%" TARGET

if "%OPT_BUILD_DIR%"=="" set "OPT_BUILD_DIR=%BUILD_DIR%"
set "BUILD_DIRECTORY=%OPT_BUILD_DIR%"

set "SYS_LIBS="
if not "%OPT_SYS_LIBS%"=="" set "SYS_LIBS=-L %OPT_SYS_LIBS%"

if "%OPT_TARGET_ARCH%"=="" set "OPT_TARGET_ARCH=x64"
set "TARGET_ARCH=%OPT_TARGET_ARCH%"

if "%OPT_TARGET_OS%"=="" set "OPT_TARGET_OS=%HOST_OS%"
set "TARGET_OS=%OPT_TARGET_OS%"

set "RAW_OPTS=%BASE_OPTIMIZATIONS_x64% %OPT_OPTIMIZATIONS%"
call :normalize_optimizations "%RAW_OPTS%" OPTIMIZATIONS
if errorlevel 1 exit /b 1

call :execution_extension "%TARGET_OS%" exec_ext
if "%OPT_OUTPUT%"=="" set "OPT_OUTPUT=%TARGET%-%VERSION%%exec_ext%"
set "OUTPUT=%OPT_OUTPUT%"

:: Require the tools for assembling and linking
call :require "nasm" || exit /b 1
call :require "zig"  || exit /b 1

echo [INFO] Starting the '%TARGET%' target build...

:: If no building directory found
if not exist "%BUILD_DIRECTORY%\" (
    echo [INFO] Creating build directories...

    mkdir "%BUILD_DIRECTORY%tmp\"
    mkdir "%BUILD_DIRECTORY%bin\"
)

set "START_TIME=%TIME%"
call :time_to_seconds "%START_TIME%" s_start

:: Build the Target
call :target_build "%TARGET%" "%TARGET_ARCH%" "%TARGET_OS%" "%OPTIMIZATIONS%" "%BUILD_DIRECTORY%" "%SYS_LIBS%" "%OUTPUT%"
if errorlevel 1 exit /b 1

set "END_TIME=%TIME%"
call :time_to_seconds "%END_TIME%" s_end

set /a "ELAPSED=s_end - s_start"
if %ELAPSED% lss 0 set /a "ELAPSED+=86400"

echo [SUCCESS] Build completed successfully in %ELAPSED% seconds
exit /b 0


:: Helper to assign CLI arguments preventing duplicates
:opt_assign

:: The parameter is being reassigned
if not "!%~1!"=="" (
    echo error: ambiguous assignment. You tried to reassign the %~3, although it was already assigned to '!%~1!' 1>&2
    exit /b 1
)

set "%~1=%~2"
exit /b 0

:: Helper for elapsed time calculation
:time_to_seconds
setlocal EnableDelayedExpansion

set "t=%~1"
set "t=!t: =0!"

for /f "tokens=1-4 delims=:.," %%A in ("!t!") do (
    set /a "sec=(1%%A-100)*3600 + (1%%B-100)*60 + (1%%C-100)"
)

endlocal & set "%~2=%sec%"
exit /b 0
