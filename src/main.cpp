// SDL Intro - a minimal SDL3 bootstrap demo.
//
// The application uses SDL3's main callbacks (SDL_MAIN_USE_CALLBACKS) so the
// bootstrap loop stays portable. It loads a PNG logo with SDL3_image, renders a
// short title with SDL3_ttf, and bounces the logo inside the window. A
// deterministic `--smoke` mode exercises the same loaders headlessly and exits
// without creating a renderer or entering the interactive loop.

#define SDL_MAIN_USE_CALLBACKS
#include <SDL3/SDL.h>
#include <SDL3/SDL_main.h>
#include <SDL3_image/SDL_image.h>
#include <SDL3_ttf/SDL_ttf.h>

#include <string>

namespace {

constexpr int kWindowWidth = 720;
constexpr int kWindowHeight = 480;
constexpr float kFontSize = 28.0f;
constexpr char kTitle[] = "SDL Intro";

// All mutable SDL resources live here and travel through SDL's callback
// `appstate` pointer, so there are no global window or renderer handles.
struct AppState {
    SDL_Window* window = nullptr;
    SDL_Renderer* renderer = nullptr;
    SDL_Texture* logo_texture = nullptr;
    SDL_Texture* title_texture = nullptr;
    TTF_Font* font = nullptr;
    bool ttf_ready = false;
    float logo_w = 0.0f;
    float logo_h = 0.0f;
    float title_w = 0.0f;
    float title_h = 0.0f;
    float logo_x = 0.0f;
    float logo_y = 0.0f;
    float vel_x = 0.0f;
    float vel_y = 0.0f;
    Uint64 last_ms = 0;
};

// Build an absolute path to a bundled asset next to the executable so loading
// works regardless of the current working directory.
std::string AssetPath(const std::string& filename) {
    const char* base = SDL_GetBasePath();
    const std::string dir = base != nullptr ? base : "";
    return dir + "assets/" + filename;
}

// Log the last SDL error for `context` and report failure to SDL.
SDL_AppResult Fail(const char* context) {
    SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, "%s: %s", context, SDL_GetError());
    return SDL_APP_FAILURE;
}

}  // namespace

SDL_AppResult SDL_AppInit(void** appstate, int argc, char* argv[]) {
    bool smoke = false;
    for (int i = 1; i < argc; ++i) {
        if (SDL_strcmp(argv[i], "--smoke") == 0) {
            smoke = true;
        }
    }

    auto* state = new AppState();
    *appstate = state;

    if (!SDL_Init(SDL_INIT_VIDEO)) {
        return Fail("SDL_Init");
    }

    if (!TTF_Init()) {
        return Fail("TTF_Init");
    }
    state->ttf_ready = true;

    SDL_Surface* logo_surface = IMG_Load(AssetPath("sdl-logo.png").c_str());
    if (logo_surface == nullptr) {
        return Fail("IMG_Load(sdl-logo.png)");
    }

    state->font = TTF_OpenFont(AssetPath("OpenSans-Regular.ttf").c_str(), kFontSize);
    if (state->font == nullptr) {
        SDL_DestroySurface(logo_surface);
        return Fail("TTF_OpenFont(OpenSans-Regular.ttf)");
    }

    const SDL_Color white = {255, 255, 255, 255};
    SDL_Surface* title_surface =
        TTF_RenderText_Blended(state->font, kTitle, 0, white);
    if (title_surface == nullptr) {
        SDL_DestroySurface(logo_surface);
        return Fail("TTF_RenderText_Blended");
    }

    if (smoke) {
        SDL_DestroySurface(logo_surface);
        SDL_DestroySurface(title_surface);
        TTF_CloseFont(state->font);
        state->font = nullptr;
        SDL_Log("Smoke test passed: PNG decoded, font opened, title surface rendered.");
        return SDL_APP_SUCCESS;
    }

    state->window = SDL_CreateWindow(kTitle, kWindowWidth, kWindowHeight, 0);
    if (state->window == nullptr) {
        SDL_DestroySurface(logo_surface);
        SDL_DestroySurface(title_surface);
        return Fail("SDL_CreateWindow");
    }

    state->renderer = SDL_CreateRenderer(state->window, nullptr);
    if (state->renderer == nullptr) {
        SDL_DestroySurface(logo_surface);
        SDL_DestroySurface(title_surface);
        return Fail("SDL_CreateRenderer");
    }

    state->logo_texture =
        SDL_CreateTextureFromSurface(state->renderer, logo_surface);
    state->title_texture =
        SDL_CreateTextureFromSurface(state->renderer, title_surface);

    // Draw the logo at half its native size so it fits comfortably.
    state->logo_w = static_cast<float>(logo_surface->w) * 0.5f;
    state->logo_h = static_cast<float>(logo_surface->h) * 0.5f;
    state->title_w = static_cast<float>(title_surface->w);
    state->title_h = static_cast<float>(title_surface->h);

    SDL_DestroySurface(logo_surface);
    SDL_DestroySurface(title_surface);

    if (state->logo_texture == nullptr || state->title_texture == nullptr) {
        return Fail("SDL_CreateTextureFromSurface");
    }

    state->logo_x = 0.0f;
    state->logo_y = state->title_h + 24.0f;
    state->vel_x = 160.0f;
    state->vel_y = 120.0f;
    state->last_ms = SDL_GetTicks();

    return SDL_APP_CONTINUE;
}

