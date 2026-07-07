# Builds libdiktafon_whisper.so: the dk_whisper shim with whisper.cpp + ggml
# (CPU backend) statically linked in. Consumed by the Flutter Linux runner
# build and by the Android externalNativeBuild (see native/README.md).
cmake_minimum_required(VERSION 3.22)
project(diktafon_native LANGUAGES C CXX)

set(CMAKE_POSITION_INDEPENDENT_CODE ON)

# Static whisper/ggml folded into our single shared library. (Cache-forced:
# upstream declares BUILD_SHARED_LIBS as an option defaulting to ON.)
set(BUILD_SHARED_LIBS OFF CACHE BOOL "" FORCE)
set(WHISPER_BUILD_TESTS    OFF CACHE BOOL "" FORCE)
set(WHISPER_BUILD_EXAMPLES OFF CACHE BOOL "" FORCE)
set(WHISPER_BUILD_SERVER   OFF CACHE BOOL "" FORCE)

add_subdirectory(whisper.cpp EXCLUDE_FROM_ALL)

add_library(diktafon_whisper SHARED src/dk_whisper.cpp)
target_link_libraries(diktafon_whisper PRIVATE whisper)
set_target_properties(diktafon_whisper PROPERTIES
  C_VISIBILITY_PRESET hidden
  CXX_VISIBILITY_PRESET hidden
)

# The engine must stay fast in app *debug* builds too (Flutter debug ⇒ CMake
# Debug ⇒ no optimization ⇒ ~20× slower inference). Nobody debugs whisper
# internals through the app build, so always optimize these targets.
foreach(engine_target ggml ggml-base ggml-cpu whisper diktafon_whisper)
  if(TARGET ${engine_target})
    target_compile_options(${engine_target} PRIVATE $<$<CONFIG:Debug>:-O2>)
  endif()
endforeach()
