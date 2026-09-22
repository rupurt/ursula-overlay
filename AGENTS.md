# Working on ursula-overlay

This repository packages the Ursula server and `ursulactl` from source. Keep the
flake small: one pinned release, two packages, a default server package, a Nixpkgs
overlay, and a shell containing both tools. Read README.md for usage and upgrades.

- Keep release, source hash, Cargo hash, Rust toolchain, and protoc handling in
  `pkgs/ursula.nix`. The CLI derivation inherits those inputs; do not duplicate pins.
- Match the tagged source's `rust-toolchain.toml`. Do not use `RUSTC_BOOTSTRAP`.
- Preserve fixed hashes and `flake.lock`. Do not update unrelated inputs during
  a package extraction or release change.
- Build from source and retain the installed CLI smoke checks. Upstream networking
  tests belong outside the Nix sandbox.
- Run `nix flake check` and `nix flake check --all-systems --no-build` after package
  or flake changes. Verify `nix run . -- --help` and `nix run .#ursulactl -- --version`
  when changing package outputs. Report platforms that were only evaluated.
- Run downstream client integration tests when changing release pins or build
  behavior. The sibling `ursula-zig` checkout has `just test integration`.
- Keep the overlay's packages identical to the direct flake packages. Its public
  names are `pkgs.ursula` and `pkgs.ursulactl`.
- Update README.md with public commands, pin changes, and validation limits.
- Preserve existing user changes and the MIT license. Keep build results out of
  Git. Do not publish or push without user authorization.
