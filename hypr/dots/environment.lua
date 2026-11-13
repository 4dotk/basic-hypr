-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------

-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Environment-variables/

hl.env("XCURSOR_THEME", "Robot")
hl.env("XCURSOR_SIZE", "24")

hl.env("HYPRCURSOR_THEME", "Robot")
hl.env("HYPRCURSOR_SIZE", "24")

hl.env("QT_QPA_PLATFORMTHEME", "kde")

-- Steam is X11; with xwayland force_zero_scaling it needs its own scale to match the monitor
hl.env("STEAM_FORCE_DESKTOPUI_SCALING", "1.2")
