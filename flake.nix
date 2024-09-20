{
  description = "A Nix flake for Metaseqoia";

  inputs.erosanix.url = "github:emmanuelrosa/erosanix";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/master";
  inputs.nix-gaming.url = "github:fufexan/nix-gaming";

  outputs = {
    self,
    nixpkgs,
    erosanix,
    ...
  }: {
    packages.x86_64-linux = let
      pkgs = import "${nixpkgs}" {
        system = "x86_64-linux";
      };

      # I have tried unstable, and wine-ge can not seem to find it :(
      # sources = (import "${self.inputs.nixpkgs}/pkgs/applications/emulators/wine/sources.nix" {inherit pkgs;}).unstable;
      # mono = pkgs.fetchurl rec {
      #   version = "8.1.0";
      #   url = "https://dl.winehq.org/wine/wine-mono/${version}/wine-mono-${version}-x86.msi";
      #   hash = "sha256-DtPsUzrvebLzEhVZMc97EIAAmsDFtMK8/rZ4rJSOCBA=";
      # };

      wine = self.inputs.nix-gaming.packages.x86_64-linux.wine-ge.override {
        # monos = [
        #   mono
        # ];
      };
      baseMetaseqoia = pkgs.callPackage ./metaseqoia.nix {
        inherit self;
        inherit (erosanix.lib.x86_64-linux) mkWindowsApp makeDesktopIcon copyDesktopIcons;
        inherit wine;
      };
    in {
      metaseqoiaBigDPI = baseMetaseqoia.override {
        setDPI = 90;
      };
      metaseqoia =
        baseMetaseqoia.override {
        };
      default = self.packages.x86_64-linux.metaseqoia;

      inherit baseMetaseqoia;
      inherit wine;
    };

    apps.x86_64-linux.metaseqoia = {
      type = "app";
      program = "${self.packages.x86_64-linux.metaseqoia}/bin/metaseqoia";
    };

    apps.x86_64-linux.default = self.apps.x86_64-linux.metaseqoia;
  };
}
