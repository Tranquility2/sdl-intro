# Dependencies.cmake — pinned FetchContent declarations for SDL3, SDL3_image,
# and SDL3_ttf.
#
# The extension libraries are fetched from their official libsdl-org
# repositories and pinned to full commit hashes for reproducibility. They are
# built statically (SDL_STATIC / vendored deps) so desktop users do not need
# separately installed SDL runtime libraries.

include(FetchContent)

FetchContent_Declare(
    SDL3
    GIT_REPOSITORY https://github.com/libsdl-org/SDL.git
    GIT_TAG f87239e71e42da91ca317a12eefb82cfbf3393eb  # release-3.4.12
    GIT_SHALLOW FALSE
)

FetchContent_Declare(
    SDL3_image
    GIT_REPOSITORY https://github.com/libsdl-org/SDL_image.git
    GIT_TAG bec9134a26c7d0f31b36d6083c25296e04cabff5  # release-3.4.4
    GIT_SHALLOW FALSE
)

FetchContent_Declare(
    SDL3_ttf
    GIT_REPOSITORY https://github.com/libsdl-org/SDL_ttf.git
    GIT_TAG a1ce3670aec736ecbf0936c43f2f0cc53aa61e5b  # release-3.2.2
    GIT_SHALLOW FALSE
)

# Force static builds for the fetched dependencies regardless of the caller's
# BUILD_SHARED_LIBS, then restore the caller's value immediately afterwards.
set(_sdl_intro_saved_shared_libs ${BUILD_SHARED_LIBS})
set(BUILD_SHARED_LIBS OFF CACHE BOOL "" FORCE)

FetchContent_MakeAvailable(SDL3 SDL3_image SDL3_ttf)

set(BUILD_SHARED_LIBS ${_sdl_intro_saved_shared_libs} CACHE BOOL "" FORCE)
unset(_sdl_intro_saved_shared_libs)
