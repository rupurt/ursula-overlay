# ursula-overlay

A Nix flake that builds the [Ursula](https://github.com/tonbo-io/ursula) durable
streams server and its `ursulactl` operations CLI from source.

Inspired by [zig-overlay](https://github.com/mitchellh/zig-overlay), with a small
set of packages and a Nixpkgs overlay. This repository maintains one pinned
release, currently **v0.5.1**. Release history is available through Git revisions;
there are no nightly channels, binary mirrors, or update automation.

## Usage

From a local checkout, with Nix flakes enabled:

```sh
nix build .#ursula .#ursulactl --no-link
nix run . -- --help
nix run .#ursulactl -- --version
nix develop
# Both ursula and ursulactl are now on PATH.
```

`nix run .` defaults to the server. The first build downloads the pinned Rust
toolchain, source, and Cargo dependencies; subsequent commands reuse Nix's build
results. `nix shell .#ursula .#ursulactl` also makes both tools available.

## Flake outputs

| Output | Contents |
| --- | --- |
| `packages.<system>.ursula` | The Ursula server binary. |
| `packages.<system>.ursulactl` | The operations CLI, built from the same release. |
| `packages.<system>.default` | Alias for `ursula`. |
| `overlays.default` | Adds `pkgs.ursula` and `pkgs.ursulactl`. |
| `devShells.<system>.default` | A shell containing both binaries. |
| `checks.<system>` | Builds both packages and checks their installed CLIs. |

Outputs are provided for `x86_64-linux`, `aarch64-linux`, `x86_64-darwin`, and
`aarch64-darwin`. Both packages have been built and run on x86_64 Linux; the other
platforms have been evaluated but still need native build validation.

## Use from another flake

Add the overlay as an input:

```nix
inputs.ursula-overlay = {
  url = "github:rupurt/ursula-overlay";
  inputs.nixpkgs.follows = "nixpkgs";
};
```

Commit your consumer's `flake.lock` to pin the overlay revision. Update it
deliberately with `nix flake update ursula-overlay` when selecting a newer release.
The packages also run directly from GitHub:

```sh
nix run github:rupurt/ursula-overlay -- --help
nix run github:rupurt/ursula-overlay#ursulactl -- --version
```

Consume the packages directly:

```nix
ursula-overlay.packages.${system}.ursula
ursula-overlay.packages.${system}.ursulactl
```

Or import the overlay into Nixpkgs:

```nix
pkgs = import nixpkgs {
  inherit system;
  overlays = [ ursula-overlay.overlays.default ];
};
# Use pkgs.ursula and pkgs.ursulactl.
```

The overlay exposes the flake's own packages and pinned build inputs; it does not
install rust-overlay into the consumer's package set. Use `nixpkgs.follows` as
above when you want both flakes to share a Nixpkgs revision.

## Packaging and maintenance

`pkgs/ursula.nix` owns the shared release version, source hash, Cargo dependency
hash, and Rust nightly. `pkgs/ursulactl.nix` reuses that build definition and selects
the `ursula-ctl` Cargo package and `ursulactl` binary. `flake.lock` pins Nixpkgs and
rust-overlay. Updating the shared release upgrades both tools together.

The current source is Ursula tag `v0.5.1`, commit
`e6d8d70770e1991d2eedf0ce2c3f74ac01f57f43`, with upstream's Rust nightly
`2026-06-01`. The build uses the upstream release profile and default features.
Its protobuf build scripts use Nix's `protoc` instead of bundled Cargo platform
executables. No prebuilt Ursula release binaries are downloaded.

To upgrade:

1. Check upstream tags/releases and update `version` and the source hash in
   `pkgs/ursula.nix`.
2. Read the tag's `rust-toolchain.toml` and match its nightly. Update the
   `rust-overlay` lock only if it lacks that toolchain.
3. Temporarily set `cargoHash = lib.fakeHash`, build, then replace it with the
   actual hash reported by Nix. Commit real hashes only.
4. Run `nix flake check` to build both packages and execute their `--help` smoke
   checks. Run `nix flake check --all-systems --no-build` to evaluate all outputs.
5. Run downstream client integration tests, then update this README and commit
   the pins. Consumers update their input with `nix flake update ursula-overlay`.

Upstream's network-dependent cluster tests are not run in the Nix sandbox.
Package checks validate the installed CLIs, not distributed durability, TLS,
or cluster operations. The sibling `ursula-zig` project supplies opt-in live
HTTP integration tests with `nix develop --command just test integration`.

## License

The packaging is [MIT licensed](LICENSE). Ursula itself is
[Apache-2.0 licensed](https://github.com/tonbo-io/ursula/blob/v0.5.1/LICENSE).
