{
  description = "AudioRelay - Use your phone as a speaker for your PC";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };

      # Reusable overlay so consumers can add the package to their nixpkgs
      overlay = final: prev: {
        audiorelay = self.packages.${final.system}.audiorelay;
      };

      audiorelay = pkgs.stdenv.mkDerivation rec {
        pname = "audiorelay";
        # You can find new versions on https://community.audiorelay.net/c/releases/9
        version = "1.0.0-alpha07";

        src = pkgs.fetchurl {
          url = "https://dl.audiorelay.net/setups/linux/audiorelay-${version}-x64.tar.gz";
          # When updating the version, make sure to also update the hash to match the new file.
          # This can be done using `nix hash path/to/audiorelay-1.0.0-alpha07-x64.tar.gz --type sha256` after downloading the file.
          hash = "sha256-49D7yIRIQxnGFSUpPwZdekV+iB5V/s/xiD/POJeIOfo=";
        };

        sourceRoot = "AudioRelay";

        nativeBuildInputs = [
          pkgs.autoPatchelfHook
          pkgs.makeWrapper
        ];

        # Runtime library dependencies
        buildInputs = [
          pkgs.alsa-lib
          pkgs.avahi
          pkgs.fontconfig
          pkgs.gdk-pixbuf
          pkgs.gtk3
          pkgs.harfbuzz
          pkgs.libGL
          pkgs.libnotify
          pkgs.ayatana-ido
          pkgs.libayatana-appindicator
          pkgs.libayatana-indicator
          pkgs.libdbusmenu-gtk3
          pkgs.libpulseaudio
          pkgs.libsecret
          pkgs.libx11
          pkgs.libxext
          pkgs.libxi
          pkgs.libxrender
          pkgs.libxtst
        ];



        dontBuild = true;

        installPhase = ''
          runHook preInstall
          mkdir -p $out
          cp -r bin lib $out/

          # Lowercase alias so `audiorelay` works in the shell
          ln -s $out/bin/AudioRelay $out/bin/audiorelay

          # Icon
          install -Dm644 lib/AudioRelay.png $out/share/icons/hicolor/256x256/apps/audiorelay.png

          # Desktop entry
          mkdir -p $out/share/applications
          cat > $out/share/applications/audiorelay.desktop <<EOF
          [Desktop Entry]
          Name=AudioRelay
          Comment=Stream audio from your PC to your phone
          Exec=$out/bin/AudioRelay
          Icon=audiorelay
          Terminal=false
          Type=Application
          Categories=Audio;Network;
          Keywords=audio;relay;stream;phone;
          EOF
          runHook postInstall
        '';

        # Tell autoPatchelfHook where to find the bundled libjvm.so and other
        # JVM-internal libraries that the bundled .so files link against.
        preFixup = ''
          addAutoPatchelfSearchPath $out/lib/runtime/lib
          addAutoPatchelfSearchPath $out/lib/runtime/lib/server
        '';

        meta = with pkgs.lib; {
          description = "Stream audio from your PC to your Android/iOS device";
          homepage = "https://audiorelay.net";
          license = licenses.unfree;
          maintainers = [ ];
          platforms = [ "x86_64-linux" ];
          mainProgram = "AudioRelay";
        };
      };
    in
    {
      packages.${system} = {
        default = audiorelay;
        audiorelay = audiorelay;
      };

      apps.${system}.default = {
        type = "app";
        program = "${audiorelay}/bin/AudioRelay";
      };

      overlays.default = overlay;

      # NixOS module — add `inputs.nix-audiorelay.nixosModules.audiorelay` to your modules list
      nixosModules.audiorelay = { config, lib, pkgs, ... }: {
        options.programs.audiorelay.enable = lib.mkEnableOption "AudioRelay";

        config = lib.mkIf config.programs.audiorelay.enable {
          nixpkgs.overlays = [ overlay ];
          nixpkgs.config.allowUnfree = true;
          environment.systemPackages = [ pkgs.audiorelay ];
        };
      };

      # Home Manager module — add `inputs.nix-audiorelay.homeManagerModules.audiorelay` to your modules list
      homeManagerModules.audiorelay = { config, lib, pkgs, ... }: {
        options.programs.audiorelay.enable = lib.mkEnableOption "AudioRelay";

        config = lib.mkIf config.programs.audiorelay.enable {
          nixpkgs.overlays = [ overlay ];
          home.packages = [ pkgs.audiorelay ];
        };
      };
    };
}
