# Convenience wrapper around CMake. CMake is the single source of build logic
# (see CMakeLists.txt and CMakePresets.json); this Makefile only provides short
# commands that invoke CMake presets. It never contains compiler flags, linker
# flags, dependency versions, or platform detection.

.PHONY: configure build run test sanitize mingw web web-serve clean help

# Default preset used by configure/build/run/test.
PRESET ?= debug

# Directory the exported WebAssembly bundle is written to by `make web`.
WEB_DIST ?= build/web-dist

help:
	@echo "SDL Intro — CMake convenience targets"
	@echo ""
	@echo "  make configure   Configure with the '$(PRESET)' preset (override: PRESET=release)"
	@echo "  make build       Build the '$(PRESET)' preset"
	@echo "  make run         Build and run sdl_intro from the '$(PRESET)' preset"
	@echo "  make test        Run the CTest smoke test for the '$(PRESET)' preset"
	@echo "  make sanitize    Configure, build, and test the 'asan-ubsan' preset"
	@echo "  make mingw       Cross-build a static Windows .exe with MinGW-w64"
	@echo "  make web         Build the WebAssembly bundle in Docker to $(WEB_DIST)"
	@echo "  make web-serve   Serve $(WEB_DIST) over HTTP for browser review"
	@echo "  make clean       Remove the build/ directory"
	@echo ""
	@echo "Presets (need Ninja on Linux/macOS): debug, release, asan-ubsan, mingw-release"
	@echo "Web preset (needs emsdk): web-release"

configure:
	cmake --preset $(PRESET)

build: configure
	cmake --build --preset $(PRESET)

run: build
	./build/$(PRESET)/sdl_intro

test: build
	ctest --preset $(PRESET)

sanitize:
	cmake --preset asan-ubsan
	cmake --build --preset asan-ubsan
	ctest --preset asan-ubsan

mingw:
	cmake --preset mingw-release
	cmake --build --preset mingw-release

# Build the WebAssembly bundle inside the official Emscripten container and
# export exactly the four deployable files to $(WEB_DIST). Using BuildKit's
# --output writes them straight to the host with host ownership, so no
# root-owned build tree is left behind and remote Docker contexts work (the
# repository is sent as build context, not bind mounted).
web:
	rm -rf $(WEB_DIST)
	DOCKER_BUILDKIT=1 docker build -f Dockerfile.web \
		--target export --output type=local,dest=$(WEB_DIST) .
	@echo "Web bundle exported to $(WEB_DIST):"
	@ls -l $(WEB_DIST)

# Serve the exported bundle over HTTP. Browsers refuse to run the .wasm/.data
# fetches from file://, so a real HTTP server is required. Foreground server;
# stop with Ctrl-C.
web-serve:
	@test -f $(WEB_DIST)/sdl_intro.html || { \
		echo "No bundle in $(WEB_DIST); run 'make web' first."; exit 1; }
	@echo "Serving $(WEB_DIST) at http://localhost:8000/sdl_intro.html"
	cd $(WEB_DIST) && python3 -m http.server 8000

clean:
	rm -rf build
