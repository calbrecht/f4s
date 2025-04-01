{
  description = "Local nixpkgs overlays flake";

  nixConfig = {
    flake-registry = "https://github.com/calbrecht/f4s-registry/raw/main/flake-registry.json";
  };

  inputs = {
    emacs.url = "flake:f4s-emacs";
    firefox-nightly.url = "flake:f4s-firefox-nightly";
    fixups.url = "flake:f4s-fixups";
    flake-parts.url = "flake:flake-parts";
    global-cursor-theme.url = "flake:f4s-global-cursor-theme";
    nixpkgs.url = "flake:nixpkgs";
    nodejs.url = "flake:f4s-nodejs";
    rust.url = "flake:f4s-rust";
    systems.url = "github:nix-systems/x86_64-linux";
    # alacritty fails with "interface 'wl_surface' has no event 2" since a sway-unwrapped update
    #wayland.url = "github:nix-community/nixpkgs-wayland/2022e1a48a42069c0e5357150504206a0199c94b"; # bad
    # dontcare, use foot
    wayland.url = "github:nix-community/nixpkgs-wayland";  # last known good
    wayland.inputs.nixpkgs.follows = "nixpkgs";
    waybar.url = "github:Alexays/Waybar";
  };

  outputs = inputs: let
    inherit (inputs.nixpkgs.lib)
      extends
      flip
      foldl'
    ;
  in inputs.flake-parts.lib.mkFlake { inherit inputs; } (top: {
    systems = (import inputs.systems);
    flake.overlays = {
      fixups = inputs.fixups.overlays.default;
      rust = inputs.rust.overlay;
      nodejs = inputs.nodejs.overlay;
      emacs = inputs.emacs.overlays.default;
      wayland = inputs.wayland.overlays.default;
      global-cursor-theme = inputs.global-cursor-theme.overlay;
      firefox-nightly = inputs.firefox-nightly.overlay;
      default = final: prev: foldl' (flip extends) (_: prev) [
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
          sway-unwrapped = prev.sway-unwrapped.overrideAttrs (old: {
            mesonFlags = builtins.filter (a: a != "-Dxwayland=enabled") old.mesonFlags;
            patches = builtins.filter (a: (
              a ? name
              && a.name != "libinput-1.27-p1.patch"
              && a.name != "libinput-1.27-p2.patch"
            )) old.patches;
          });
          sway = prev.sway.override {
            sway-unwrapped = final.sway-unwrapped;
          };
          waybar = inputs.waybar.packages.x86_64-linux.waybar;

          foot = (prev.foot.override {
            wayland-protocols = prev.new-wayland-protocols;
            fcft = prev.fcft;
          }).overrideAttrs (old: {
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
    perSystem = { config, system, pkgs, lib, ... }: {
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
    };
  });
}
