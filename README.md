<div align="center">
<h1> NixOS虚拟机配置 </h1>
<p>

![nixos](/file/fastsetch.png)

<p>

<p>简体中文 | <a href="README.en-US.md">English</a></p>
<img src="https://img.shields.io/badge/MBP%20M1%20Pro-Tahoe-000000?logo=apple&logoColor=white" alt="MBP M1 Pro"></a>
<img src="https://img.shields.io/badge/UTM-NixOS%2025.05-5277C3?logo=nixos&logoColor=white" alt="UTM"></a>
<p>
<p>
</div>

## 快速开始

1. [开启 SSH](#开启ssh)
2. [UTM 文件共享](#virtfs-file-sharing)
3. [迁移至 flake](#flake迁移)
4. [安装 lazyvim](#安装lazyvim)
5. [安装 yazi](#安装yazi)
6. [中文输入法](#中文输入法fcitx5)
7. [GNOME 增强](#gnome-增强)
8. [修改默认字体](#设置-jetbrains-mono-为系统默认字体)
9. [相关项目](#相关项目)

### 开启 SSH

在`configuration.nix`中增加以下部分:

```
{ config, pkgs, ... }:
{
  ...

  # enable OpenSSH
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";  # 推荐：禁止 root 登录，提高安全性
      PasswordAuthentication = true;  # 允许密码登录（或设为 false 只用密钥）
    };
  };

  # 允许 SSH 端口通过防火墙（如果防火墙启用）
  networking.firewall = {
    enable = true;  # 如果已启用，保持
    allowedTCPPorts = [ 22 ];  # 默认 SSH 端口
  };

  ...
}
```

### VirtFS File Sharing

1. 在主机上（macOS）进入终端, `~/share`替换成主机中文件夹的位置

```
chmod -R 777 ~/share  # 赋予所有文件/目录完全权限（读/写/执行）
chown -R $USER:staff ~/share  # 确保所有权为当前 macOS 用户
ls -lR ~/share  # 验证权限（应显示 drwxrwxrwx）
sudo reboot
```

2. 在`configuration.nix`中增加以下部分, 将示例路径替换成你在 NixOS 中的实际挂载位置（例如 `/home/ericxu/Downloads/Share` 或 `/mnt/share`）:

```
{ config, pkgs, ... }:
{
  ...

  environment.systemPackages = with pkgs; [
    spice-vdagent # 访客工具
    virtiofsd
  ];

  # 启用必要内核模块
  boot.initrd.availableKernelModules = [ "virtio" "9p" ];

  # 自动挂载共享目录，并设置权限映射
  fileSystems."/mnt/share" = {
    device = "share";
    fsType = "9p";
    options = [ "trans=virtio" "version=9p2000.L" "cache=loose" "msize=8192" "uid=1000" "gid=100" "access=client" "dmask=0777" "fmask=0666" ];  # 替换为您的 UID/GID；dmask/fmask 确保子文件夹权限
  };

  # 添加 systemd 服务：在挂载后递归调整权限
  systemd.services.fix-share-permissions = {
  description = "Fix permissions on /mnt/share recursively";
    # 注意：after 需要匹配挂载单元名。Systemd 会把路径转成单元名：
    # 例如 /mnt/share -> mnt-share.mount，/home/ericxu/Downloads/Share -> home-ericxu-Downloads-Share.mount
    after = [ "mnt-share.mount" ];  # 在挂载后运行（若路径不同请同步修改）
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.bash}/bin/bash -c 'chown -R 1000:100 /mnt/share && chmod -R 777 /mnt/share'";  # 替换为您的 UID/GID
    };
  };

  # 启用 QEMU 访客支持（可选，提高兼容性）
  services.qemuGuest.enable = true

  ...
}

```

3. 使用 flake 重建并重启

```
# 在仓库根目录
sudo nixos-rebuild switch --flake .#nixos
sudo reboot
```

### flake 迁移

1. 在`configuration.nix`中增加以下部分:

```
{ config, pkgs, ... }:
{
  ...

  # 启用 Nix Flakes 和 nix-command
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  ...
}
```

2. 重建配置并检查

```
sudo nixos-rebuild switch #重建并切换系统配置
cat /etc/nix/nix.conf  #应该看到⁠experimental-features = nix-command flakes
sudo systemctl restart nix-daemon.service #重启 Nix Daemon
```

### 安装 Lazyvim

1. 安装 neovim 和其他推荐的依赖项,在`configuration.nix`中增加以下部分:

```
{ config, pkgs, ... }:
{
  ...

  environment.systemPackages = [
    neovim
    fd
    ripgrep
    fzf
    lazygit
    gcc     # C 编译器，用于 Treesitter 构建
    nodejs  # Node.js，用于插件安装和运行
  ];

  ...
}

```

2. 安装 lazyvim

```
git clone https://github.com/LazyVim/starter ~/.config/nvim
rm -rf ~/.config/nvim/.git
```

### 安装 yazi

在`configuration.nix`中增加以下部分:

```
{ config, pkgs, ... }:
{
  ...

  environment.systemPackages = [
    yazi
    starship #可选,与dotfile搭配使用
    ffmpeg  # 视频/音频预览
    pkgs."7zip"   # 新版 7-Zip (7zz)
    jq      # JSON 处理
    poppler_utils  # PDF 预览（poppler 的 utils 包）
    # fd     # 已安装，注释掉
    # ripgrep # 已安装，注释掉
    # fzf    # 已安装，注释掉
    zoxide  # 目录跳转（可选，但推荐）
    resvg   # SVG 渲染（可选）
    imagemagick  # 图像处理（推荐）
  ];

  ...
}

```

### 中文输入法（fcitx5）

在 `configuration.nix` 中启用 fcitx5 以及中文插件（Wayland/GTK/Qt 均支持）：

```
{ config, pkgs, ... }:
{
  i18n.inputMethod.enabled = "fcitx5";
  i18n.inputMethod.fcitx5.addons = with pkgs; [
    fcitx5-chinese-addons
    fcitx5-gtk
    fcitx5-qt
    fcitx5-configtool
  ];
}
```

说明：使用 NixOS 模块启用后，会自动设置输入法相关环境变量（GTK/QT/XMODIFIERS），登录 GNOME 后即可使用。

### GNOME 增强

推荐在 GNOME 桌面下启用以下增强项：

```
{ config, pkgs, ... }:
{
  programs.dconf.enable = true;
  services.gnome.gnome-keyring.enable = true;
  xdg.portal.enable = true;
  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gnome ];
}
```

### 设置 JetBrains Mono 为系统默认字体

在`configuration.nix`中增加以下部分:

```
{ config, pkgs, ... }:
{
  fonts.packages = with pkgs; [
    jetbrains-mono
    (nerdfonts.override { fonts = [ "JetBrainsMono" ]; })
  ];
  fonts.fontconfig.defaultFonts.monospace = [
    "JetBrainsMono Nerd Font Mono"
    "JetBrainsMono Nerd Font"
    "JetBrains Mono"
  ];

  # Also set GNOME monospace/UI fonts (remove UI if undesired)
  programs.dconf.settings = {
    "org/gnome/desktop/interface" = {
      monospace-font-name = "JetBrainsMono Nerd Font 12";
      font-name = "JetBrainsMono Nerd Font 11";
    };
  };
}
```

### 相关项目

- 更换系统软件源脚本: https://github.com/SuperManito/LinuxMirrors
- Dotfiles: https://github.com/xsj57/dotfile
