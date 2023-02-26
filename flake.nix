{
  description = "Local nixpkgs overlays flake";

  nixConfig = {
    flake-registry = https://github.com/calbrecht/f4s-registry/raw/main/flake-registry.json;
  };

  inputs = {
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
    home = {
      url = path:/f4s/home;
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, ... }@inputs:
    let
      system = "x86_64-linux";
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
    in
    {
      legacyPackages."${system}" = pkgs // {
        vscode = pkgs.vscode-with-extensions.override {
          vscodeExtensions = with pkgs.vscode-extensions; [ ms-vsliveshare.vsliveshare ];
        };
      };

      defaultPackage."${system}" = pkgs.nix-zsh-completions;

      overlays = with nixpkgs.lib; recursiveUpdate (mapAttrs (_: input: input.overlay) inputs) {
        wayland = (self: prev:
        let
          selfWaylandPkgs = inputs.wayland.overlays.default self prev ;
        in
        {
          waylandPkgs = recursiveUpdate selfWaylandPkgs {
            swaylock = selfWaylandPkgs.swaylock.overrideAttrs (old: {
              mesonFlags = [
                "-Dpam=enabled"
                "-Dgdk-pixbuf=enabled"
                "-Dman-pages=enabled"
              ];
            });
          };
        });
      };

      nixosModules = inputs.home.nixosModules { inherit pkgs; };

      homeConfigurations = inputs.home.homeConfigurations { inherit pkgs; };

      apps."${system}".hm = {
        type = "app";
        program = (pkgs.writeScriptBin "run-home-manager.sh" ''
          nix flake lock --update-input home && nix run ./#home-manager -- "''${@}"
        '') + /bin/run-home-manager.sh;
      };

    };
}
