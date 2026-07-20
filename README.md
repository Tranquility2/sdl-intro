# SDL Intro

A minimal, self-contained **SDL3** C++ bootstrap. One executable opens a
720×480 window, renders the title **SDL Intro** with Open Sans, and bounces the
SDL logo around the window. It exists to demonstrate a clean, reproducible SDL3
project setup — pinned dependencies, strict project-owned warnings, sanitizers,
a headless smoke test, and cross-platform CI — without any game-specific
complexity.

> This template is **not affiliated with, sponsored by, or endorsed by** the
> SDL project. "SDL" and the SDL logo are trademarks of their respective
> owners; the bundled logo is used referentially only.

## Platform matrix (version 1)

| Platform | Compiler   | Runner          | Build type      |
| -------- | ---------- | --------------- | --------------- |
| Linux    | GCC        | `ubuntu-latest` | Release + ASan/UBSan |
| macOS    | AppleClang | `macos-latest`  | Release         |
| Windows  | MSVC       | `windows-2022`  | Release         |

"Multi-platform" here means native Linux, macOS, and Windows desktop builds.

## Prerequisites

- **CMake** 3.21 or newer
- **Ninja** (Linux and macOS)
- **GCC** (Linux), **AppleClang** (macOS), or **Visual Studio 2022 / MSVC**
  (Windows)
- A network connection on the first configure (SDL3, SDL3_image, and SDL3_ttf
  are fetched and statically linked)
- **Linux only:** SDL's X11/Wayland/GL/audio development packages. On
  Debian/Ubuntu:

  ```sh
  sudo apt-get install -y ninja-build \
    libx11-dev libxext-dev libxrandr-dev libxcursor-dev libxi-dev \
    libxfixes-dev libxss-dev libxtst-dev libwayland-dev \
    libxkbcommon-dev wayland-protocols libegl1-mesa-dev \
    libgl1-mesa-dev libgles2-mesa-dev libpulse-dev libasound2-dev
  ```

## Build and run

Using CMake presets (recommended):

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

Available presets: `debug`, `release`, `asan-ubsan` (Linux/macOS, Ninja) and
`windows-msvc-debug`, `windows-msvc-release` (Windows, MSVC).

### Makefile shortcuts

The `Makefile` is a thin wrapper over the presets (no build logic of its own):

```sh
make configure          # PRESET=debug by default; override with PRESET=release
make build
make run
make test
make sanitize           # configure + build + test the asan-ubsan preset
make clean
make help
```

## Expected behavior

Running `sdl_intro` opens a 720×480 window with **SDL Intro** rendered near the
top and the SDL logo bouncing within the window bounds. Pressing **Escape** or
closing the window exits cleanly.

### Smoke test

`sdl_intro --smoke` runs deterministically without a desktop session. It
initializes SDL video and SDL3_ttf, decodes `assets/sdl-logo.png`, opens
`assets/OpenSans-Regular.ttf`, renders the title to a surface, cleans up, and
exits `0` — without creating a renderer or entering the render loop. CTest runs
it as `intro-smoke` with `SDL_VIDEODRIVER=dummy` and a 10-second timeout.

## Dependencies (pinned)

All fetched via CMake `FetchContent` from the official `libsdl-org`
repositories and statically linked:

| Library    | Release  | Commit                                     |
| ---------- | -------- | ------------------------------------------ |
| SDL3       | `3.4.12` | `f87239e71e42da91ca317a12eefb82cfbf3393eb` |
| SDL3_image | `3.4.4`  | `bec9134a26c7d0f31b36d6083c25296e04cabff5` |
| SDL3_ttf   | `3.2.2`  | `a1ce3670aec736ecbf0936c43f2f0cc53aa61e5b` |

SDL3_image is configured with **PNG only**; SDL3_ttf is built **without
HarfBuzz or PlutoSVG**, because the demo renders fixed basic-Latin text.

## Non-goals (version 1)

No unit-test framework, packaging workflows, mobile (Android/iOS) targets, web
(Emscripten) targets, audio, or additional media formats. SDL3's main callbacks
keep those feasible for a later version.

## Provenance

- Extracted from the [NAM](https://github.com/Tranquility2) repository's
  `SDL_test` sandbox at commit `103fb44`. This repository starts with a clean
  history rather than importing NAM's Git history.
- The demo was migrated from SDL2 to SDL3 and rewritten around SDL3's main
  callbacks.

## Assets and licensing

- Project source and configuration: **MIT** — see [`LICENSE`](LICENSE).
- **Open Sans** (`assets/OpenSans-Regular.ttf`): Apache License 2.0, Copyright
  2010-2011 Google, Inc. — full text in
  [`licenses/Apache-2.0.txt`](licenses/Apache-2.0.txt).
- **SDL logo** (`assets/sdl-logo.png`): sourced from
  [Wikimedia Commons](https://commons.wikimedia.org/wiki/File:Simple_DirectMedia_Layer,_Logo.svg),
  classified public domain for copyright purposes and trademark-restricted.

See [`THIRD_PARTY_NOTICES.md`](THIRD_PARTY_NOTICES.md) for full asset provenance,
checksums, trademark notice, and fetched-dependency licenses.
