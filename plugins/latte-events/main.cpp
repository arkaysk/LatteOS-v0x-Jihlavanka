// latte-events: what Hyprland does not tell its Lua configuration, told.
//
//   hl.on("latte.drag_end", function(window, x, y) … end)
//       a floating window that was being moved with the mouse has been let go, the pointer at x, y. However
//       the move began: by the title bar, by the window's own header, with Win and the mouse.
//
// Without it a window cannot be laid against an edge when it is dropped there, as Windows does
// (system/hypr/latte/windows.lua). The configuration works without the plugin; it only lacks that.
//
// And one thing Hyprland does not do: a press on the empty desktop just outside a floating window, beyond the
// strip where its edge is taken to resize it, carries the whole window. So a window can always be taken hold
// of, whatever part of it is in reach.
//
//   hl.on("latte.window_menu", function(window, x, y) … end)
//       a window asked for its menu (xdg_toplevel.show_window_menu: the right button on its own header, in GTK,
//       Chromium and Electron apps such as VS Code), the pointer at x, y. Hyprland leaves the request unanswered;
//       LatteOS shows the same menu as on the window's berry.
// SPDX-License-Identifier: MIT
#define WLR_USE_UNSTABLE

#include <hyprland/src/plugins/PluginAPI.hpp>
#include <hyprland/src/event/EventBus.hpp>
#include <hyprland/src/layout/LayoutManager.hpp>
#include <hyprland/src/layout/supplementary/DragController.hpp>
#include <hyprland/src/layout/target/Target.hpp>
#include <hyprland/src/managers/input/InputManager.hpp>
#include <hyprland/src/managers/SeatManager.hpp>
#include <hyprland/src/desktop/state/FocusState.hpp>
#include <hyprland/src/desktop/state/WindowState.hpp>
#include <hyprland/src/desktop/view/window/Window.hpp>
#include <hyprland/src/Compositor.hpp>
// the request is set on the toplevel's wire object, which XDGShell keeps private; a window's xdg surface is private
// to its Wayland backend
#define private public
#include <hyprland/src/protocols/XDGShell.hpp>
#include <hyprland/src/desktop/view/window/WaylandBackend.hpp>
#undef private

using CCustomEvent = Event::CEventBus::CCustomEvent;

static const char*         DRAG_END = "latte.drag_end";
static const char*         WINDOW_MENU = "latte.window_menu";
static HANDLE              g_handle = nullptr;
static SP<CCustomEvent>    g_dragEnd, g_windowMenu;
static CHyprSignalListener g_onMove, g_onButton, g_onReload, g_onOpen;
static PHLWINDOWREF        g_moved;            // the floating window the mouse is moving, if any
static bool                g_carrying = false; // …and it is this plugin that began the move, from beside the window
static const double        REACH    = 36;      // px outside a window where a press still takes hold of it
static const uint32_t      LEFT_BUTTON = 0x110;

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

// The floating window whose outside the pointer is just beside, if there is one and nothing else is under the
// pointer: no window, no panel that takes the mouse there.
// The xdg toplevel of a window, none for an X11 one.
static SP<CXDGToplevelResource> toplevelOf(const PHLWINDOW& w) {
    if (!w || w->backend().type() != Desktop::View::eBackendType::WINDOW_BACKEND_WAYLAND)
        return nullptr;
    const auto xdg = static_cast<Desktop::View::CWaylandBackend&>(w->backend()).m_resource.lock();
    return xdg ? xdg->m_toplevel.lock() : nullptr;
}

static PHLWINDOW besideWindow(const Vector2D& at) {
    if (g_pSeatManager->m_state.pointerFocus.lock())
        return nullptr;
    PHLWINDOW found = nullptr;
    for (const auto& w : Desktop::windowState()->windows()) {
        if (!w || !w->mapped() || !w->isFloating() || w->isHidden() || !w->m_workspace || !w->m_workspace->visible())
            continue;
        const auto box = w->getWindowMainSurfaceBox();
        if (at.x >= box.x - REACH && at.x <= box.x + box.w + REACH && at.y >= box.y - REACH && at.y <= box.y + box.h + REACH)
            found = w;                                  // the last one is the one on top
    }
    return found;
}

