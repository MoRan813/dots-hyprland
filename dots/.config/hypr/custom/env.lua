-- User environment overrides (survives dots-hyprland updates)

-- Input method: fcitx5 (Rime)
-- Wayland 下不设 GTK_IM_MODULE：fcitx5 的 "Wayland Input method frontend"
-- (zwp_input_method_v2 + text-input-v3) 已接管原生 Wayland 的 GTK3/GTK4 窗口；
-- 再设 GTK_IM_MODULE 会触发 fcitx5 的 "Detect GTK_IM_MODULE being set ..." 警告，
-- 并在部分 GTK 程序里重复提交。个别跑在 Xwayland 上的程序需要时单独覆盖：
--   GTK_IM_MODULE=fcitx <program>
hl.env("QT_IM_MODULE", "fcitx")
hl.env("XMODIFIERS", "@im=fcitx")
hl.env("SDL_IM_MODULE", "fcitx")
