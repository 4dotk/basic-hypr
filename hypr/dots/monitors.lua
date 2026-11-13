------------------
---- MONITORS ----
------------------

-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto",
    scale    = "1.2",
})

hl.config({
    xwayland = {
        force_zero_scaling = true, -- X11 apps draw at native res (sharp); scale them per app
    },
})
