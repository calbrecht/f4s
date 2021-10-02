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
        waylandPkgs.mako = pkgs.waylandPkgs.mako.overrideAttrs (old: {
          nativeBuildInputs = old.nativeBuildInputs ++ [ pkgs.wrapGAppsHook ];
        });
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

      overlays = (nixpkgs.lib.mapAttrs (_: input: input.overlay) inputs);
    };
}
