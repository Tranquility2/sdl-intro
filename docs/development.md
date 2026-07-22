# Development guide

Authoritative technical reference for building, testing, and cross-compiling
**SDL Intro**. For the project overview see the [README](../README.md).

CMake is the single source of build logic: [`CMakeLists.txt`](../CMakeLists.txt)
and [`CMakePresets.json`](../CMakePresets.json) own every flag, dependency, and
platform decision. The [`Makefile`](../Makefile) is a thin convenience wrapper
with no build logic of its own.

## Prerequisites

- **CMake** 3.21 or newer
- **Ninja** (Linux and macOS presets)
- A compiler toolchain:
  - **GCC** on Linux
  - **AppleClang** on macOS
  - **Visual Studio 2022 / MSVC** on Windows
  - **MinGW-w64** for the Linux→Windows cross-build
- A network connection on the first configure. SDL3, SDL3_image, and SDL3_ttf
  are fetched via CMake `FetchContent` and statically linked, so no system SDL
  runtime is required.

### Linux packages

SDL's X11/Wayland/GL/audio development headers are required to build on Linux.
On Debian/Ubuntu:

```sh
sudo apt-get install -y ninja-build \
  libx11-dev libxext-dev libxrandr-dev libxcursor-dev libxi-dev \
  libxfixes-dev libxss-dev libxtst-dev libwayland-dev \
  libxkbcommon-dev wayland-protocols libegl1-mesa-dev \
  libgl1-mesa-dev libgles2-mesa-dev libpulse-dev libasound2-dev
```

For the MinGW cross-build, install the cross toolchain instead (or in
addition):

```sh
sudo apt-get install -y ninja-build \
  gcc-mingw-w64-x86-64 g++-mingw-w64-x86-64
```

## Presets

All presets are defined in [`CMakePresets.json`](../CMakePresets.json).

| Preset                 | Host          | Generator              | Build type | Notes                              |
| ---------------------- | ------------- | ---------------------- | ---------- | ---------------------------------- |
| `debug`                | Linux / macOS | Ninja                  | Debug      |                                    |
| `release`              | Linux / macOS | Ninja                  | Release    |                                    |
| `asan-ubsan`           | Linux / macOS | Ninja                  | Debug      | AddressSanitizer + UBSan           |
| `windows-msvc-debug`   | Windows       | Visual Studio 17 2022 (x64) | Debug |                                    |
| `windows-msvc-release` | Windows       | Visual Studio 17 2022 (x64) | Release |                                    |
| `mingw-release`        | Linux         | Ninja                  | Release    | Cross-compiles to Windows x86_64   |
| `web-release`          | Linux / macOS | Unix Makefiles         | Release    | Emscripten/WebAssembly (needs emsdk)|

The Unix presets carry a host condition that excludes Windows, and the MSVC
presets carry the inverse condition, so `cmake --list-presets` only offers the
presets valid for the current host. `SDL_INTRO_WARNINGS_AS_ERRORS` is `ON` for
every preset.

## Build, run, and test

Using CMake presets directly:

```sh
# Linux / macOS
cmake --preset release
cmake --build --preset release
ctest --preset release          # runs the headless smoke test
./build/release/sdl_intro       # run the interactive demo

# Windows (Visual Studio 17 2022, x64)
cmake --preset windows-msvc-release
cmake --build --preset windows-msvc-release
ctest --preset windows-msvc-release
```

Each preset builds into `build/<presetName>/`.

### Makefile targets

The [`Makefile`](../Makefile) wraps the presets. `PRESET` defaults to `debug`;
override it with `PRESET=release` (etc.).

| Target           | Action                                                        |
| ---------------- | ------------------------------------------------------------- |
| `make configure` | Configure with the `$(PRESET)` preset                         |
| `make build`     | Build the `$(PRESET)` preset (configures first)               |
| `make run`       | Build and run `./build/$(PRESET)/sdl_intro`                   |
| `make test`      | Run the CTest smoke test for the `$(PRESET)` preset           |
| `make sanitize`  | Configure, build, and test the `asan-ubsan` preset            |
| `make mingw`     | Cross-build a static Windows `.exe` with MinGW-w64            |
| `make web`       | Build the WebAssembly bundle in Docker into `build/web-dist`  |
| `make web-serve` | Serve `build/web-dist` over HTTP for browser review          |
| `make clean`     | Remove the `build/` directory                                 |
| `make help`      | List the available targets                                    |