SDL_AppResult SDL_AppIterate(void* appstate) {
    auto* state = static_cast<AppState*>(appstate);

    int output_width = 0;
    int output_height = 0;
    if (!SDL_GetRenderOutputSize(state->renderer, &output_width, &output_height)) {
        return Fail("SDL_GetRenderOutputSize");
    }

    const Uint64 now = SDL_GetTicks();
    float dt = static_cast<float>(now - state->last_ms) / 1000.0f;
    state->last_ms = now;
    if (dt > 0.05f) {
        dt = 0.05f;  // Clamp large stalls so the logo never teleports.
    }

    const float render_width = static_cast<float>(output_width);
    const float render_height = static_cast<float>(output_height);
    const float max_x = SDL_max(0.0f, render_width - state->logo_w);
    const float max_y = SDL_max(0.0f, render_height - state->logo_h);
    const float min_y = SDL_min(state->title_h + 24.0f, max_y);

    state->logo_x += state->vel_x * dt;
    state->logo_y += state->vel_y * dt;

    if (max_x == 0.0f) {
        state->logo_x = 0.0f;
    } else if (state->logo_x <= 0.0f) {
        state->logo_x = 0.0f;
        if (state->vel_x < 0.0f) {
            state->vel_x = -state->vel_x;
        }
    } else if (state->logo_x >= max_x) {
        state->logo_x = max_x;
        if (state->vel_x > 0.0f) {
            state->vel_x = -state->vel_x;
        }
    }

    if (max_y == min_y) {
        state->logo_y = min_y;
    } else if (state->logo_y <= min_y) {
        state->logo_y = min_y;
        if (state->vel_y < 0.0f) {
            state->vel_y = -state->vel_y;
        }
    } else if (state->logo_y >= max_y) {
        state->logo_y = max_y;
        if (state->vel_y > 0.0f) {
            state->vel_y = -state->vel_y;
        }
    }

    SDL_SetRenderDrawColor(state->renderer, 15, 20, 30, 255);
    SDL_RenderClear(state->renderer);

    const SDL_FRect title_dst = {
        SDL_max(0.0f, (render_width - state->title_w) / 2.0f), 12.0f,
        state->title_w, state->title_h};
    SDL_RenderTexture(state->renderer, state->title_texture, nullptr, &title_dst);

    const SDL_FRect logo_dst = {state->logo_x, state->logo_y, state->logo_w,
                                state->logo_h};
    SDL_RenderTexture(state->renderer, state->logo_texture, nullptr, &logo_dst);

    SDL_RenderPresent(state->renderer);
    return SDL_APP_CONTINUE;
}

SDL_AppResult SDL_AppEvent(void* appstate, SDL_Event* event) {
    (void)appstate;
    if (event->type == SDL_EVENT_QUIT) {
        return SDL_APP_SUCCESS;
    }
    if (event->type == SDL_EVENT_KEY_DOWN && event->key.key == SDLK_ESCAPE) {
        return SDL_APP_SUCCESS;
    }
    return SDL_APP_CONTINUE;
}

void SDL_AppQuit(void* appstate, SDL_AppResult result) {
    (void)result;
    auto* state = static_cast<AppState*>(appstate);
    if (state == nullptr) {
        return;
    }

    if (state->logo_texture != nullptr) {
        SDL_DestroyTexture(state->logo_texture);
    }
    if (state->title_texture != nullptr) {
        SDL_DestroyTexture(state->title_texture);
    }
    if (state->font != nullptr) {
        TTF_CloseFont(state->font);
    }
    if (state->renderer != nullptr) {
        SDL_DestroyRenderer(state->renderer);
    }
    if (state->window != nullptr) {
        SDL_DestroyWindow(state->window);
    }
    if (state->ttf_ready) {
        TTF_Quit();
    }

    delete state;
    // SDL calls SDL_Quit() itself after this callback returns.
}
