--------------------------------
---- WINDOWS AND WORKSPACES ----
--------------------------------

-- See https://wiki.hypr.land/Configuring/Basics/Window-Rules/
-- and https://wiki.hypr.land/Configuring/Basics/Workspace-Rules/

-- Example window rules that are useful

local suppressMaximizeRule = hl.window_rule({
    -- Ignore maximize requests from all apps. You'll probably like this.
    name           = "suppress-maximize-events",
    match          = { class = ".*" },

    suppress_event = "maximize",
})
-- suppressMaximizeRule:set_enabled(false)

hl.window_rule({
    -- Fix some dragging issues with XWayland
    name     = "fix-xwayland-drags",
    match    = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },

    no_focus = true,
})

-- Layer rules also return a handle.
-- local overlayLayerRule = hl.layer_rule({
--     name  = "no-anim-overlay",
--     match = { namespace = "^my-overlay$" },
--     no_anim = true,
-- })
-- overlayLayerRule:set_enabled(false)

-- Blur behind rofi (its background is 90% opaque, see rofi/dots/colors.rasinc).
-- ignore_alpha: don't blur fully transparent pixels, so the blur follows
-- rofi's rounded corners instead of being a square.
hl.layer_rule({
    name         = "blur-rofi",
    match        = { namespace = "^rofi$" },

    blur         = true,
    ignore_alpha = 0.5,
})

-- Screenshot overlays (slurp = 'selection', hyprpicker freeze) must vanish
-- instantly — otherwise their fade-out gets captured and tints the shot.
hl.layer_rule({
    name    = "no-anim-screenshot-overlays",
    match   = { namespace = "^(selection|hyprpicker)$" },

    no_anim = true,
})

-- Hyprland-run windowrule
hl.window_rule({
    name  = "move-hyprland-run",
    match = { class = "hyprland-run" },

    move  = "20 monitor_h-120",
    float = true,
})
