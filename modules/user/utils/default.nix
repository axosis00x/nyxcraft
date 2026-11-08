{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.userSettings.utils;
in
{
  options.userSettings.utils = {
    enable = lib.mkEnableOption "utils utilities";
  };
  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      wget
      tldr
      curl
      glib
      gsettings-desktop-schemas
      vips
      util-linux
      libsecret
      file
    ];
  };
}
