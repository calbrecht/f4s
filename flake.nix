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
  };

  outputs = { self, nixpkgs, ... }@inputs:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config = { allowUnfree = true; };
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

        silo = with pkgs; with libsForQt5; stdenv.mkDerivation {
          pname = "silo";
          version = "git-2021-09-19-78ba44abe8";
          src = fetchfossil {
            url = "https://code.jessemcclure.org/silo/";
            rev = "78ba44abe8";
            sha256 = "sha256-nfp520cdS9bUGQv8AfN5dK60YCmkM1gQDL8FTA4WqeM=";
          };
          nativeBuildInputs = [ wrapQtAppsHook pkgconf ];
          buildInputs = [
            qtbase
            wayland
            layer-shell-qt
          ];
          patchPhase = ''
            substituteInPlace ./Makefile \
            --replace '/usr/include/LayerShellQt' '${layer-shell-qt}/include/LayerShellQt' \
            --replace '= /usr' '= ${placeholder "out"}'

            substituteInPlace ./src/barwin.cpp \
            --replace \
            'case C | Key_Q:          end(0);            break;' \
            'case C | Key_G:          end(0);            break;
             case C | Key_N:          sel(+1);           break;
             case C | Key_P:          sel(-1);           break;
             case C | Key_F:          move(+1);          break;
             case C | Key_B:          move(-1);          break;
             case C | Key_E:          move(+MAX);        break;
             case C | Key_A:          move(-MAX);        break;
             case C | Key_D:          del(+1);           break;
             case C | Key_H:          del(-1);           break;
             case C | Key_K:          del(+MAX);         break;
             case C | A | Key_H:      del(-MAX);         break;
             case C | Key_M:          end(1);            break;
             case C | A | Key_M:      end(2);            break;
             case C | Key_Q:          end(0);            break;' \
            --replace \
            'case     Key_Tab:        sel(+1);           break;' \
            'case     Key_Tab:        complete(0);       break;'
          '';
          installTargets = "install-extra";
          postInstall = ''
            #mkdir -p $out/etc/xdg
            #cp -R $out/share/doc/silo $out/etc/xdg/
          '';
          outputs = [ "out" "dev" ];
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
            imv = selfWaylandPkgs.imv.overrideAttrs (old: {
              src = pkgs.fetchgit {
                url = "https://git.sr.ht/~exec64/imv";
                rev = "c7306a6325df0282c16d60b7201b6bd963f76756";
                sha256 = "sha256-KApnP6W/mYKjPHIhZAMgjHC/64D9JjG6hZutvH70HXw=";
              };
            });
          };
        });
      };
    };
}
