{
  description = "Local nixpkgs overlays flake";

  inputs = {
    emacs.url = "github:calbrecht/f4s-emacs";
    emacs.inputs.fixups.follows = "fixups";
    emacs.inputs.flake-parts.follows = "flake-parts";
    emacs.inputs.nixpkgs.follows = "nixpkgs";
    emacs.inputs.nodejs.follows = "nodejs";
    emacs.inputs.rust.follows = "rust";
    emacs.inputs.treefmt-nix.follows = "treefmt-nix";
    emacs.inputs.systems.follows = "systems";
    firefox-nightly.url = "github:calbrecht/f4s-firefox-nightly";
    firefox-nightly.inputs.nixpkgs.follows = "nixpkgs";
    fixups.url = "github:calbrecht/f4s-fixups";
    fixups.inputs.nixpkgs.follows = "nixpkgs";
    flake-parts.url = "github:hercules-ci/flake-parts";
    global-cursor-theme.url = "github:calbrecht/f4s-global-cursor-theme";
    nixpkgs.url = "github:nixos/nixpkgs";
    nodejs.url = "github:calbrecht/f4s-nodejs";
    nodejs.inputs.nixpkgs.follows = "nixpkgs";
    rust.url = "github:calbrecht/f4s-rust";
    rust.inputs.nixpkgs.follows = "nixpkgs";
    systems.url = "github:nix-systems/x86_64-linux";
    treefmt-nix.url = "github:numtide/treefmt-nix";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";
    waybar.url = "github:Alexays/Waybar";
    waybar.inputs.nixpkgs.follows = "nixpkgs";
    wayland.url = "github:nix-community/nixpkgs-wayland";
    wayland.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    inputs:
    let
      inherit (inputs.nixpkgs.lib)
        extends
        flip
        foldl'
        ;
    in
    inputs.flake-parts.lib.mkFlake { inherit inputs; } (top: {
      systems = (import inputs.systems);
      flake.overlays = {
        fixups = inputs.fixups.overlays.default;
        rust = inputs.rust.overlay;
        nodejs = inputs.nodejs.overlay;
        emacs = inputs.emacs.overlays.default;
        wayland = inputs.wayland.overlays.default;
        global-cursor-theme = inputs.global-cursor-theme.overlay;
        firefox-nightly = inputs.firefox-nightly.overlay;
        default =
          final: prev:
          foldl' (flip extends) (_: prev) [
            top.config.flake.overlays.fixups
            top.config.flake.overlays.rust
            top.config.flake.overlays.nodejs
            top.config.flake.overlays.emacs
            top.config.flake.overlays.wayland
            top.config.flake.overlays.global-cursor-theme
            top.config.flake.overlays.firefox-nightly
            (final: prev: {
              vscode = prev.vscode-with-extensions.override {
                vscodeExtensions = with prev.vscode-extensions; [ ms-vsliveshare.vsliveshare ];
              };

              waybar = inputs.waybar.packages.x86_64-linux.waybar;

              foot =
                (prev.foot.override {
                  wayland-protocols = prev.new-wayland-protocols;
                  fcft = prev.fcft;
                }).overrideAttrs
                  (old: {
                    src = prev.fetchFromGitea {
                      domain = "codeberg.org";
                      owner = "dnkl";
                      repo = "foot";
                      rev = "9b776f2d6de39569670dbd76f635c11a383b8971";
                      sha256 = "sha256-6NUebp3NCxwuvEAPURCtN7dQLHiIyiLBRa9vO8ExfW4=";
                    };
                  });
            })
          ] final;
      };
      perSystem =
        {
          system,
          pkgs,
          ...
        }:
        {
          _module.args.pkgs = import inputs.nixpkgs {
            inherit system;
            config = {
              allowUnfree = true;
              permittedInsecurePackages = [
                "openssl-1.1.1v"
              ];
            };
            overlays = [
              top.config.flake.overlays.default
            ];
          };
          legacyPackages = pkgs;
          formatter =
            (inputs.treefmt-nix.lib.evalModule pkgs {
              programs.nixfmt.enable = true;
            }).config.build.wrapper;
        };
    });
}