## Sanitizers (ASan/UBSan)

The `asan-ubsan` preset sets `SDL_INTRO_SANITIZE=address;undefined` (a Debug
build). Sanitizer flags live on the `project_sanitizers` INTERFACE target in
[`cmake/ProjectSanitizers.cmake`](../cmake/ProjectSanitizers.cmake) and are
linked **PRIVATE only to `sdl_intro`**, so the fetched SDL dependencies are
never instrumented. Enabled flags are `-fsanitize=address,undefined`,
`-fno-sanitize-recover=all`, `-fno-omit-frame-pointer`, and `-g`. Only
`address` and `undefined` are accepted; MSVC is rejected with a fatal error.

The `asan-ubsan` test preset runs with fail-fast options:

```
ASAN_OPTIONS=halt_on_error=1:abort_on_error=1:detect_leaks=1:print_stacktrace=1
UBSAN_OPTIONS=halt_on_error=1:print_stacktrace=1
```

Run everything in one step with `make sanitize`.

## Smoke test

`sdl_intro --smoke` runs deterministically without a desktop session. It
initializes SDL video and SDL3_ttf, decodes `assets/sdl-logo.png`, opens
`assets/OpenSans-Regular.ttf`, renders the title to a surface, cleans up, and
exits `0` — without creating a renderer or entering the render loop.

CTest registers it as `intro-smoke` in [`CMakeLists.txt`](../CMakeLists.txt)
with `SDL_VIDEODRIVER=dummy` and a 10-second timeout. It is the test invoked by
every `ctest --preset ...` command above.

## Warnings

Warning policy lives on the `project_warnings` INTERFACE target in
[`cmake/ProjectWarnings.cmake`](../cmake/ProjectWarnings.cmake), linked
**PRIVATE only to `sdl_intro`** so strict flags never propagate into the fetched
SDL sources.

- **GCC/Clang:** `-Wall -Wextra -Wpedantic -Wshadow -Wconversion
  -Wsign-conversion`, plus `-Werror` when `SDL_INTRO_WARNINGS_AS_ERRORS` is `ON`.
- **MSVC:** `/W4 /permissive-`, plus `/WX` when warnings-as-errors is `ON`.

## Dependencies (pinned)

All three libraries are fetched from the official `libsdl-org` repositories via
`FetchContent`, pinned to full commit hashes, and statically linked. See
[`cmake/Dependencies.cmake`](../cmake/Dependencies.cmake).

| Library    | Release  | Commit                                     |
| ---------- | -------- | ------------------------------------------ |
| SDL3       | `3.4.12` | `f87239e71e42da91ca317a12eefb82cfbf3393eb` |
| SDL3_image | `3.4.4`  | `bec9134a26c7d0f31b36d6083c25296e04cabff5` |
| SDL3_ttf   | `3.2.2`  | `a1ce3670aec736ecbf0936c43f2f0cc53aa61e5b` |

Minimal feature configuration (set in [`CMakeLists.txt`](../CMakeLists.txt)
before `FetchContent_MakeAvailable`):

- Everything is built **static** (`SDL_SHARED=OFF`, `SDL_STATIC=ON`); tests,
  examples, and installs for the fetched projects are disabled.
- **SDL3_image**: vendored, **PNG only** (`SDLIMAGE_PNG` /
  `SDLIMAGE_PNG_LIBPNG` on; every other format off).
- **SDL3_ttf**: vendored, built **without HarfBuzz or PlutoSVG**
  (`SDLTTF_HARFBUZZ=OFF`, `SDLTTF_PLUTOSVG=OFF`), because the demo renders fixed
  basic-Latin text.

`Dependencies.cmake` forces `BUILD_SHARED_LIBS=OFF` around
`FetchContent_MakeAvailable` and restores the caller's value afterward.

## Assets: lookup, copy, and install

At runtime the app resolves assets next to the executable via
`SDL_GetBasePath()`, joining `assets/<filename>` (see `AssetPath` in
[`src/main.cpp`](../src/main.cpp)), so loading works regardless of the current
working directory.

