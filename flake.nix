{
  description = "My NixOS Flake Configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";  # Adjust according to your NixOS version
  };

  outputs = { self, nixpkgs, ... }@inputs: {
    nixosConfigurations = {
      nixos = nixpkgs.lib.nixosSystem {  # Replace 'nixos' with your actual hostname.
        system = "aarch64-linux";  # According to your system architecture adjustment (view with `uname -m`)
        modules = [
          ./nixos/configuration.nix  # Reference the copied configuration.nix
          # If hardware-configuration.nix is not imported by configuration.nix, it can be explicitly added:
          # ./nixos/hardware-configuration.nix

          # Optional: Add Flake-specific inline configuration
          # ({ pkgs, ... }: {
          #   networking.hostName = "nixos";  # Set hostname
          # })
        ];
      };
    };
  };
}
