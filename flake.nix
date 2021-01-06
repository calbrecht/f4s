{
  description = "Local nixpkgs overlays flake";

  inputs = {
    emacs = { url = path:./emacs; inputs.nixpkgs.follows = "nixpkgs"; };
    firefox-nightly = { url = path:./firefox-nightly; inputs.nixpkgs.follows = "nixpkgs"; };
    global-cursor-theme = { url = path:./global-cursor-theme; };
    nodejs = { url = path:./nodejs; inputs.nixpkgs.follows = "nixpkgs"; };
    rust = { url = path:./rust; };
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