// A window that asks for its menu is answered with the event, where the pointer is. Hyprland tells a window
// only that it can be maximised and made fullscreen, and an app asks for no menu it is not told of: the window
// is told again, with the menu, and a configure makes it take that up.
static void hearMenu(PHLWINDOW window) {
    const auto toplevel = toplevelOf(window);
    if (!toplevel || !toplevel->m_resource)
        return;
    if (toplevel->m_resource->version() >= 5) {
        wl_array caps;
        wl_array_init(&caps);
        for (uint32_t c : {XDG_TOPLEVEL_WM_CAPABILITIES_WINDOW_MENU, XDG_TOPLEVEL_WM_CAPABILITIES_MAXIMIZE, XDG_TOPLEVEL_WM_CAPABILITIES_FULLSCREEN})
            *(uint32_t*)wl_array_add(&caps, sizeof(uint32_t)) = c;
        toplevel->m_resource->sendWmCapabilities(&caps);
        wl_array_release(&caps);
        const auto box = window->getWindowMainSurfaceBox();
        if (box.w > 0 && box.h > 0)                     // a size of nothing would let the app choose its own
            toplevel->setSize(box.size());
    }
    toplevel->m_resource->setShowWindowMenu([ref = PHLWINDOWREF{window}](CXdgToplevel*, wl_resource*, uint32_t, int32_t, int32_t) {
        const auto w = ref.lock();
        if (!w)
            return;
        const auto at = g_pInputManager->getMouseCoordsInternal();
        (void)g_windowMenu->emit({PHLWINDOWREF{w}, at.x, at.y});
    });
}

APICALL EXPORT PLUGIN_DESCRIPTION_INFO PLUGIN_INIT(HANDLE handle) {
    g_handle = handle;
    using T  = CCustomEvent::eType;
    g_dragEnd = makeShared<CCustomEvent>(DRAG_END, std::vector<T>{T::TYPE_WINDOW, T::TYPE_DOUBLE, T::TYPE_DOUBLE});
    HyprlandAPI::addEvent(handle, g_dragEnd);
    g_windowMenu = makeShared<CCustomEvent>(WINDOW_MENU, std::vector<T>{T::TYPE_WINDOW, T::TYPE_DOUBLE, T::TYPE_DOUBLE});
    HyprlandAPI::addEvent(handle, g_windowMenu);
    for (const auto& w : Desktop::windowState()->windows())
        hearMenu(w);
    g_onOpen = Event::bus()->m_events.window.open.listen([](PHLWINDOW w) { hearMenu(w); });

    // Nothing says that a move has begun or ended; the drag controller says whether one is going on, and it is
    // asked whenever the mouse moves. The end is the button let go, or, when a key binding took that
    // (Win + the mouse) and it never comes here, the first movement after the move is over.
    g_onMove = Event::bus()->m_events.input.mouse.move.listen([](Vector2D, Event::SCallbackInfo&) {
        const auto& drag   = g_layoutManager->dragController();
        const auto  target = drag && drag->mode() == MBIND_MOVE ? drag->target() : nullptr;
        const auto  window = target ? target->window() : nullptr;
        if (window && window->isFloating())
            g_moved = window;
        else
            letGo();
    });
    g_onButton = Event::bus()->m_events.input.mouse.button.listen([](IPointer::SButtonEvent e, Event::SCallbackInfo& info) {
        const auto& drag = g_layoutManager->dragController();
        if (e.state == WL_POINTER_BUTTON_STATE_RELEASED) {
            if (g_carrying) {
                g_carrying = false;
                if (drag)
                    drag->dragEnd();
                info.cancelled = true;
            }
            letGo();
            return;
        }
        if (e.button != LEFT_BUTTON || !drag || drag->mode() != MBIND_INVALID)
            return;
        const auto window = besideWindow(g_pInputManager->getMouseCoordsInternal());
        if (!window)
            return;
        Desktop::focusState()->fullWindowFocus(window, Desktop::FOCUS_REASON_CLICK);
        drag->dragBegin(window->layoutTarget(), MBIND_MOVE);
        g_moved    = window;
        g_carrying = true;
        info.cancelled = true;
    });
    // Each time the configuration is read again its Lua starts anew, and with it who listens to what: Hyprland
    // 0.56 then still knows a plugin's event by name but no longer delivers it. Announced again, it does. (The
    // configuration is read again right after a plugin is loaded, so this is every session, not a rare case.)
    g_onReload = Event::bus()->m_events.config.reloaded.listen([] {
        Event::bus()->m_events.pluginEventAdded.emit(g_dragEnd);
        Event::bus()->m_events.pluginEventAdded.emit(g_windowMenu);
    });
    return {"latte-events", "LatteOS: a window let go after a move; a window carried from beside it; a window's menu", "LatteOS", "1.2"};
}

APICALL EXPORT void PLUGIN_EXIT() {
    g_onMove.reset();
    g_onButton.reset();
    g_onReload.reset();
    g_onOpen.reset();
    for (const auto& w : Desktop::windowState()->windows()) {
        const auto toplevel = toplevelOf(w);
        if (toplevel && toplevel->m_resource)
            toplevel->m_resource->setShowWindowMenu(nullptr);  // nothing of the plugin may stay behind it
    }
    HyprlandAPI::removeEvent(g_handle, DRAG_END);
    HyprlandAPI::removeEvent(g_handle, WINDOW_MENU);
}
