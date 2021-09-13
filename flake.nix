{
  description = "Local nixpkgs overlays flake";

  inputs = {
    emacs = { url = github:calbrecht/f4s-emacs; inputs.nixpkgs.follows = "nixpkgs"; };
    firefox-nightly = {
      url = github:calbrecht/f4s-firefox-nightly;
      inputs.nixpkgs.follows = "nixpkgs";
    };
    global-cursor-theme = { url = github:calbrecht/f4s-global-cursor-theme; };
    nodejs = { url = github:calbrecht/f4s-nodejs; inputs.nixpkgs.follows = "nixpkgs"; };
    rust = { url = github:calbrecht/f4s-rust; };
    wayland = { url = github:colemickens/nixpkgs-wayland; inputs.nixpkgs.follows = "nixpkgs"; };
    nixpkgs_steam_fix = { url = path:/ws/nixpkgs; };
  };

  outputs = { self, nixpkgs, nixpkgs_steam_fix, ... }@inputs:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config = { allowUnfree = true; };
        overlays = with self.overlays; [
          rust
          wayland
          nodejs
          emacs
          firefox-nightly
          (self: super: {
            firefox-unwrapped = super.firefox-unwrapped.overrideAttrs (old: {
              patches = (old.patches or [ ]) ++ [
                (self.fetchpatch {
                  url = "https://hg.mozilla.org/integration/autoland/raw-rev/3b856ecc00e4";
                  sha256 = "sha256-d8IRJD6ELC3ZgEs1ES/gy2kTNu/ivoUkUNGMEUoq8r8=";
                })
                (self.fetchpatch {
                  url = "https://hg.mozilla.org/mozilla-central/raw-rev/51c13987d1b8";
                  sha256 = "sha256-C2jcoWLuxW0Ic+Mbh3UpEzxTKZInljqVdcuA9WjspoA=";
                })
              ];
            });
          })
        ];
      };
      steamfixpkgs = import nixpkgs_steam_fix {
        inherit system;
        config = { allowUnfree = true; };
        overlays = with self.overlays; [
          wayland
        ];
      };
    in
    {
      legacyPackages."${system}" = pkgs // {
        steam = steamfixpkgs.steam;
      };
      defaultPackage."${system}" = pkgs.nix-zsh-completions;

      overlays = (nixpkgs.lib.mapAttrs (_: input: input.overlay) inputs);
    };
}
