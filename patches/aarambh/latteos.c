/*
 * LatteOS's boot menu theme for Aarambh (github.com/NarkAgni/aarambh, GPL-3.0), after its Cinema theme
 * (ROADMAP 3.11, the dark design chosen 16. 11.: inspo/boot-latteos-tmavy.png). Copied into Aarambh's tree as
 * src/themes/latteos/latteos.c and registered by patches/aarambh/build.sh.
 *
 * What differs from Cinema: each entry brings its own picture (the coffee cup on espresso, made by
 * patches/aarambh/make-assets.py) and the pictures cross-fade as the selection moves, as Minimal does; the
 * clock is 24-hour; the words and the gold are LatteOS's. Text stays ASCII: Aarambh draws characters 32-126.
 */
#include "aarambh/theme_kit.h"

#include "lib/str.h"

#define LATTE_GOLD    0xe2aa5c   /* system/cups.json, the latte cup's gold */
#define LATTE_CREAM   0xf6eee2
#define LATTE_WARM    0xd6c4b0
#define LATTE_TILE    0x241810
#define LATTE_LIT     0x4e301a
#define LATTE_TITLES  3

typedef struct {
    Face label;
    Face titles[LATTE_TITLES];
    Face detail;
    Face hint;
    Face clock;
    Face list;
    Face letter;
    Face splash;
} LatteTheme;

static LatteTheme latte;

static float strip_top(const Image *screen) { return screen->height - kit_y(screen, 140); }

/* The entries' pictures, the nearer two blended by where the selection is (as Minimal does). */
static void draw_pictures(const ThemeContext *context, const ThemeFrame *frame)
{
    int lower = (int)frame->position;
    int upper = lower + 1;
    float blend = frame->position - lower;

    if (lower < 0) lower = 0;
    if (lower >= context->entry_count) lower = context->entry_count - 1;
    image_copy(context->screen, &context->entries[lower].background);
    if (upper < context->entry_count && blend > 0.0f) {
        image_blend(context->screen, context->screen, &context->entries[upper].background, (int)(blend * 256.0f));
    }
}

/* The top bar and the bottom strip are in the pictures themselves (make-assets.py), so nothing is blended
   line by line each frame; only the name is drawn on the bar. */
static void draw_bars(Image *screen)
{
    draw_text(screen, &latte.label, kit_x(screen, 48), (int)(kit_y(screen, 34) + latte.label.ascent), "LATTEOS",
              LATTE_GOLD, 256);
}

static void latte_load(const ThemeContext *context)
{
    const Image *screen = context->screen;

    face_init(&latte.label, context->font_bold, kit_s(screen, 15));
    face_init(&latte.titles[0], context->font_bold, kit_s(screen, 92));
    face_init(&latte.titles[1], context->font_bold, kit_s(screen, 70));
    face_init(&latte.titles[2], context->font_bold, kit_s(screen, 52));
    face_init(&latte.detail, context->font_regular, kit_s(screen, 18));
    face_init(&latte.hint, context->font_regular, kit_s(screen, 15));
    face_init(&latte.clock, context->font_bold, kit_s(screen, 20));
    face_init(&latte.list, context->font_regular, kit_s(screen, 20));
    face_init(&latte.letter, context->font_bold, kit_s(screen, 30));
    face_init(&latte.splash, context->font_bold, kit_s(screen, 52));
}

/* "NOW BREWING" over LatteOS; the others say what they are. */
static const char *tag_for(const Entry *entry, int is_default)
{
    if (str_equal(entry->key, "windows")) return "ALSO ON THIS PC";
    if (is_default) return "NOW BREWING";
    return "ON THIS PC";
}

static void draw_feature(const ThemeContext *context, const ThemeFrame *frame, int alpha)
{
    Image *screen = context->screen;
    float visibility;
    int index = kit_nearest(frame, context->entry_count, &visibility);
    const Entry *entry = &context->entries[index];
    float strip = strip_top(screen);
    int shown = (int)(alpha * visibility);
    int content = (int)(shown * (1.0f - frame->list));
    float slide = (1.0f - visibility) * kit_s(screen, 40);
    Face *title = kit_fit(latte.titles, LATTE_TITLES, entry->title, kit_x(screen, 640));
    char line[160];

    draw_text(screen, &latte.label, kit_x(screen, 80), (int)(strip - kit_s(screen, 236) + latte.label.ascent),
              tag_for(entry, index == context->default_index), LATTE_GOLD, content);
    draw_text(screen, title, kit_x(screen, 76) - slide, (int)(strip - kit_s(screen, 206) + latte.titles[0].ascent),
              entry->title, LATTE_CREAM, shown);

    str_copy(line, entry_launch_detail(entry, -1), sizeof(line));
    if (line[0] == '\0') {
        entry_subtitle(entry, index == context->default_index, line, sizeof(line));
    }
    if (frame->status[0] != '\0') {
        str_append(line, "   -   ", sizeof(line));
        str_append(line, frame->status, sizeof(line));
    }
    draw_text(screen, &latte.detail, kit_x(screen, 82), (int)(strip - kit_s(screen, 86) + latte.detail.ascent), line,
              LATTE_WARM, content * 220 / 256);

    kit_kernel_list(screen, entry, frame, &latte.label, &latte.list, kit_x(screen, 80), kit_y(screen, 170),
                    kit_x(screen, 560), LATTE_CREAM, LATTE_GOLD, shown);
}