To make that path valid, [`CMakeLists.txt`](../CMakeLists.txt):

- Runs a `POST_BUILD` custom command that creates
  `$<TARGET_FILE_DIR:sdl_intro>/assets` and copies `sdl-logo.png` and
  `OpenSans-Regular.ttf` next to the built binary (`copy_if_different`).
- Installs the executable to `bin/` and the `assets/` directory to `bin/assets`
  so `SDL_GetBasePath()/assets` also resolves from an installed location.

## Application lifecycle

The demo uses SDL3's main callbacks (`SDL_MAIN_USE_CALLBACKS`) rather than a
hand-written `main` loop. All mutable SDL resources live in an `AppState` struct
that travels through SDL's `appstate` pointer — there are no global window or
renderer handles. See [`src/main.cpp`](../src/main.cpp).

- `SDL_AppInit` — parses `--smoke`, initializes SDL video and SDL3_ttf, loads
  the logo and font, and renders the title surface. In smoke mode it cleans up
  and returns `SDL_APP_SUCCESS` before any window/renderer is created; otherwise
  it creates the window and renderer, builds textures, and returns
  `SDL_APP_CONTINUE`.
- `SDL_AppIterate` — queries the current renderer output size, advances and
  clamps the bouncing logo within those live bounds with delta-time (clamped to
  avoid teleporting on stalls), centers the title, draws, and presents. This
  keeps browser fullscreen and other output-size changes correct.
- `SDL_AppEvent` — exits cleanly on quit or the **Escape** key.
- `SDL_AppQuit` — destroys textures, font, renderer, and window, quits TTF, and
  frees `AppState`. SDL calls `SDL_Quit()` itself afterward.

The window is 720×480; the title is rendered with Open Sans at 28 px.

## MinGW-w64 cross-build (Linux → Windows)

Cross-compile a self-contained Windows x86_64 executable from Linux:

```sh
cmake --preset mingw-release
cmake --build --preset mingw-release
# or simply:
make mingw
```

The `mingw-release` preset (a Ninja Release build) points CMake at the toolchain
file [`cmake/toolchains/mingw-w64-x86_64.cmake`](../cmake/toolchains/mingw-w64-x86_64.cmake),
which:

- Sets `CMAKE_SYSTEM_NAME=Windows`, `CMAKE_SYSTEM_PROCESSOR=x86_64`.
- Uses the `x86_64-w64-mingw32` toolchain (`-gcc`, `-g++`, `-windres`). Override
  with `-DMINGW_TARGET_TRIPLE=...` for differently named distro toolchains.
- Searches target headers/libraries under `/usr/x86_64-w64-mingw32` while
  keeping host programs discoverable.
- Links `-static -static-libgcc -static-libstdc++` so the resulting `.exe`
  depends on no MinGW runtime DLLs — matching the project's static-SDL
  philosophy.

The build produces `build/mingw-release/sdl_intro.exe` with the runtime assets
copied to `build/mingw-release/assets/`. The `.exe` uses the Windows GUI
subsystem, so launching it does not open a second console window. It targets
Windows and does not run on the Linux host.

## WebAssembly build (Emscripten)

The app builds to WebAssembly and runs unchanged in a browser: SDL3 3.4.12
supports Emscripten and the `SDL_MAIN_USE_CALLBACKS` application needs no source
changes. On Emscripten `SDL_GetBasePath()` returns `/`, so the assets are
packaged into the virtual filesystem at `/assets` and the existing
`assets/<file>` lookup resolves unchanged.

The `web-release` preset uses **Unix Makefiles** (the official Emscripten
container ships no Ninja) and the emsdk CMake toolchain at
`$env{EMSDK}/upstream/emscripten/cmake/Modules/Platform/Emscripten.cmake`. The
Emscripten target block in [`CMakeLists.txt`](../CMakeLists.txt) applies, only to
`sdl_intro`:

- `SUFFIX ".html"` so the build emits a runnable HTML shell.
- `-sALLOW_MEMORY_GROWTH=1`.
- `-sEXPORTED_RUNTIME_METHODS=requestFullscreen` so the custom shell can call
  `Module.requestFullscreen(false, false)`.
