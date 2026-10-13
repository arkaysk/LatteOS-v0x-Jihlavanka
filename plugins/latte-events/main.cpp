// latte-events: what Hyprland does not tell its Lua configuration, told.
//
//   hl.on("latte.drag_end", function(window, x, y) … end)
//       a floating window that was being moved with the mouse has been let go, the pointer at x, y. However
//       the move began: by the title bar, by the window's own header, with Win and the mouse.
//
// Without it a window cannot be laid against an edge when it is dropped there, as Windows does
// (system/hypr/latte/windows.lua). The configuration works without the plugin; it only lacks that.
// SPDX-License-Identifier: MIT
#define WLR_USE_UNSTABLE

#include <hyprland/src/plugins/PluginAPI.hpp>
#include <hyprland/src/event/EventBus.hpp>
#include <hyprland/src/layout/LayoutManager.hpp>
#include <hyprland/src/layout/supplementary/DragController.hpp>
#include <hyprland/src/layout/target/Target.hpp>
#include <hyprland/src/managers/input/InputManager.hpp>
#include <hyprland/src/desktop/view/Window.hpp>
#include <hyprland/src/Compositor.hpp>

using CCustomEvent = Event::CEventBus::CCustomEvent;

static const char*         DRAG_END = "latte.drag_end";
static HANDLE              g_handle = nullptr;
static SP<CCustomEvent>    g_dragEnd;
static CHyprSignalListener g_onMove, g_onButton, g_onReload;
static PHLWINDOWREF        g_moved;            // the floating window the mouse is moving, if any

APICALL EXPORT std::string PLUGIN_API_VERSION() {
    return HYPRLAND_API_VERSION;
}

static void letGo() {
    const auto window = g_moved.lock();
    g_moved.reset();
    if (!window)
        return;
    const auto at = g_pInputManager->getMouseCoordsInternal();
    (void)g_dragEnd->emit({PHLWINDOWREF{window}, at.x, at.y});
}

APICALL EXPORT PLUGIN_DESCRIPTION_INFO PLUGIN_INIT(HANDLE handle) {
    g_handle = handle;
    using T  = CCustomEvent::eType;
    g_dragEnd = makeShared<CCustomEvent>(DRAG_END, std::vector<T>{T::TYPE_WINDOW, T::TYPE_DOUBLE, T::TYPE_DOUBLE});
    HyprlandAPI::addEvent(handle, g_dragEnd);

    // Nothing says that a move has begun or ended; the drag controller says whether one is going on, and it is
    // asked whenever the mouse moves. The end is the button let go, or, when a key binding took that
    // (Win + the mouse) and it never comes here, the first movement after the move is over.
    g_onMove = Event::bus()->m_events.input.mouse.move.listen([](Vector2D, Event::SCallbackInfo&) {
        const auto& drag   = g_layoutManager->dragController();
        const auto  target = drag && drag->mode() == MBIND_MOVE ? drag->target() : nullptr;
        const auto  window = target ? target->window() : nullptr;
        if (window && window->m_isFloating)
            g_moved = window;
        else
            letGo();
    });
    g_onButton = Event::bus()->m_events.input.mouse.button.listen([](IPointer::SButtonEvent e, Event::SCallbackInfo&) {
        if (e.state == WL_POINTER_BUTTON_STATE_RELEASED)
            letGo();
    });
    // Each time the configuration is read again its Lua starts anew, and with it who listens to what: Hyprland
    // 0.56 then still knows a plugin's event by name but no longer delivers it. Announced again, it does. (The
    // configuration is read again right after a plugin is loaded, so this is every session, not a rare case.)
    g_onReload = Event::bus()->m_events.config.reloaded.listen([] { Event::bus()->m_events.pluginEventAdded.emit(g_dragEnd); });
    return {"latte-events", "LatteOS: a window let go after a move", "LatteOS", "1.0"};
}

APICALL EXPORT void PLUGIN_EXIT() {
    g_onMove.reset();
    g_onButton.reset();
    g_onReload.reset();
    HyprlandAPI::removeEvent(g_handle, DRAG_END);
}
