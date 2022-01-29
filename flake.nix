{
  description = "Local nixpkgs overlays flake";

  inputs = {
    emacs = {
      url = github:calbrecht/f4s-emacs;
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.f4s-overlays.follows = "";
    };
    firefox-nightly = {
      url = github:calbrecht/f4s-firefox-nightly;
      inputs.nixpkgs.follows = "nixpkgs";
    };
    global-cursor-theme = {
      url = github:calbrecht/f4s-global-cursor-theme;
    };
    nodejs = {
      url = github:calbrecht/f4s-nodejs;
      inputs.nixpkgs.follows = "nixpkgs";
    };
    rust = {
      url = github:calbrecht/f4s-rust;
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

      overlays = (nixpkgs.lib.mapAttrs (_: input: input.overlay) inputs) // {
        wayland = (self: prev:
        let
          selfWaylandPkgs = inputs.wayland.overlay self prev ;
        in
        {
          waylandPkgs = selfWaylandPkgs // {
            swaylock = selfWaylandPkgs.swaylock.overrideAttrs (old: {
              mesonFlags = [
                "-Dpam=enabled"
                "-Dgdk-pixbuf=enabled"
                "-Dman-pages=enabled"
              ];
            });
          };
        });
        fixups = (self: prev: {
          python3 = let
            packageOverrides = python-self: python-super: {
              taskw = python-super.taskw.overridePythonAttrs (old: {
                src = prev.fetchFromGitHub {
                  owner = "ralphbean";
                  repo = "taskw";
                  rev = "3baf339370c7cb4c62d52cb6736ed0cb458a57b5";
                  sha256 = "sha256-cGTQmSATNnImYCxdGAj/yprXCUWzmeOrkWeAE3dEW3Y=";
                };
              });
              bugwarrior = python-super.bugwarrior.overridePythonAttrs (old: {
                src = prev.fetchFromGitHub {
                  owner = "ralphbean";
                  repo = "bugwarrior";
                  rev = "89bff55e533569b7390848f35b9dd95b552e50ae";
                  sha256 = "sha256-ejx6REsmf1GtlpC8lJSLqllx7+BhzjhRKTYDZmVDHIU=";
                };
              });
              pychromecast-9 = python-super.PyChromecast.overridePythonAttrs (old: {
                  src = python-super.fetchPypi {
                    pname = "PyChromecast";
                    version = "9.4.0";
                    sha256 = "sha256-Y8PLrjxZHml7BmklEJ/VXGqkRyneAy+QVA5rusPeBHQ=";
                  };
              });
            };
          in prev.python3.override {inherit packageOverrides;};
          pulseaudio-dlna = prev.pulseaudio-dlna.overridePythonAttrs (old: {
            src = prev.fetchFromGitHub {
              owner = "Cygn";
              repo = "pulseaudio-dlna";
              rev = "3cdcf84184548e91ea25fbe60f3850768e15c2a2";
              sha256 = "sha256-V+r5akxQ40ORvnYqR+q//0VV0vK54Oy1iz+iuQbPOtU=";
            };
            propagatedBuildInputs = [
              prev.python3Packages.pychromecast-9
            ] ++ (nixpkgs.lib.filter (
              pkg: pkg != prev.python3Packages.PyChromecast
            ) old.propagatedBuildInputs);
          });
        });
      };
    };
}
