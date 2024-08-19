{
  description = "Description for the project";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    pre-commit-hooks.url = "github:cachix/pre-commit-hooks.nix";
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {

      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];

      perSystem =
        {
          config,
          self',
          pkgs,
          system,
          ...
        }:
        {
          _module.args.pkgs = import inputs.nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };

          formatter = pkgs.nixfmt-rfc-style;

          devShells.default = pkgs.mkShell rec {
            inherit (self'.checks.pre-commit-check) shellHook;
            buildInputs =
              with pkgs;
              [
                rustc
                just
                pkg-config
                libxkbcommon
                wayland
              ]
              ++ self'.checks.pre-commit-check.enabledPackages;
            LD_LIBRARY_PATH = "${pkgs.lib.makeLibraryPath buildInputs}";
          };
          checks.pre-commit-check = inputs.pre-commit-hooks.lib.${system}.run {
            src = ./.;
            hooks = {
              # nix
              nixfmt = {
                enable = true;
                package = pkgs.nixfmt-rfc-style;
              };
              flake-checker.enable = true;

              # git
              commitizen.enable = true;

              # rust
              cargo-check.enable = true;
              clippy.enable = true;
              rustfmt.enable = true;
            };
          };
        };
    };
}
