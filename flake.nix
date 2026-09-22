{
  description = "Source-built Ursula server and operations CLI";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, rust-overlay, ... }:
    let
      forAllSystems = nixpkgs.lib.genAttrs [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-darwin"
        "x86_64-linux"
      ];
      pkgsFor = system: import nixpkgs {
        inherit system;
        overlays = [ rust-overlay.overlays.default ];
      };
    in
    {
      packages = forAllSystems (system:
        let
          pkgs = pkgsFor system;
          ursula = pkgs.callPackage ./pkgs/ursula.nix { };
        in
        {
          inherit ursula;
          ursulactl = pkgs.callPackage ./pkgs/ursulactl.nix { inherit ursula; };
          default = ursula;
        });

      # Reuse the flake's packages, including its pinned Rust toolchain.
      overlays.default = _final: prev: {
        inherit (self.packages.${prev.stdenv.hostPlatform.system}) ursula ursulactl;
      };

      devShells = forAllSystems (system: {
        default = (pkgsFor system).mkShell {
          packages = with self.packages.${system}; [ ursula ursulactl ];
        };
      });

      # Both packages smoke-test their installed binary with --help.
      checks = forAllSystems (system: {
        inherit (self.packages.${system}) ursula ursulactl;
      });
    };
}
