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

    # Provide a formatter for `nix fmt`
    formatter = {
      aarch64-linux = (import nixpkgs { system = "aarch64-linux"; }).alejandra;
      x86_64-linux = (import nixpkgs { system = "x86_64-linux"; }).alejandra;
    };

    # Simple development shells
    devShells = {
      aarch64-linux.default = let pkgs = import nixpkgs { system = "aarch64-linux"; }; in pkgs.mkShell {
        packages = with pkgs; [ alejandra nixd git ];
      };
      x86_64-linux.default = let pkgs = import nixpkgs { system = "x86_64-linux"; }; in pkgs.mkShell {
        packages = with pkgs; [ alejandra nixd git ];
      };
    };
  };
}
