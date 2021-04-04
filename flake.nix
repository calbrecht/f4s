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
    nix-zsh-completions-src = { url = github:Ma27/nix-zsh-completions/flakes; flake = false; };
    nixpkgs_steam_fix = { url = path:/ws/nixpkgs; };
  };

  outputs = { self, nixpkgs, nixpkgs_steam_fix, ... }@inputs:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config = { allowUnfree = true; };
        overlays = with self.overlays; [
          nix-zsh-completions
          rust
          wayland
          nodejs
          emacs
          firefox-nightly
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

      overlays = (nixpkgs.lib.mapAttrs (_: input: input.overlay) inputs) //
        {
          nix-zsh-completions = (final: prev: {
            nix-zsh-completions = prev.nix-zsh-completions.overrideAttrs (prev.lib.const {
              src = inputs.nix-zsh-completions-src;
            });
          });
        };
    };
}
