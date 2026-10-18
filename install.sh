#!/bin/bash
# ==============================================================================
#  一键关机 安装脚本（Loongnix 25.1 / 兼容 sysvinit 或 systemd 的传统发行版）
#
#  用法：
#    sudo ./install.sh              安装到 /usr/local（推荐）
#    sudo ./install.sh --prefix /usr   安装到系统目录
#    sudo ./install.sh --uninstall  卸载
# ==============================================================================

set -eu

PREFIX="/usr/local"
UNINSTALL=0
PROG_NAME="one-key-poweroff"

die() { printf '错误：%s\n' "$*" >&2; exit 1; }
info() { printf '  %s\n' "$*"; }
step() { printf '\n\033[1m==> %s\033[0m\n' "$*"; }

# ---------- 解析参数 ----------
while [ $# -gt 0 ]; do
    case "$1" in
        --prefix)   PREFIX="${2:?--prefix 需要目录参数}"; shift ;;
        --prefix=*) PREFIX="${1#*=}" ;;
        --uninstall|--remove) UNINSTALL=1 ;;
        -h|--help)
            sed -n '4,10p' "$0" | sed 's/^#  \{0,2\}//'
            exit 0 ;;
        *) die "未知参数：$1" ;;
    esac
    shift
done

[ "$(id -u)" -eq 0 ] || die "请用 root 运行：sudo $0 $*"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

BIN_DIR="$PREFIX/bin"
SHARE_DIR="$PREFIX/share/one-key-poweroff"
APPS_DIR="$PREFIX/share/applications"
ICON_DIR="$PREFIX/share/icons/hicolor/scalable/apps"

# ============================ 卸载 ============================
if [ "$UNINSTALL" = "1" ]; then
    step "卸载 一键关机"
    rm -f  "$BIN_DIR/$PROG_NAME"
    rm -f  "$APPS_DIR/$PROG_NAME.desktop"
    rm -f  "$ICON_DIR/$PROG_NAME.svg"
    rm -rf "$SHARE_DIR"
    # 移除可能存在的旧版系统级图标
    rm -f "/usr/share/pixmaps/$PROG_NAME.png" 2>/dev/null || true

    command -v update-desktop-database >/dev/null 2>&1 \
        && update-desktop-database "$APPS_DIR" >/dev/null 2>&1 || true
    command -v gtk-update-icon-cache >/dev/null 2>&1 \
        && gtk-update-icon-cache -qtf "$PREFIX/share/icons/hicolor" >/dev/null 2>&1 || true

    info "已删除：$BIN_DIR/$PROG_NAME"
    info "已删除：$APPS_DIR/$PROG_NAME.desktop"
    info "已删除：$SHARE_DIR"
    printf '\n卸载完成。桌面上的图标若仍存在，请注销后重新登录。\n'
    exit 0
fi

# ============================ 安装 ============================
step "检查环境"
# poweroff 位置因发行版而异（/usr/bin、/bin、/sbin、/usr/sbin），只要求能找到
POWEROFF_PATH="$(command -v poweroff 2>/dev/null || true)"
[ -n "$POWEROFF_PATH" ] || die "未找到 poweroff 命令，本系统可能不支持电源管理"
info "poweroff  : $POWEROFF_PATH"
if command -v systemctl >/dev/null 2>&1; then
    info "systemctl : $(command -v systemctl)"
fi
if command -v zenity >/dev/null 2>&1; then
    info "zenity    : $(command -v zenity)"
else
    info "zenity    : 未安装 —— 图形确认框将不可用"
    printf '\n  \033[33m提示：\033[0m本应用依赖 zenity 显示确认对话框。\n'
    printf '  请先安装：sudo dnf install zenity   （或 yum install zenity）\n'
    printf '  若跳过安装，程序会自动降级为终端确认模式。\n\n'
fi
if [ -e /etc/os-release ]; then
    info "系统      : $(. /etc/os-release; printf '%s' "${PRETTY_NAME:-unknown}")"
fi

