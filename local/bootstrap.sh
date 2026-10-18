#!/usr/bin/env bash
# 把本机（已配置好的 dots-hyprland）复制到另一台 Arch 机器上。
#
# 在新机器上执行：
#   git clone -b custom https://github.com/MoRan813/dots-hyprland ~/repository/dots-hyprland
#   cd ~/repository/dots-hyprland && ./local/bootstrap.sh
#
# 需要在 tty 或终端里跑：./setup install 会交互式提问（终端选 kitty、shell 选 fish）。
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

SKIP_SETUP=false
SKIP_APPS=false
WITH_NVIDIA_580XX=false
OVERLAY_ONLY=false

usage() {
  cat <<'EOF'
用法: ./local/bootstrap.sh [OPTIONS]

  --skip-setup         不运行 ./setup install（DE 依赖+配置文件已就绪时用）
  --skip-apps          不安装 local/packages-*.txt 里的应用
  --with-nvidia-580xx  一并安装 nvidia-580xx 系列（仅 GSP-less 老卡，如 GTX 10 系）
  --overlay-only       只铺 local/overlay 与 Rime 用户配置，不碰包和 setup
  -h, --help           显示本帮助

不带参数 = 全量：./setup install → 应用包 → overlay → Rime → fontconfig 缓存。
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --skip-setup) SKIP_SETUP=true ;;
    --skip-apps) SKIP_APPS=true ;;
    --with-nvidia-580xx) WITH_NVIDIA_580XX=true ;;
    --overlay-only) OVERLAY_ONLY=true; SKIP_SETUP=true; SKIP_APPS=true ;;
    -h|--help) usage; exit 0 ;;
    *) echo "未知选项: $1" >&2; usage; exit 1 ;;
  esac
  shift
done

say() { printf '\n\033[36m==> %s\033[0m\n' "$*"; }
die() { printf '\033[31m错误: %s\033[0m\n' "$*" >&2; exit 1; }

[[ -f /etc/arch-release ]] || die "本脚本只适用于 Arch Linux（未找到 /etc/arch-release）"
command -v git >/dev/null || die "缺少 git"

# ---------------------------------------------------------------------------
# 1. dots-hyprland 本体：依赖 + 权限/服务 + 配置文件
#    官方安装器负责：pacman/AUR 依赖、group 与 polkit、把 dots/ 拷进 ~/.config
# ---------------------------------------------------------------------------
if [[ "$SKIP_SETUP" == false ]]; then
  say "运行 ./setup install（会交互提问：终端选 kitty、shell 选 fish）"
  ./setup install
else
  say "跳过 ./setup install"
fi

# ---------------------------------------------------------------------------
# 2. 应用与工具（dotfiles 之外的）：两份清单来自源机器的 pacman -Qqe / -Qqm
#    已装的会被 --needed 跳过，可重复执行
# ---------------------------------------------------------------------------
if [[ "$SKIP_APPS" == false ]]; then
  command -v yay >/dev/null || die "缺少 yay；先装 AUR 助手（sudo pacman -S --needed git base-devel && git clone https://aur.archlinux.org/yay.git && cd yay && makepkg -si）"

  mapfile -t pkgs < <(cat local/packages-repo.txt local/packages-aur.txt | grep -v '^\s*$' | sort -u)
  if [[ "$WITH_NVIDIA_580XX" == false ]]; then
    # 580xx 是给没有 GSP 的老卡（GTX 900/10 系）用的分支；新卡装它会反而加载失败
    mapfile -t pkgs < <(printf '%s\n' "${pkgs[@]}" | grep -v '^nvidia-580xx-\|^opencl-nvidia-580xx$')
    echo "（已排除 nvidia-580xx 系列；老卡请加 --with-nvidia-580xx）"
  fi
  echo "计划安装 ${#pkgs[@]} 个包（大部分已由 ./setup install 装好，此处只补齐用户应用）"
  yay -S --needed --noconfirm "${pkgs[@]}"
else
  say "跳过应用包安装"
