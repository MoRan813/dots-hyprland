-- User autostart commands (survives dots-hyprland updates)

hl.on("hyprland.start", function()
    -- Input method: fcitx5 + Rime
    hl.exec_cmd("fcitx5 -d --replace")
end)
