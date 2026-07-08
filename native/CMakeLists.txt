# Builds the on-device ML engines as two shared libraries:
#   libdiktafon_whisper.so — dk_whisper shim + whisper.cpp   (M2, D2)
#   libdiktafon_llama.so   — dk_llama shim + llama.cpp        (M3, D3)
# ggml (CPU backend) is built once from llama.cpp's tree and statically
# linked into both. Consumed by the Flutter Linux runner build and by the
# Android externalNativeBuild (see native/README.md).
cmake_minimum_required(VERSION 3.22)
project(diktafon_native LANGUAGES C CXX)

set(CMAKE_POSITION_INDEPENDENT_CODE ON)

# Static engines folded into our shared libraries. (Cache-forced:
# upstream declares BUILD_SHARED_LIBS as an option defaulting to ON.)
set(BUILD_SHARED_LIBS OFF CACHE BOOL "" FORCE)
set(WHISPER_BUILD_TESTS    OFF CACHE BOOL "" FORCE)
set(WHISPER_BUILD_EXAMPLES OFF CACHE BOOL "" FORCE)
set(WHISPER_BUILD_SERVER   OFF CACHE BOOL "" FORCE)
set(LLAMA_BUILD_COMMON     OFF CACHE BOOL "" FORCE)
set(LLAMA_BUILD_TESTS      OFF CACHE BOOL "" FORCE)
set(LLAMA_BUILD_TOOLS      OFF CACHE BOOL "" FORCE)
set(LLAMA_BUILD_EXAMPLES   OFF CACHE BOOL "" FORCE)
set(LLAMA_BUILD_SERVER     OFF CACHE BOOL "" FORCE)
set(LLAMA_BUILD_APP        OFF CACHE BOOL "" FORCE)

# llama.cpp must come first: it defines the `ggml` target that whisper.cpp
# then reuses via its `if (NOT TARGET ggml)` guard. Both vendored trees pin
# ggml 0.15.1 (whisper v1.9.1 2026-06-19, llama b9700 2026-06-18).
add_subdirectory(llama.cpp EXCLUDE_FROM_ALL)
add_subdirectory(whisper.cpp EXCLUDE_FROM_ALL)

add_library(diktafon_whisper SHARED src/dk_whisper.cpp)
target_link_libraries(diktafon_whisper PRIVATE whisper)

add_library(diktafon_llama SHARED src/dk_llama.cpp)
target_link_libraries(diktafon_llama PRIVATE llama)

set_target_properties(diktafon_whisper diktafon_llama PROPERTIES
  C_VISIBILITY_PRESET hidden
  CXX_VISIBILITY_PRESET hidden
)

# The engines must stay fast in app *debug* builds too (Flutter debug ⇒ CMake
# Debug ⇒ no optimization ⇒ ~20× slower inference). Nobody debugs engine
# internals through the app build, so always optimize these targets.
foreach(engine_target ggml ggml-base ggml-cpu whisper llama
        diktafon_whisper diktafon_llama)
  if(TARGET ${engine_target})
    target_compile_options(${engine_target} PRIVATE $<$<CONFIG:Debug>:-O2>)
  endif()
endforeach()
