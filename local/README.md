# local/ — 迁移到另一台机器

这套 dotfiles 的真相源是本 fork 的 `custom` 分支。`dots/` 里是会被 `./setup install`
拷贝到 `~/.config` 的内容；`local/` 里是安装器不管、但新机器需要的部分。

## 新机器上

```bash
# 1. 基础系统（Arch + 一个能登录的 tty；不需要桌面）
git clone -b custom https://github.com/MoRan813/dots-hyprland ~/repository/dots-hyprland
cd ~/repository/dots-hyprland

# 2. 一条命令
./local/bootstrap.sh
```

`bootstrap.sh` 依次做：`./setup install`（依赖 + 权限 + 拷贝 dots/，会交互问终端和
shell，选 kitty + fish）→ 装 `packages-*.txt` 里的应用 → 铺 `local/overlay/` →
部署 Rime → 刷字体缓存。

常用变体：

```bash
./local/bootstrap.sh --overlay-only       # 只重铺 overlay 与 Rime 用户配置
./local/bootstrap.sh --skip-apps          # 只装 DE，不装 bitwarden/zen 等应用
./local/bootstrap.sh --with-nvidia-580xx  # 新机也是 GTX 10 系无 GSP 老卡时加这个
```

## 目录

| 路径 | 内容 |
|------|------|
| `dots/` | 由 `./setup install` 拷贝；本机定制已合并进这里（见下） |
| `local/overlay/.config/illogical-impulse/config.json` | shell 运行时偏好（面板开关等），首次启动才生成，安装器不覆盖 |
| `local/overlay/.config/fcitx5/` | 输入法分组（默认 us 布局 + rime）与通知配置 |
| `local/overlay/.local/share/fcitx5/rime/` | `default.custom.yaml`（方案列表 + switcher 热键改造）、`custom_phrase.txt` |
| `local/packages-repo.txt` / `local/packages-aur.txt` | 源机器的 `pacman -Qqe` / `-Qqm`（已剔除 `-debug`） |

## 已并入 dots/ 的本机定制

这些以前只存在于 `~/.config`，`./setup install` 会把它们覆盖掉，现在都在 fork 里：

- `hypr/hypridle.conf` — 不自动锁屏 / 不自动睡眠，只保留手动 `SUPER+L` 与挂起前锁屏
- `hypr/custom/env.lua`、`execs.lua` — fcitx5 环境变量与登录自启
- `quickshell/ii/.../Translator.qml` — 翻译引擎由配置指定，默认 auto 会选不通的 google
- `quickshell/ii/.../InterfaceConfig.qml` — 左栏移除后停用翻译器开关
- `kitty/kitty.conf` — `symbol_map` 把汉字显式指向 Noto Sans Mono CJK SC
- `fontconfig/conf.d/60-noto-cjk-sc.conf` — 全局 CJK 兜底
- `fish/config.fish` — `fnm env --use-on-cd`

## 刻意不迁移

| 路径 | 原因 |
|------|------|
| `~/.config/hypr/hyprland/colors.lua`、`hyprlock/colors.conf`、`fuzzel_theme.ini` | matugen 由壁纸生成，新机器重生成即可 |
| `~/.local/share/fcitx5/rime/build/`、`sync/` | 编译产物与机器状态，首次启动自动重建 |
| `~/.config/illogical-impulse/installed_listfile`、`*.bak` | 安装器内部状态 |
| `~/.config/fish/fish_variables`、`conf.d/fish_frozen_key_bindings.fish` | fish 自动生成 |
| `pacman -Qqm` 里的 `*-debug` | 调试符号包 |
| `nvidia-580xx-*` | 仅 GSP-less 老卡适用，默认排除 |

## 日常维护

```bash
cd ~/repository/dots-hyprland
git stash && git pull          # 拉上游（main 分支的更新）
git rebase main custom         # 或者把上游合并进 custom
./setup exp-update             # 只更新配置，不重装依赖
```

改 `~/.config` 里的东西后，如果希望新机器也拿到，记得把改动同步回 `dots/`：

```bash
cp ~/.config/<path> ~/repository/dots-hyprland/dots/.config/<path>
git -C ~/repository/dots-hyprland diff
```
