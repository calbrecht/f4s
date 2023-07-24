{
  description = "Local nixpkgs overlays flake";

  nixConfig = {
    flake-registry = https://github.com/calbrecht/f4s-registry/raw/main/flake-registry.json;
  };

  inputs = {
    systems.url = github:nix-systems/x86_64-linux;
    flake-utils = {
      url = github:numtide/flake-utils;
      inputs.systems.follows = "systems";
    };
    emacs = {
      url = flake:f4s-emacs;
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.rust.follows = "rust";
      inputs.nodejs.follows = "nodejs";
      inputs.fixups.follows = "fixups";
    };
    firefox-nightly = {
      url = flake:f4s-firefox-nightly;
      inputs.nixpkgs.follows = "nixpkgs";
    };
    fixups = {
      url = flake:f4s-fixups;
      inputs.nixpkgs.follows = "nixpkgs";
    };
    global-cursor-theme = {
      url = flake:f4s-global-cursor-theme;
    };
    nodejs = {
      url = flake:f4s-nodejs;
      inputs.nixpkgs.follows = "nixpkgs";
    };
    rust = {
      url = flake:f4s-rust;
      inputs.nixpkgs.follows = "nixpkgs";
    };
    wayland = {
      url = github:nix-community/nixpkgs-wayland;
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, flake-utils, ... }@inputs:
  {
    overlays = with nixpkgs.lib; recursiveUpdate (
      mapAttrs (_: i: i.overlays.default or i.overlay) inputs
    ) {
      wayland = (self: prev:
      let
        selfWaylandPkgs = inputs.wayland.overlays.default self prev ;
      in
      {
        waylandPkgs = recursiveUpdate selfWaylandPkgs {
          #swaylock = selfWaylandPkgs.swaylock.overrideAttrs (old: {
          #  mesonFlags = [
          #    "-Dpam=enabled"
          #    "-Dgdk-pixbuf=enabled"
          #    "-Dman-pages=enabled"
          #  ];
          #});
        };
      });
    };
  }
  // (flake-utils.lib.eachDefaultSystem (system: let
    pkgs = import nixpkgs {
      inherit system;
      config = {
        allowUnfree = true;
        permittedInsecurePackages = [
          "python2.7-urllib3-1.26.2"
          "python2.7-pyjwt-1.7.1"
        ];
      };
      overlays = with self.overlays; [
        fixups
        rust
        wayland
        nodejs
        emacs
        firefox-nightly
      ];
    };
  in {
    apps = {
      hm = flake-utils.lib.mkApp {
        drv = (pkgs.writeScriptBin "run-home-manager.sh" ''
          pushd /f4s/home
          nix run home-manager -- --flake ./ "''${@}"
        '');
      };
    };
    packages = { default = pkgs.hello; };
    legacyPackages = pkgs // {
      vscode = pkgs.vscode-with-extensions.override {
        vscodeExtensions = with pkgs.vscode-extensions; [ ms-vsliveshare.vsliveshare ];
      };
    };
  }));
}
