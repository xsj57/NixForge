<div align="center">
<h1> NixOS虚拟机配置 </h1>
<p>

![nixos](/file/fastsetch.png)

<p>

<p>简体中文 | <a href="README.en-US.md">English</a></p>
<img src="https://img.shields.io/badge/MBP%20M1%20Pro-macOS%20Tahoe-000000?logo=apple&logoColor=white" alt="MBP M1 Pro"></a>
<img src="https://img.shields.io/badge/UTM-NixOS%2025.05-5277C3?logo=nixos&logoColor=white" alt="UTM"></a>
<p>
<p>
</div>

## 快速开始
1. [开启 SSH](#开启ssh)
2. [UTM文件共享](#virtfs-file-sharing)
3. [迁移至flake](#flake迁移)
4. [安装lazyvim](#安装lazyvim)
5. [安装yazi](#安装yazi)
6. [相关项目](#相关项目)

### 开启SSH
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

2. 在`configuration.nix`中增加以下部分, `/mnt/share`更换成NixOS中文件夹的位置:
```
{ config, pkgs, ... }:
{
  ...

  environment.systemPackages = with pkgs; [
    spice-vdagent # 访客工具
    _9pfs
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
    after = [ "mnt-share.mount" ];  # 在挂载后运行
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

3. 保存后重启

```
sudo nixos-rebuild switch
sudo reboot
```
### flake迁移
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

### 安装Lazyvim
1. 安装neovim和其他推荐的依赖项,在`configuration.nix`中增加以下部分:
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
2. 安装lazyvim
```
git clone https://github.com/LazyVim/starter ~/.config/nvim
rm -rf ~/.config/nvim/.git
```

### 安装yazi
在`configuration.nix`中增加以下部分:
```
{ config, pkgs, ... }:
{
  ...

  environment.systemPackages = [
    yazi
    starship #可选,与dotfile搭配使用
    ffmpeg  # 视频/音频预览
    _7zz    # 基本 7z 支持（如果 override 用 _7zz-rar 不行，用这个替换）
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

### 相关项目
- 更换系统软件源脚本: https://github.com/SuperManito/LinuxMirrors
- Dotfiles: https://github.com/xsj57/dotfile