{
  description = "Local nixpkgs overlays flake";

  inputs = {
    emacs = { url = github:calbrecht/f4s-emacs; inputs.nixpkgs.follows = "nixpkgs"; };
    firefox-nightly = {
      url = github:calbrecht/firefox-nightly-flake;
      inputs.nixpkgs.follows = "nixpkgs";
    };
    global-cursor-theme = { url = github:calbrecht/f4s-global-cursor-theme; };
    nodejs = { url = github:calbrecht/f4s-nodejs; inputs.nixpkgs.follows = "nixpkgs"; };
    rust = { url = github:calbrecht/f4s-rust; };
    wayland = { url = github:colemickens/nixpkgs-wayland; inputs.nixpkgs.follows = "nixpkgs"; };
  };

  outputs = { self, nixpkgs, ... }@inputs:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        overlays = with self.overlays; [ rust wayland nodejs emacs firefox-nightly ];
      };
    in
    {
      legacyPackages."${system}" = pkgs;

      overlays = nixpkgs.lib.mapAttrs (_: input: input.overlay) inputs;
    };
}
