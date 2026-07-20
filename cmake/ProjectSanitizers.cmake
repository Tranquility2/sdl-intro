# ProjectSanitizers.cmake — project-only sanitizer policy.
#
# SDL_INTRO_SANITIZE is a semicolon-separated list, for example
# "address;undefined". The asan-ubsan preset sets it; a normal build leaves it
# empty and this module produces an INTERFACE target with no flags.
#
# The flags are carried on the `project_sanitizers` INTERFACE target which is
# linked PRIVATE only to `sdl_intro`, so the fetched SDL dependencies are never
# instrumented.
#
# Usage:
#     target_link_libraries(sdl_intro PRIVATE project_sanitizers)

if(TARGET project_sanitizers)
    return()
endif()

set(SDL_INTRO_SANITIZE "" CACHE STRING
    "Semicolon-separated sanitizers to enable for sdl_intro (e.g. address;undefined)")

add_library(project_sanitizers INTERFACE)

if(NOT SDL_INTRO_SANITIZE)
    return()
endif()

set(_project_supported_sanitizers address undefined)
foreach(_sanitizer IN LISTS SDL_INTRO_SANITIZE)
    if(NOT _sanitizer IN_LIST _project_supported_sanitizers)
        message(FATAL_ERROR
            "SDL_INTRO_SANITIZE contains unsupported sanitizer '${_sanitizer}'. "
            "Supported values: ${_project_supported_sanitizers}.")
    endif()
endforeach()

if(MSVC)
    message(FATAL_ERROR
        "SDL_INTRO_SANITIZE is only supported with GCC and Clang in version 1.")
endif()

message(STATUS "Project sanitizers enabled for sdl_intro: ${SDL_INTRO_SANITIZE}")

string(REPLACE ";" "," _project_sanitize_csv "${SDL_INTRO_SANITIZE}")
target_compile_options(project_sanitizers INTERFACE
    -fsanitize=${_project_sanitize_csv}
    -fno-sanitize-recover=all
    -fno-omit-frame-pointer
    -g
)
target_link_options(project_sanitizers INTERFACE
    -fsanitize=${_project_sanitize_csv}
)
