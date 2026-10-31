{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.userSettings.games;
in
{
  options.userSettings.games = {
    enable = lib.mkEnableOption "gaming tools";
  };
  config = lib.mkIf cfg.enable {
    home.packages =
      with pkgs;
      [
        # steam
        # prismlauncher
      ]
      ++ [
        (inputs.polymc.packages.${pkgs.stdenv.hostPlatform.system}.default.override {
          gamemodeSupport = pkgs.stdenv.hostPlatform.isLinux;
        })
      ];
  };
}
