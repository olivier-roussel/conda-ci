setlocal EnableDelayedExpansion
@echo on

cd build

if [%PKG_NAME%] == [libsofa-core] (
    REM only the libraries (don't copy CMake metadata)
    REM XXX move to xcopy instead ?
    move temp_prefix\lib\Sofa* %LIBRARY_LIB%
    REM dll's go to LIBRARY_BIN
    move temp_prefix\bin\Sofa*.dll %LIBRARY_BIN%
    REM and plugins libraries
    cd temp_prefix\plugins
    for /D %%G in (*) do (
      mkdir %LIBRARY_PREFIX%\plugins\%%G\lib
      xcopy /y %%G\lib\*.lib %LIBRARY_PREFIX%\plugins\%%G\lib
      mkdir %LIBRARY_PREFIX%\plugins\%%G\bin
      xcopy /y %%G\bin\*.dll %LIBRARY_PREFIX%\plugins\%%G\bin
    )
    cd ..\..
) else if [%PKG_NAME%] == [libsofa-core-devel] (
    REM headers
    robocopy temp_prefix\include %LIBRARY_INC% /E >nul
    REM CMake metadata
    mkdir %LIBRARY_LIB%\cmake
    robocopy temp_prefix\lib\cmake %LIBRARY_LIB%\cmake /E >nul
    echo "============================="
    echo "===== files in source: temp_prefix\lib\cmake"
    echo "============================="
    dir temp_prefix\lib\cmake /A-D /S /B
    echo "============================="
    dir temp_prefix\lib\cmake /b /s
    echo "============================="
    dir temp_prefix\lib /b
    echo "============================="
    dir temp_prefix /b
    echo "============================="
    echo "===== files in dest: %LIBRARY_LIB%\cmake"
    echo "============================="
    dir %LIBRARY_LIB%\cmake /A-D /S /B
    echo "============================="
    echo "============================="
    REM and plugins
    cd temp_prefix\plugins
    for /D %%G in (*) do (
      REM headers
      mkdir %LIBRARY_PREFIX%\plugins\%%G\include
      xcopy /e /y %%G\include %LIBRARY_PREFIX%\plugins\%%G\include
      REM CMake metadata
      mkdir %LIBRARY_PREFIX%\plugins\%%G\lib\cmake
      xcopy /e /y %%G\lib\cmake %LIBRARY_PREFIX%\plugins\%%G\lib\cmake
    )
    cd ..\..
) else (
    echo "Invalid package to install"
    exit 1
)