- `--preload-file <source>/assets@/assets` to package the assets.
- `--shell-file <source>/web/shell.html` to render the bundle inside the
  project-owned presentation shell instead of Emscripten's default template.

Native `POST_BUILD` asset copying and the install rules are guarded off for
Emscripten; web assets come only from preload packaging.

### Presentation shell (`web/shell.html`)

[`web/shell.html`](../web/shell.html) is the project-owned Emscripten shell that
Emscripten expands at link time, substituting its generated loader for the
required `{{{ SCRIPT }}}` placeholder. It is a single self-contained HTML5
document with all CSS and JavaScript inline — no external fonts, stylesheets,
scripts, or analytics — and it deliberately omits Emscripten's default branding
and console textarea. Its structure is:

- A centered header (`SDL Intro` plus the subtitle *A minimal SDL3 C++ demo
  running in WebAssembly.*) over a dark background matching the application's
  render clear color.
- A `.demo-card` holding a `role="status"` element, the
  `#canvas` element (720×480 logical resolution), and a `#fullscreen` button.
  The canvas is **responsive** — it scales to `min(100%, 720px)` wide with a
  fixed `3 / 2` aspect ratio and a visible keyboard-focus outline — so the demo
  fits narrow viewports without distortion.
- A footer with visible attribution: links to the GitHub source and
  `THIRD_PARTY_NOTICES.md`, the Open Sans Apache-2.0 notice, and the SDL
  trademark / non-affiliation disclaimer.

Runtime behavior is driven by a `Module` object defined before the placeholder:

- `Module.canvas` binds the SDL surface to `#canvas`; `print`/`printErr` forward
  to `console.log`/`console.error`.
- `setStatus(text)` shows non-empty **loading text** and hides the status
  element when empty; `monitorRunDependencies(left)` reports remaining downloads
  while assets load.
- `onRuntimeInitialized` enables the fullscreen button (disabled until then),
  which calls `Module.requestFullscreen(false, false)`.
- `window.onerror` surfaces a runtime **error state** (`data-state="error"`)
  directing the viewer to the browser console.

### Local emsdk build

With an activated emsdk (`source /path/to/emsdk/emsdk_env.sh`, which exports
`EMSDK`):

```sh
cmake --preset web-release
cmake --build --preset web-release
```

This emits four files into `build/web-release/`:

| File               | Purpose                                    |
| ------------------ | ------------------------------------------ |
| `sdl_intro.html`   | HTML shell / entry point                   |
| `sdl_intro.js`     | JavaScript loader/glue                     |
| `sdl_intro.wasm`   | Compiled WebAssembly module                |
| `sdl_intro.data`   | Preloaded virtual filesystem (the assets)  |

The preset resolves the toolchain from `EMSDK` directly, so it works both after
`source emsdk_env.sh` and inside the official Docker image **without** `emcmake`.

### One-command Docker build

If you do not have emsdk installed, build the bundle reproducibly inside the
official Emscripten container:

```sh
make web
```

This runs a BuildKit build of [`Dockerfile.web`](../Dockerfile.web) and exports
exactly the four bundle files to `build/web-dist/`. The Dockerfile:

- Pins `emscripten/emsdk:6.0.3` by both tag and digest
  (`sha256:bb0910e6a18bb9bd7cb31ae4ed40f9073148b78cb2cdb8ea8676454e0d85425c`).
- `COPY`s the repository as build context rather than bind mounting it, so the
  workflow works against **remote Docker contexts** as well as local ones.
- Uses a BuildKit cache mount for `FetchContent` downloads so repeat builds
  reuse the pinned SDL checkouts.
- Exports the bundle through a `scratch` stage with `--output type=local`, so the
  files land on the host with host ownership and no root-owned build tree is left
  behind.

`.dockerignore` keeps `.git`, `build/`, `.deps/`, editor state, and generated
output out of the build context.

### Serving and viewing

Browsers refuse to fetch the `.wasm`/`.data` files over `file://`, so the bundle
must be served over **HTTP**. After `make web`:

```sh
make web-serve   # serves build/web-dist at http://localhost:8000/sdl_intro.html
```

