

在 Loongnix 25电脑上运行步骤

1. 把项目拷到目标电脑
将下载的整个目录拷贝到你的 Loongnix 电脑上，例如放到 ~/poweroff-app。

2. 安装（只需一次）

cd ~/poweroff-app

sudo ./install.sh

安装内容：

/usr/local/bin/one-key-poweroff — 主程序

/usr/local/share/applications/one-key-poweroff.desktop — 应用菜单入口

/usr/local/share/icons/.../one-key-poweroff.svg — 图标


3. 日常使用（三种方式任选）
   
方式 A：桌面图标（推荐普通用户）​

在应用菜单搜索「一键关机」，点击 → 弹出确认框 → 点「立即关机」。

方式 B：终端命令

one-key-poweroff              # 打开图形界面

one-key-poweroff --now        # 立即关机（会先确认一次）

one-key-poweroff --delay 300  # 5 分钟后关机

one-key-poweroff --cancel     # 取消关机


方式 C：绑定快捷键（真·一键）
​

在系统设置的「键盘 → 快捷键」里新建自定义快捷键，命令填：

one-key-poweroff --now


之后按下该快捷键 → 确认框弹出 → 关机。若想按了就直接关、不弹确认，先编辑 /usr/local/share/one-key-poweroff/config.sh 把 CONFIRM=1 改成 CONFIRM=0。
