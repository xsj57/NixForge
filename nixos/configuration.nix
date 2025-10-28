# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Asia/Shanghai";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Enable the GNOME Desktop Environment.
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.ericxu = {
    isNormalUser = true;
    description = "ericxu";
    shell = pkgs.fish;
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [
    #  thunderbird
    ];
  };
  
  # enbale fish
  programs.fish.enable = true;

  # Install firefox.
  programs.firefox.enable = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [ 
    #qemu-guest-agent
    spice-vdagent  # Visitor Tools
    pkgs._9pfs
    pkgs.virtiofsd
    fish
    ghostty
    git
    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    wget
    curl
    fastfetch
    neovim
    fd
    ripgrep
    fzf
    lazygit
    gcc # C Compiler, for Treesitter construction
    nodejs # Node.js，Used for plugin installation and operation
    yazi
    starship
    #ffmpeg  # Video/Audio Preview
    _7zz    # Basic 7z support (use this as a replacement if _7zz-rar does not work)
    jq      # JSON processing
    #poppler_utils  # PDF Preview
    zoxide  # Table of Contents Jump (optional, but recommended)
    resvg   # SVG rendering (optional)
    #imagemagick  # Image Processing (recommended)
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.05"; # Did you read the comment?
  
  # enable flake
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  
  # Enable required kernel modules
  boot.initrd.availableKernelModules = [ "virtio" "9p" ];

  # Automatically mount the shared directory and set permission mapping
  fileSystems."/home/ericxu/Downloads/Share" = {
    device = "share";  # UTM Default Tags
    fsType = "9p";
    options = [ "trans=virtio" "version=9p2000.L" "cache=loose" "msize=8192" "uid=1000" "gid=100" "access=client" "dmask=0777" "fmask=0666" ]; 
  };
  
   # Add systemd service: Recursively adjust permissions after mounting
  systemd.services.fix-share-permissions = {
  description = "Fix permissions on /home/ericxu/Downloads/Share recursively";
    after = [ "mnt-share.mount" ];  # After mounting, run
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.bash}/bin/bash -c 'chown -R 1000:100 /home/ericxu/Downloads/Share && chmod -R 777 /home/ericxu/Downloads/Share'";  # Replace with your UID/GID
    };
  };

  # Enable QEMU guest support (optional, improves compatibility)
  services.qemuGuest.enable = true;

  # enable OpenSSH
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";  # Recommended: disable root login, improve security
      PasswordAuthentication = true;  # Allow password login
    };
  };

  # Allow SSH port to pass through the firewall (if the firewall is enabled)
  networking.firewall = {
    enable = true;  # If enabled, maintain
    allowedTCPPorts = [ 22 ];  # Default SSH port
  };
}
