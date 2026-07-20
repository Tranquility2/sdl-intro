# Third-Party Notices

This project bundles third-party assets and fetches third-party dependencies at
build time. The template-owned source and configuration are licensed under the
MIT License (see [`LICENSE`](LICENSE)). The notices below cover everything that
is not template-owned.

## Bundled assets

### `assets/OpenSans-Regular.ttf` — Open Sans

- License: Apache License 2.0 (full text in [`licenses/Apache-2.0.txt`](licenses/Apache-2.0.txt))
- Copyright 2010-2011 Google, Inc.
- Extracted from the NAM repository file `SDL_test/Sans.ttf`.
- SHA-256: `13c03e22a633919beb2847c58c8285fb8a735ee97097d7c48fd403f8294b05f8`

### `assets/sdl-logo.png` — Simple DirectMedia Layer logo

- Source: Wikipedia / Wikimedia Commons,
  <https://commons.wikimedia.org/wiki/File:Simple_DirectMedia_Layer,_Logo.svg>
- Wikimedia Commons marks the logo as being in the **public domain for
  copyright purposes**. That classification does **not** waive trademark
  rights: "SDL" and the SDL logo are trademarks of the SDL project.
- This template uses the logo referentially only. It is **not affiliated with,
  sponsored by, or endorsed by** the SDL project. Any further use must remain
  referential and must not imply endorsement.
- Extracted from the NAM repository file `SDL_test/Sdl-logo.png`.
- SHA-256: `0739ff652a426b1b7e4c548404ec900c747d0b936422bbf61b4afcb3a8a61e80`

## Fetched dependencies

These are downloaded and statically linked at build time via CMake
`FetchContent`; they are not redistributed in this repository's source tree.
Each carries its own license within its fetched source tree.

- **SDL3** `3.4.12` — zlib license — <https://github.com/libsdl-org/SDL>
  (`LICENSE.txt` in the fetched source tree),
  <https://www.libsdl.org/license.php>
- **SDL3_image** `3.4.4` — zlib license — <https://github.com/libsdl-org/SDL_image>
  (`LICENSE.txt` in the fetched source tree)
- **SDL3_ttf** `3.2.2` — zlib license — <https://github.com/libsdl-org/SDL_ttf>
  (`LICENSE.txt` in the fetched source tree)

SDL3_image and SDL3_ttf vendor additional libraries whose licenses are retained
in their respective fetched source trees:

- **libpng** — PNG Reference Library License (bundled with SDL3_image)
- **zlib** — zlib license (bundled with SDL3_image)
- **FreeType** — FreeType License / GPLv2 dual license (bundled with SDL3_ttf)
