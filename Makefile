# Convenience wrapper around CMake. CMake is the single source of build logic
# (see CMakeLists.txt and CMakePresets.json); this Makefile only provides short
# commands that invoke CMake presets. It never contains compiler flags, linker
# flags, dependency versions, or platform detection.

.PHONY: configure build run test sanitize clean help

# Default preset used by configure/build/run/test.
PRESET ?= debug

help:
	@echo "SDL Intro — CMake convenience targets"
	@echo ""
	@echo "  make configure   Configure with the '$(PRESET)' preset (override: PRESET=release)"
	@echo "  make build       Build the '$(PRESET)' preset"
	@echo "  make run         Build and run sdl_intro from the '$(PRESET)' preset"
	@echo "  make test        Run the CTest smoke test for the '$(PRESET)' preset"
	@echo "  make sanitize    Configure, build, and test the 'asan-ubsan' preset"
	@echo "  make clean       Remove the build/ directory"
	@echo ""
	@echo "Presets (need Ninja on Linux/macOS): debug, release, asan-ubsan"

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

clean:
	rm -rf build