step "安装文件到 $PREFIX"
install -d -m 755 "$BIN_DIR" "$SHARE_DIR" "$APPS_DIR" "$ICON_DIR"

# 主程序
install -m 755 "$SCRIPT_DIR/src/bin/$PROG_NAME" "$BIN_DIR/$PROG_NAME"
info "$BIN_DIR/$PROG_NAME"

# 配置
install -m 644 "$SCRIPT_DIR/src/config.sh" "$SHARE_DIR/config.sh"
info "$SHARE_DIR/config.sh"

# 图标
install -m 644 "$SCRIPT_DIR/src/share/icons/hicolor/scalable/apps/$PROG_NAME.svg" \
        "$ICON_DIR/$PROG_NAME.svg"
info "$ICON_DIR/$PROG_NAME.svg"

# 桌面入口（需要把 @变量@ 替换成实际值）
# 从配置里读取 APP_NAME / APP_COMMENT / APP_CATEGORIES
# shellcheck source=/dev/null
. "$SHARE_DIR/config.sh"

sed -e "s|@PREFIX@|$PREFIX|g" \
    -e "s|@ICON_NAME@|$PROG_NAME|g" \
    -e "s|@APP_NAME@|${APP_NAME}|g" \
    -e "s|@APP_COMMENT@|${APP_COMMENT}|g" \
    -e "s|@APP_CATEGORIES@|${APP_CATEGORIES}|g" \
    "$SCRIPT_DIR/src/share/applications/$PROG_NAME.desktop.in" \
    > "$APPS_DIR/$PROG_NAME.desktop"
chmod 644 "$APPS_DIR/$PROG_NAME.desktop"
# desktop 文件必须可执行才被部分桌面环境识别为“可启动”
chmod 755 "$APPS_DIR/$PROG_NAME.desktop"
info "$APPS_DIR/$PROG_NAME.desktop"

step "刷新桌面数据库"
if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database "$APPS_DIR" >/dev/null 2>&1 && info "已更新 MIME/desktop 缓存" || true
else
    info "跳过（未安装 desktop-file-utils）"
fi
if command -v gtk-update-icon-cache >/dev/null 2>&1; then
    gtk-update-icon-cache -qtf "$PREFIX/share/icons/hicolor" >/dev/null 2>&1 \
        && info "已更新图标缓存" || true
fi

step "验证安装"
if [ -x "$BIN_DIR/$PROG_NAME" ]; then
    info "可执行文件就绪"
fi
# 用 --status 自检：只读取系统状态，不弹窗、不触发关机，适合安装时验证
if "$BIN_DIR/$PROG_NAME" --status >/dev/null 2>&1; then
    info "自检通过（--status 正常）"
else
    printf '  \033[33m自检未通过，请执行 %s --status 查看原因。\033[0m\n' "$BIN_DIR/$PROG_NAME"
fi
# 单独验证关机命令拼装是否正确（不执行，仅打印）
if [ "$(id -u)" -eq 0 ]; then
    info "命令预览：$("$BIN_DIR/$PROG_NAME" --dry-run --now 2>&1 | tail -1)"
fi

printf '\n\033[32m安装完成。\033[0m\n\n'
printf '用法：\n'
printf '  %-28s %s\n' "$PROG_NAME" "打开图形界面"
printf '  %-28s %s\n' "$PROG_NAME --now" "立即关机（可绑定快捷键）"
printf '  %-28s %s\n' "$PROG_NAME --delay 300" "5 分钟后关机"
printf '  %-28s %s\n' "$PROG_NAME --cancel" "取消关机"
printf '\n桌面图标：在应用菜单中搜索「一键关机」；或复制到桌面：\n'
printf '  cp %s/%s.desktop ~/桌面/\n' "$APPS_DIR" "$PROG_NAME"
printf '\n调整行为：编辑 %s\n' "$SHARE_DIR/config.sh"
printf '  %-14s %s\n' "DEFAULT_DELAY" "默认延时秒数（0 = 立即）"
printf '  %-14s %s\n' "CONFIRM" "是否弹出确认框（1/0）"
printf '\n'
