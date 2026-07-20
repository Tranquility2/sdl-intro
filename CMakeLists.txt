cmake_minimum_required(VERSION 3.21)

project(sdl_intro LANGUAGES C CXX)

# C++17 is the project baseline.
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# Default single-config builds to Release; multi-config generators pick per
# build.
if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
    set(CMAKE_BUILD_TYPE Release CACHE STRING "Build type" FORCE)
endif()

list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/cmake)

include(CTest)

option(SDL_INTRO_WARNINGS_AS_ERRORS "Treat project warnings as errors" ON)

# ---- Fetched dependency configuration --------------------------------------
# These must be set before FetchContent_MakeAvailable so the SDL projects pick
# them up. Build everything static and trim the extension libraries to only the
# formats/features this demo needs.
set(SDL_SHARED OFF CACHE BOOL "" FORCE)
set(SDL_STATIC ON CACHE BOOL "" FORCE)
set(SDL_TESTS OFF CACHE BOOL "" FORCE)
set(SDL_EXAMPLES OFF CACHE BOOL "" FORCE)
set(SDL_INSTALL OFF CACHE BOOL "" FORCE)

set(SDLIMAGE_VENDORED ON CACHE BOOL "" FORCE)
set(SDLIMAGE_DEPS_SHARED OFF CACHE BOOL "" FORCE)
set(SDLIMAGE_INSTALL OFF CACHE BOOL "" FORCE)
set(SDLIMAGE_SAMPLES OFF CACHE BOOL "" FORCE)
set(SDLIMAGE_TESTS OFF CACHE BOOL "" FORCE)
set(SDLIMAGE_PNG ON CACHE BOOL "" FORCE)
set(SDLIMAGE_PNG_LIBPNG ON CACHE BOOL "" FORCE)
foreach(_fmt ANI AVIF BMP GIF JPG JXL LBM PCX PNM QOI SVG TGA TIF WEBP XCF XPM XV)
    set(SDLIMAGE_${_fmt} OFF CACHE BOOL "" FORCE)
endforeach()

set(SDLTTF_VENDORED ON CACHE BOOL "" FORCE)
set(SDLTTF_INSTALL OFF CACHE BOOL "" FORCE)
set(SDLTTF_SAMPLES OFF CACHE BOOL "" FORCE)
set(SDLTTF_HARFBUZZ OFF CACHE BOOL "" FORCE)
set(SDLTTF_PLUTOSVG OFF CACHE BOOL "" FORCE)

include(Dependencies)

# ---- Project-owned policy targets ------------------------------------------
include(ProjectWarnings)
include(ProjectSanitizers)

# ---- Executable ------------------------------------------------------------
add_executable(sdl_intro src/main.cpp)
target_compile_features(sdl_intro PRIVATE cxx_std_17)
target_link_libraries(sdl_intro
    PRIVATE
        SDL3::SDL3
        SDL3_image::SDL3_image
        SDL3_ttf::SDL3_ttf
        project_warnings
        project_sanitizers
)

# Copy the assets next to the built executable so SDL_GetBasePath()/assets
# resolves at runtime.
add_custom_command(TARGET sdl_intro POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E make_directory
        $<TARGET_FILE_DIR:sdl_intro>/assets
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
        ${CMAKE_CURRENT_SOURCE_DIR}/assets/sdl-logo.png
        ${CMAKE_CURRENT_SOURCE_DIR}/assets/OpenSans-Regular.ttf
        $<TARGET_FILE_DIR:sdl_intro>/assets
    COMMENT "Copying assets next to sdl_intro"
    VERBATIM
)

# ---- Install ---------------------------------------------------------------
# Install the executable and the assets together so SDL_GetBasePath()/assets
# also works from an installed location.
install(TARGETS sdl_intro RUNTIME DESTINATION bin)
install(DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/assets DESTINATION bin)

# ---- Smoke test ------------------------------------------------------------
if(BUILD_TESTING)
    add_test(NAME intro-smoke COMMAND sdl_intro --smoke)
    set_tests_properties(intro-smoke PROPERTIES
        ENVIRONMENT "SDL_VIDEODRIVER=dummy"
        TIMEOUT 10
    )
endif()