fi

# ---------------------------------------------------------------------------
# 3. overlay：不进 dots/、也不进安装器的本机定制
#    - illogical-impulse/config.json：shell 运行时偏好（面板开关等），首次启动才生成
#    - fcitx5 profile / notifications：输入法分组与通知
#    - Rime 用户配置：default.custom.yaml（含方案列表与 switcher 热键）、custom_phrase.txt
# ---------------------------------------------------------------------------
say "铺设 overlay 配置"

install_overlay() {
  local src="$1" dst="$2"
  mkdir -p "$(dirname "$dst")"
  if [[ -f "$dst" ]] && cmp -s "$src" "$dst"; then
    echo "  未变  $dst"
    return
  fi
  [[ -f "$dst" ]] && cp -f "$dst" "$dst.bak.$(date +%Y%m%d-%H%M%S)"
  cp -f "$src" "$dst"
  echo "  写入  $dst"
}

# config.json 里存的是绝对路径（源机器是 /home/moran），换用户名后要改写
tmp_overlay="$(mktemp -d)"
trap 'rm -rf "$tmp_overlay"' EXIT
cp -a local/overlay/. "$tmp_overlay"/
if [[ -f "$tmp_overlay/.config/illogical-impulse/config.json" ]]; then
  sed -i "s|/home/moran|$HOME|g" "$tmp_overlay/.config/illogical-impulse/config.json"
fi

while IFS= read -r -d '' f; do
  rel="${f#"$tmp_overlay"/}"
  install_overlay "$f" "$HOME/$rel"
done < <(find "$tmp_overlay" -type f -print0)

# ---------------------------------------------------------------------------
# 4. Rime：rime-ice 方案本体 + 用户配置
# ---------------------------------------------------------------------------
say "部署 Rime（雾凇拼音 rime-ice）"
RIME_DIR="$HOME/.local/share/fcitx5/rime"
mkdir -p "$RIME_DIR"

if [[ ! -f "$RIME_DIR/rime_ice.schema.yaml" ]]; then
  rime_tmp="$(mktemp -d)"
  echo "  克隆 rime-ice 到 $rime_tmp"
  git clone --depth 1 https://github.com/iDvel/rime-ice "$rime_tmp/rime-ice"
  # 只取方案与词库，不带上游 .git；本地已有的文件（含用户词库）保留
  rsync -a --exclude '.git' --ignore-existing "$rime_tmp/rime-ice"/ "$RIME_DIR"/
  rm -rf "$rime_tmp"
else
  echo "  已存在 rime_ice.schema.yaml，跳过克隆"
fi

# 用户配置必须覆盖：上游 default.custom.yaml 没有我们的 switcher 热键定制
for f in default.custom.yaml custom_phrase.txt; do
  src="local/overlay/.local/share/fcitx5/rime/$f"
  [[ -f "$src" ]] || continue
  install_overlay "$src" "$RIME_DIR/$f"
done

# ---------------------------------------------------------------------------
# 5. 收尾
# ---------------------------------------------------------------------------
say "刷新字体缓存"
fc-cache -f >/dev/null 2>&1 || true

say "完成"
cat <<EOF

还需要手动确认的几件事：
  1. 重新登录（或重启）——custom/env.lua 里的环境变量只对新进程生效
  2. 输入法：登录后应自动起 fcitx5；否则 fcitx5 -d --replace
     首次启动会编译 Rime 方案，中文候选出现前的几秒无响应属正常
  3. 屏幕/缩放：general.lua 用的是 mode=preferred + position=auto，多屏再各自用
     nwg-displays 生成 ~/.config/hypr/monitors.lua 即可
  4. 显卡：本机用 AUR nvidia-580xx（GTX 10 系无 GSP）。新机若是较新的卡，
     按 Arch Wiki 装 nvidia-open，别用 580xx
  5. 服务：蓝牙/UPower 等由 ./setup install 处理；mpd 是用户服务
     systemctl --user enable --now mpd
EOF
