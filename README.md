# SDL Intro

A minimal, self-contained **SDL3** C++ bootstrap. One executable opens a
720×480 window, renders the title **SDL Intro** with Open Sans, and bounces the
SDL logo around the window. It exists to demonstrate a clean, reproducible SDL3
project setup — pinned dependencies, strict project-owned warnings, sanitizers,
a headless smoke test, and cross-platform CI — without any game-specific
complexity.

**[Run the live WebAssembly demo](https://tranquility2.github.io/sdl-intro/)**

> This template is **not affiliated with, sponsored by, or endorsed by** the
> SDL project. "SDL" and the SDL logo are trademarks of their respective
> owners; the bundled logo is used referentially only.

## What it shows

Running `sdl_intro` opens a 720×480 window with **SDL Intro** rendered near the
top and the SDL logo bouncing within the window bounds. Pressing **Escape** or
closing the window exits cleanly.

## Quick start

```sh
cmake --preset release
cmake --build --preset release
./build/release/sdl_intro
```

SDL3 (plus SDL3_image and SDL3_ttf) is fetched and statically linked on the
first configure, so there is nothing else to install at runtime. On Linux you
need SDL's development packages first — see the developer guide below.

## Supported platforms

| Platform        | Toolchain  | Notes                                 |
| --------------- | ---------- | ------------------------------------- |
| Linux           | GCC        | Native desktop build                  |
| macOS           | AppleClang | Native desktop build                  |
| Windows         | MSVC       | Native desktop build                  |
| Linux → Windows | MinGW-w64  | Cross-compiled, self-contained `.exe` |
| Web             | Emscripten | [Live WebAssembly demo](https://tranquility2.github.io/sdl-intro/) |

See the developer guide for the WebAssembly local emsdk and one-command Docker
workflows.

## Documentation

See **[docs/development.md](docs/development.md)** for the full technical guide:
prerequisites, presets, build/run/test commands, Makefile targets, sanitizers,
the smoke test, pinned dependencies, asset handling, the MinGW cross-build, CI,
and project structure.

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
