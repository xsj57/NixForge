<div align="center">

<h1> NixOS Virtual Machine Configuration </h1>
<p>

![nixos](/file/fastsetch.png)

<p>

<p><a href="README.md">简体中文</a> | English</p>
<img src="https://img.shields.io/badge/MBP%20M1%20Pro-Tahoe-000000?logo=apple&logoColor=white" alt="MBP M1 Pro"></a>
<img src="https://img.shields.io/badge/UTM-NixOS%2025.05-5277C3?logo=nixos&logoColor=white" alt="UTM"></a>
<p>
<p>

</div>

## Quick Start

1. [enable SSH](#enable-ssh)
2. [UTM file sharing](#virtfs-file-sharing)
3. [Migrate to flake](#migrate-to-flake)
4. [Install lazyvim](#install-lazyvim)
5. [Install yazi](#install-yazi)
6. [Chinese Input Method](#chinese-input-method-fcitx5)
7. [GNOME Enhancements](#gnome-enhancements)
8. [Modify default font](#set-jetbrains-mono-as-default-font)
9. [Related Items](#related-projects)

### enable SSH

Add the following section in `configuration.nix`:

```
{ config, pkgs, ... }:
{
  ...

  # enable OpenSSH
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";  # Recommendation: Prohibit root login to improve security
      PasswordAuthentication = true;  # Allow password login
    };
  };

  # Allow SSH ports through the firewall (if the firewall is enabled)
  networking.firewall = {
    enable = true;  # If enabled, maintain
    allowedTCPPorts = [ 22 ];  # Default SSH port
  };

  ...
}
```

### VirtFS File Sharing

1. Enter the terminal on the host (macOS) and replace `~/share`with the location of the folder in the host

```
chmod -R 777 ~/share  # Grant full permissions (read/write/execute) to all files/directories
chown -R $USER:staff ~/share  # The ownership is preserved for the current macOS user.
ls -lR ~/share  # Verify permissions (should show drwxrwxrwx)
sudo reboot
```

2. Add the following section in `configuration.nix`, replacing the example path with your actual mount point in NixOS (e.g. `/home/ericxu/Downloads/Share` or `/mnt/share`):

```
{ config, pkgs, ... }:
{
  ...

  environment.systemPackages = with pkgs; [
    spice-vdagent # Visitor Tools
    virtiofsd
  ];

  # Enable required kernel modules
  boot.initrd.availableKernelModules = [ "virtio" "9p" ];

  # Automatically mount shared directories and set permission mapping
  fileSystems."/mnt/share" = {
    device = "share";
    fsType = "9p";
    options = [ "trans=virtio" "version=9p2000.L" "cache=loose" "msize=8192" "uid=1000" "gid=100" "access=client" "dmask=0777" "fmask=0666" ];  # Replace with your UID/GID, dmask/fmask ensure subfolder permissions
  };

  # Add systemd service: Recursively adjust permissions after mounting
  systemd.services.fix-share-permissions = {
  description = "Fix permissions on /mnt/share recursively";
    # Note: `after` must match the mount unit name. Systemd converts a path to a unit name:
    # e.g. /mnt/share -> mnt-share.mount, /home/ericxu/Downloads/Share -> home-ericxu-Downloads-Share.mount
    after = [ "mnt-share.mount" ];  # Run after mount (adjust if your path differs)
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.bash}/bin/bash -c 'chown -R 1000:100 /mnt/share && chmod -R 777 /mnt/share'";  # Replace with your UID/GID
    };
  };

  # Enable QEMU guest support (optional, improves compatibility)
  services.qemuGuest.enable = true

  ...
}

```

3. Rebuild with flake and restart

```
# From the repository root
sudo nixos-rebuild switch --flake .#nixos
sudo reboot
```

### Migrate to flake

1. Add the following section in `configuration.nix`:

```
{ config, pkgs, ... }:
{
  ...

  # Enabling Nix Flakes and nix-command
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  ...
}
```

2. Rebuild configuration and check

```
sudo nixos-rebuild switch #Rebuild and switch system configuration
cat /etc/nix/nix.conf  #Should see ⁠experimental-features = nix-command flakes
sudo systemctl restart nix-daemon.service #Restart the Nix daemon
```

### Install Lazyvim

1. Install neovim and other recommended dependencies, add the following section in `configuration.nix`:

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
    gcc     # C compiler, for Treesitter construction
    nodejs  # Node.js, used for plugin installation and operation
  ];

  ...
}

```

2. Install lazyvim

```
git clone https://github.com/LazyVim/starter ~/.config/nvim
rm -rf ~/.config/nvim/.git
```

### Install yazi

Add the following section in `configuration.nix`:

```
{ config, pkgs, ... }:
{
  ...

  environment.systemPackages = [
    yazi
    starship # Optional, to be used with dotfile
    ffmpeg  # Video/Audio Preview
    pkgs."7zip"    # Modern 7-Zip (7zz)
    jq      # JSON processing
    poppler_utils  # PDF Preview (utils package for poppler)
    # fd     # Installed, commented out
    # ripgrep # Installed, commented out
    # fzf    # Installed, commented out
    zoxide  # Table of Contents Jump (optional, but recommended)
    resvg   # SVG Rendering (optional)
    imagemagick  # Image Processing (recommended)
  ];

  ...
}

```

### Chinese Input Method (fcitx5)

Enable fcitx5 with Chinese addons (Wayland/GTK/Qt supported):

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

Note: the NixOS module sets the necessary environment variables automatically; after logging into GNOME the input method should work.

### GNOME enhancements

Recommended additions for GNOME desktop:

```
{ config, pkgs, ... }:
{
  programs.dconf.enable = true;
  services.gnome.gnome-keyring.enable = true;
  xdg.portal.enable = true;
  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gnome ];
}
```

### Set JetBrains Mono as default font

Add the following section in `configuration.nix`:

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

### Related projects

- Linux mirror switching script: https://github.com/SuperManito/LinuxMirrors
- Dotfiles: https://github.com/xsj57/dotfile
