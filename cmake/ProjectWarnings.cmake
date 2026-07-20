# ProjectWarnings.cmake — a private INTERFACE target carrying the project's
# warning policy.
#
# Only the project-owned `sdl_intro` target links `project_warnings`, so the
# strict flags (and optional warnings-as-errors) never propagate into the
# fetched SDL3, SDL3_image, SDL3_ttf, or transitive dependency sources.
#
# Usage:
#     target_link_libraries(sdl_intro PRIVATE project_warnings)

if(TARGET project_warnings)
    return()
endif()

option(SDL_INTRO_WARNINGS_AS_ERRORS "Treat project warnings as errors" ON)

add_library(project_warnings INTERFACE)

set(_project_gnu_like_warnings
    -Wall
    -Wextra
    -Wpedantic
    -Wshadow
    -Wconversion
    -Wsign-conversion
)

if(MSVC)
    target_compile_options(project_warnings INTERFACE /W4 /permissive-)
    if(SDL_INTRO_WARNINGS_AS_ERRORS)
        target_compile_options(project_warnings INTERFACE /WX)
    endif()
else()
    target_compile_options(project_warnings INTERFACE ${_project_gnu_like_warnings})
    if(SDL_INTRO_WARNINGS_AS_ERRORS)
        target_compile_options(project_warnings INTERFACE -Werror)
    endif()
endif()
