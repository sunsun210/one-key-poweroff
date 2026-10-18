# 一键关机 (Loongnix 25.1)
#
# 系统级路径与默认配置。所有文件在安装时通过 @PREFIX@ 宏替换。
# 修改本文件后需重新执行 install.sh 生效。

# ---- 可执行程序 ----
POWEROFF_BIN=/usr/bin/poweroff
SYSTEMCTL_BIN=/usr/bin/systemctl
ZENITY_BIN=/usr/bin/zenity
XTERM_BIN=/usr/bin/xterm

# ---- 关机行为 ----
# 延迟秒数（0 = 立即关机）。poweroff --help 确认支持 -p/--poweroff、-f/--force
DEFAULT_DELAY=0
# 关机前是否等待用户确认（1 开启 / 0 关闭）
CONFIRM=1
# 是否在关机前给所有登录用户发送 wall 广播（1/0），对应 poweroff --no-wall 取反
WALL=1
# 关机命令参数（不含延迟），推荐 "poweroff" 或 "systemctl poweroff"
POWER_CMD="poweroff"

# ---- 日志 ----
# 普通用户不可写 /var/log，故日志放在用户状态目录；可选 systemd journal
# 日志目录（相对用户家目录，避免被 shell 提前展开成字面量）
LOG_SUBDIR=".local/state/one-key-poweroff"
LOG_MAX_LINES=500
USE_JOURNAL=0

# ---- 启动器条目 ----
APP_NAME="一键关机"
APP_COMMENT="立即关闭计算机（调用 poweroff）"
APP_CATEGORIES="System;Utility;"
