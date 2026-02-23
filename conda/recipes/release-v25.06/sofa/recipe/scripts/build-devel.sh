#!/bin/bash
set -ex

if [[ $target_platform == osx* ]] ; then
    # Dealing with modern C++ for Darwin in embedded catch library.
    # See https://conda-forge.org/docs/maintainer/knowledge_base.html#newer-c-features-with-old-sdk
    CXXFLAGS="${CXXFLAGS} -D_LIBCPP_DISABLE_AVAILABILITY"
fi

rm -rf build

mkdir build
cd build

if [[ $target_platform =~ emscripten.* ]]; then
  export CONDA_BUILD_CROSS_COMPILATION="1"
  # PYTHON_EXECUTABLE=$BUILD_PREFIX/bin/python$PY_VER
  # echo "set_property(GLOBAL PROPERTY TARGET_SUPPORTS_SHARED_LIBS TRUE)"> $SRC_DIR/__vinca_shared_lib_patch.cmake
  # echo "set(CMAKE_STRIP FALSE)  # used by default in pybind11 on .so modules">> $SRC_DIR/__vinca_shared_lib_patch.cmake
  # echo "set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE BOTH)  # fixes an error where numpy header files are not found correctly">> $SRC_DIR/__vinca_shared_lib_patch.cmake


  # echo "set(CMAKE_SHARED_LIBRARY_CREATE_C_FLAGS \"-s ASSERTIONS=1 -s SIDE_MODULE=1 -sWASM_BIGINT -s USE_PTHREADS=0 -s ALLOW_MEMORY_GROWTH=1 -s DEMANGLE_SUPPORT=1 \")">> $SRC_DIR/__vinca_shared_lib_patch.cmake
  # echo "set(CMAKE_SHARED_LIBRARY_CREATE_CXX_FLAGS \"-s ASSERTIONS=1 -s SIDE_MODULE=1 -sWASM_BIGINT -s USE_PTHREADS=0 -s ALLOW_MEMORY_GROWTH=1 -s DEMANGLE_SUPPORT=1 \")">> $SRC_DIR/__vinca_shared_lib_patch.cmake
  # echo "set(CMAKE_EXE_LINKER_FLAGS \"-sMAIN_MODULE=1 -sASSERTIONS=1 -fexceptions -lembind -sWASM_BIGINT -s USE_PTHREADS=0 -sALLOW_MEMORY_GROWTH=1 -s DEMANGLE_SUPPORT=1 -L$SRC_DIR/build -L$PREFIX/lib\")  # remove SIDE_MODULE from exe linker flags">> $SRC_DIR/__vinca_shared_lib_patch.cmake

  echo "set_property(GLOBAL PROPERTY TARGET_SUPPORTS_SHARED_LIBS TRUE)" > $SRC_DIR/overwriteProp.cmake  # does not need to be global :)
  echo "set(CMAKE_SHARED_LIBRARY_CREATE_C_FLAGS \"-s SIDE_MODULE=1\")" >> $SRC_DIR/overwriteProp.cmake
  echo "set(CMAKE_SHARED_LIBRARY_CREATE_CXX_FLAGS \"-s SIDE_MODULE=1\")" >> $SRC_DIR/overwriteProp.cmake
  echo "set(CMAKE_STRIP FALSE)  # used by default in pybind11 on .so modules, only for needed when using pybind11" >> $SRC_DIR/overwriteProp.cmake

  export BUILD_TYPE="Debug"
  export EXTRA_CMAKE_ARGS=" \
      -DPYTHON_SOABI="cpython-${ROS_PYTHON_VERSION//./}-wasm32-emscripten" \
      -DCMAKE_FIND_ROOT_PATH=$PREFIX \
      -DCMAKE_POSITION_INDEPENDENT_CODE=TRUE \
      -DCMAKE_PROJECT_INCLUDE=$SRC_DIR/overwriteProp.cmake \
  "

  unset -f cmake
  export CMAKE_GEN="emcmake cmake"
  export CMAKE_BLD="cmake"
else
  export BUILD_TYPE="Release"
  export CMAKE_GEN="cmake"
  export CMAKE_BLD="cmake"
fi;

${CMAKE_GEN} ${CMAKE_ARGS} \
  -B . \
  -S .. \
  -DCMAKE_BUILD_TYPE:STRING=Release \
  -DSOFA_ALLOW_FETCH_DEPENDENCIES=OFF \
  --preset conda-core

# build
${CMAKE_GEN} --build . --parallel ${CPU_COUNT}

# install
${CMAKE_GEN} --build . --parallel ${CPU_COUNT} --target install