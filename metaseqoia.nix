{
  stdenv,
  lib,
  mkWindowsApp,
  wine,
  fetchurl,
  makeDesktopItem,
  makeDesktopIcon, # This comes with erosanix. It's a handy way to generate desktop icons.
  copyDesktopItems,
  copyDesktopIcons, # This comes with erosanix. It's a handy way to generate desktop icons.
  unzip,
  system,
  self,
  pkgs,
  setDPI ? null,
}: let
  # This registry file sets winebrowser (xdg-open) as the default handler for
  # text files, instead of Wine's notepad.
  pname = "metaseqoia";
  txtReg = ./txt.reg;
  # Contains GPU cache, code cache, window state,
  # and the machine's unique license sig
  stateDir = "$HOME/.local/share/${pname}/roaming";

  setDPIReg = pkgs.writeText "set-dpi-${toString setDPI}.reg" ''
    Windows Registry Editor Version 5.00
    [HKEY_LOCAL_MACHINE\System\CurrentControlSet\Hardware Profiles\Current\Software\Fonts]
    "LogPixels"=dword:${toString setDPI}
  '';
in
  mkWindowsApp rec {
    inherit wine pname;

    version = "24.2.2";

    src = builtins.fetchurl {
      url = "https://metaseq2.sakura.ne.jp/metaseq/Metaseq490a_x64_Installer.exe";
      # sha256 = lib.fakeHash;
      sha256 = "sha256:0gaizqhs953hp0xvmqsxawvd6a206mqydfi6hrad7504xhj5xmdz";
    };

    dontUnpack = true;
    wineArch = "win64";

    enableInstallNotification = true;
    # This should work, but it doesn't seem to?
    # More testing required.
    # fileMap = {
    #   "${stateDir}" = "drive_c/users/$USER/AppData/Roaming/Metaseqoia";
    # };
    enableMonoBootPrompt = false;
    fileMapDuringAppInstall = false;
    persistRegistry = false;
    # FIXME: runtime layer lacks persistance
    persistRuntimeLayer = true;
    # persistRuntimeLayer = false;
    inputHashMethod = "store-path";

    nativeBuildInputs = [unzip copyDesktopItems copyDesktopIcons];

    winAppInstall =
      # doubt that this actually helps
      # winetricks -q corefonts
      ''
        # https://askubuntu.com/questions/29552/how-do-i-enable-font-anti-aliasing-in-wine
        winetricks -q settings fontsmooth=rgb
        $WINE ${src} /silent
        regedit ${txtReg}
        regedit ${./use-theme-none.reg}
        regedit ${./wine-breeze-dark.reg}
        mkdir -p $WINEPREFIX/${stateDir}
      ''
      + lib.optionalString (setDPI != null) ''
        regedit ${setDPIReg}
      '';
    winAppPreRun = ''
      mkdir -p $WINEPREFIX/${stateDir}
    '';

    winAppRun = ''
      mkdir -p $WINEPREFIX/${stateDir}
      wine "$WINEPREFIX/drive_c/Program Files/Metaseqoia/Metaseqoia.exe" "$ARGS"
    '';

    winAppPostRun = "";

    installPhase = ''
      runHook preInstall
      ln -s $out/bin/.launcher $out/bin/${pname}
      runHook postInstall
    '';

    desktopItems = let
      mimeTypes = [
        "application/x-Metaseqoia"
        "application/x-metaseqoia"
      ];
    in [
      (makeDesktopItem {
        inherit mimeTypes;

        name = pname;
        exec = pname;
        icon = pname;
        desktopName = "Metaseqoia for Windows";
        genericName = "3D CAD software for Windows-using artists, I guess.";
        categories = ["Graphics" "Viewer"];
      })
    ];

    desktopIcon = makeDesktopIcon {
      name = "metaseqoia";

      src = fetchurl {
        url = "https://www.metaseqoia.xyz/_next/image?w=256&q=75&url=%2F_next%2Fstatic%2Fmedia%2Ficon_256x256.09a58ec3.png";
        sha256 = "sha256-OAmFMeIsrMogwTYiney7rNcKkjbSj/64kGb+6zdbRtA=";
      };
    };

    meta = with lib; {
      description = "Metaseqoia (Proton version)";
      homepage = "https://www.metaseqoia.xyz/";
      license = licenses.unfree;
      maintainers = with maintainers; [];
      platforms = ["x86_64-linux"];
    };
  }