`make web-serve` is a foreground Python HTTP server (`python3 -m http.server`);
stop it with Ctrl-C. A missing `favicon.ico` (404) is harmless.

### Limitation

The native `intro-smoke` CTest is **not** registered for Emscripten because the
`.html` target is not directly executable by CTest. Runtime behavior on the web
is validated manually (and was verified in headless Chrome during development).

## Continuous integration

Automatic CI is defined in
[`.github/workflows/ci.yml`](../.github/workflows/ci.yml). The macOS build is
kept separate in [`.github/workflows/macos.yml`](../.github/workflows/macos.yml)
and runs only when manually started with GitHub Actions' **Run workflow**
control. FetchContent downloads are cached under `.deps` (keyed on the pinned
SDL/image/ttf versions) via `-DFETCHCONTENT_BASE_DIR`.

| Job                | Runner          | What it proves                                              |
| ------------------ | --------------- | ---------------------------------------------------------- |
| `native-release`   | `ubuntu-latest`, `windows-2022` | Automatic native Release build + `intro-smoke` on Linux (GCC) and Windows (MSVC) |
| `mingw-cross`      | `ubuntu-latest` | Linux→Windows cross-build and artifact verification        |
| `emscripten-web`   | `ubuntu-latest` | Emscripten/WebAssembly build and bundle verification       |
| `ubuntu-asan-ubsan`| `ubuntu-latest` | ASan/UBSan Debug build + smoke test with fail-fast options |
| `native-release` (`macos.yml`) | `macos-latest` | Manual native Release build + `intro-smoke` on macOS (AppleClang) |

The native and ASan jobs run `ctest`. The MinGW job cannot run the produced
`.exe` on Linux, so instead of CTest it:

- Asserts `build/mingw-release/sdl_intro.exe` exists and that `file` reports a
  `PE32+ executable (GUI)` (Windows x86_64).
- Asserts `assets/sdl-logo.png` and `assets/OpenSans-Regular.ttf` were copied
  beside the binary.
- Uploads artifact `sdl_intro-windows-x86_64` containing
  `build/mingw-release/sdl_intro.exe` and `build/mingw-release/assets` (fails if
  no files are found).

The `emscripten-web` job sets up the Emscripten SDK with
`emscripten-core/setup-emsdk` pinned to the v16 commit
`4528d102f7230f0e7b276855c01ea1159be0e984` and SDK version `6.0.3`, builds the
`web-release` preset, and (since the `.html` target is not executable by CTest)
asserts that all four bundle files (`sdl_intro.html`, `.js`, `.wasm`, `.data`)
exist and are non-empty before uploading them as artifact `sdl_intro-web`. It
uses a separate FetchContent cache path/key (`.deps-web`,
`deps-<os>-web-<versions>`) from the native and MinGW jobs.

## GitHub Pages deployment

The WebAssembly bundle is published as a live demo at
**<https://tranquility2.github.io/sdl-intro/>**.

Deployment is defined in a **separate** workflow,
[`.github/workflows/pages.yml`](../.github/workflows/pages.yml), rather than in
`ci.yml`. Keeping it separate isolates the elevated Pages write and OIDC
permissions from the pull-request CI matrix.

- **Triggers**: pushes to `main` and manual **Run workflow**
  (`workflow_dispatch`) only. There is deliberately **no** `pull_request`
  trigger, so pull requests build in `ci.yml` but never deploy.
- **Permission isolation**: the workflow's top-level permissions are
  `contents: read`. Only the `deploy` job opts into `pages: write` and
  `id-token: write`; the `build` job has `contents: read` and `pages: read` so
  `configure-pages` can read the site's metadata without receiving any write
  permission. A `concurrency` group `pages` with `cancel-in-progress: false`
  lets an in-progress deployment finish cleanly.

The `build` job (on `ubuntu-latest`) mirrors the `emscripten-web` CI job — same
pinned `emscripten-core/setup-emsdk` v16 commit, SDK `6.0.3`, `.deps-web`
cache, and `web-release` preset — then **stages** the bundle into `_site`:

- Verifies the four generated files (`sdl_intro.html`, `.js`, `.wasm`, `.data`)
  exist and are non-empty.