static float widest_hints(const ThemeContext *context, const ThemeFrame *frame, const UiHintStyle *hints)
{
    float widest = 0.0f;
    int i;

    for (i = 0; i < context->entry_count; i++) {
        float width = kit_hints_width(hints, &context->entries[i], frame, 0);
        if (width > widest) widest = width;
    }
    return widest;
}

static void draw_tiles(const ThemeContext *context, const ThemeFrame *frame, float min_left, int alpha)
{
    Image *screen = context->screen;
    float gap = kit_s(screen, 12);
    float max_total = screen->width - kit_x(screen, 80) - min_left;
    float width = kit_s(screen, 112);
    float height = kit_s(screen, 76);
    float top = strip_top(screen) + kit_s(screen, 42);
    float left;
    float outline;
    int i;

    if (context->entry_count * (width + gap) - gap > max_total) {
        width = (max_total + gap) / context->entry_count - gap;
    }
    left = screen->width - kit_x(screen, 80) - context->entry_count * (width + gap) + gap;

    for (i = 0; i < context->entry_count; i++) {
        const Entry *entry = &context->entries[i];
        float weight = kit_weight(frame, i);
        float x = left + i * (width + gap);
        float icon = kit_s(screen, 34);

        draw_round_rect(screen, x, top, width, height, kit_s(screen, 8), 0, LATTE_TILE, alpha);
        draw_round_rect(screen, x, top, width, height, kit_s(screen, 8), 0, LATTE_LIT, (int)(alpha * weight));
        kit_logo(screen, entry, &latte.letter, x + (width - icon) / 2, top + (height - icon) / 2, icon, 0xfae2be,
                 (int)(alpha * (0.45f + 0.55f * weight)));
    }

    outline = left + frame->position * (width + gap);
    draw_round_rect(screen, outline - 3, top - 3, width + 6, height + 6, kit_s(screen, 10), 3, LATTE_GOLD, alpha);
}

/* Aarambh's clock is "9:41" with "AM"/"PM" beside it; LatteOS shows the 24-hour time. */
static void clock_24(const ThemeFrame *frame, char *out, int size)
{
    const char *t = frame->clock_time;
    int hour = 0;
    int i = 0;

    while (t[i] >= '0' && t[i] <= '9') hour = hour * 10 + (t[i++] - '0');
    if (frame->clock_period[0] == 'P' && hour != 12) hour += 12;
    if (frame->clock_period[0] == 'A' && hour == 12) hour = 0;
    out[0] = (char)('0' + hour / 10);
    out[1] = (char)('0' + hour % 10);
    out[2] = '\0';
    str_append(out, t + i, size);
}

static void latte_render(const ThemeContext *context, const ThemeFrame *frame)
{
    Image *screen = context->screen;
    KitFade fade = kit_fade(frame);
    UiHintStyle hints = { &latte.hint, LATTE_WARM, 0 };
    float hints_x = kit_x(screen, 80);
    float strip_left = hints_x + widest_hints(context, frame, &hints) + kit_s(screen, 32);
    char clock[16];

    draw_pictures(context, frame);
    draw_bars(screen);
    draw_feature(context, frame, fade.alpha);
    draw_tiles(context, frame, strip_left, fade.alpha);

    kit_hints(screen, &hints, hints_x, (int)(strip_top(screen) + kit_s(screen, 70) + latte.hint.ascent / 2),
              &context->entries[frame->selected], frame, 0, fade.alpha * 170 / 256);

    clock_24(frame, clock, sizeof(clock));
    kit_text_right(screen, &latte.clock, screen->width - kit_x(screen, 48), (int)(kit_y(screen, 34) + latte.clock.ascent),
                   clock, LATTE_CREAM, fade.alpha);

    kit_splash(context, frame, &latte.splash, &latte.detail, &context->entries[frame->selected].background, LATTE_CREAM,
               LATTE_GOLD);
    kit_intro_blackout(screen, frame);
}

static const EditColors latte_edit = { 0x1c120c, 0x0f0906, LATTE_GOLD, LATTE_CREAM, 0xb8a58e, EDIT_FRAME_CARD };

const Theme latteos_theme = {
    .name = "latteos",
    .list_rows = KIT_LIST_ROWS,
    .vertical_navigation = 0,
    .down_opens_list = 1,
    .edit = &latte_edit,
    .load = latte_load,
    .render = latte_render
};