- Copies all four into `_site/`, then copies `sdl_intro.html` to
  `_site/index.html` so the project root (`/sdl-intro/`) opens automatically
  while the sibling-relative `.js`, `.wasm`, and `.data` references still
  resolve.
- Re-verifies all five staged files are non-empty.

No `.nojekyll` is created and the generated bundle contents are never altered.
The staged `_site` is uploaded as the Pages artifact.

Privileged Pages actions are pinned to full commit SHAs:

| Action | Pinned commit |
| ------ | ------------- |
| `actions/configure-pages` | `45bfe0192ca1faeb007ade9deae92b16b8254a0d` (v6) |
| `actions/upload-pages-artifact` | `fc324d3547104276b827a68afc52ff2a11cc49c9` (v5) |
| `actions/deploy-pages` | `cd2ce8fcbc39b97be8ca5fce6e763baed58fa128` (v5) |

The `deploy` job `needs: build`, runs on `ubuntu-latest`, uses the
`github-pages` environment, and exposes
`${{ steps.deployment.outputs.page_url }}` as the environment URL. Its single
`actions/deploy-pages` step (id `deployment`) publishes the uploaded artifact.

**Deployment history and rollback**: every push to `main` and manual dispatch
appears as a run under the **Pages** workflow in the Actions tab, and each
successful deployment is listed in the **github-pages** environment's
deployment history. To roll back, open a previous **successful** Pages workflow
run and use **Re-run all jobs**; re-running rebuilds that commit's bundle and
redeploys it, restoring the earlier site without a new commit.

## Project structure

```
sdl-intro/
├── CMakeLists.txt              # Build logic, target, assets, smoke test
├── CMakePresets.json           # Presets (debug/release/asan-ubsan/msvc/mingw/web)
├── Makefile                    # Convenience wrapper over the presets
├── Dockerfile.web              # Reproducible Emscripten/WebAssembly build
├── .dockerignore               # Keeps the Docker build context minimal
├── cmake/
│   ├── Dependencies.cmake      # Pinned FetchContent declarations
│   ├── ProjectWarnings.cmake   # project_warnings INTERFACE target
│   ├── ProjectSanitizers.cmake # project_sanitizers INTERFACE target
│   └── toolchains/
│       └── mingw-w64-x86_64.cmake
├── src/
│   └── main.cpp                # SDL3 main-callbacks demo + --smoke mode
├── web/
│   └── shell.html              # Project-owned Emscripten presentation shell
├── assets/                     # sdl-logo.png, OpenSans-Regular.ttf
├── licenses/                   # Apache-2.0.txt (Open Sans)
├── .github/workflows/
│   ├── ci.yml                  # Automatic CI matrix
│   ├── macos.yml               # Manually dispatched macOS CI
│   └── pages.yml               # GitHub Pages build and deployment
├── README.md
└── docs/development.md         # This guide
```

## Provenance

- Extracted from the [NAM](https://github.com/Tranquility2) repository's
  `SDL_test` sandbox at commit `103fb44`. This repository starts with a clean
  history rather than importing NAM's Git history.
- The demo was migrated from SDL2 to SDL3 and rewritten around SDL3's main
  callbacks.

## Non-goals (version 1)

No unit-test framework, packaging workflows, mobile (Android/iOS) targets,
custom domains, analytics, threaded (COOP/COEP) WebAssembly, audio, or
additional media formats. WebAssembly (Emscripten) is now supported and
published to GitHub Pages; the SDL3 main callbacks keep the remaining items
feasible for a later version.

## Licensing and attribution

- Project source and configuration: **MIT** — see [`LICENSE`](../LICENSE).
- **Open Sans** (`assets/OpenSans-Regular.ttf`): Apache License 2.0, Copyright
  2010-2011 Google, Inc. — full text in
  [`licenses/Apache-2.0.txt`](../licenses/Apache-2.0.txt).
- **SDL logo** (`assets/sdl-logo.png`): public domain for copyright purposes,
  trademark-restricted, used referentially only.

See [`THIRD_PARTY_NOTICES.md`](../THIRD_PARTY_NOTICES.md) for full asset
provenance, checksums, trademark notice, and fetched-dependency licenses.
