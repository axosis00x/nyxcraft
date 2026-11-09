{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  cfg = config.userSettings.hyprland;
in
{
  options.userSettings.hyprland = {
    enable = lib.mkEnableOption "Hyprland window manager";
  };
  config = lib.mkIf cfg.enable {
    home.packages =
      (with pkgs; [
        brightnessctl
        kitty
        hyprsunset
        cliphist
        wl-clipboard
        grimblast
        playerctl
        cava
        awww
        wiremix
        grim
        slurp
        quickshell
        hyprpicker
        libnotify
        hyprshade
        zenity
        matugen
        python313Packages.rembg
      ])
      ++ [
        inputs.hyprmod.packages.${pkgs.stdenv.hostPlatform.system}.default
      ];
    xdg.portal = {
      enable = true;
      extraPortals = with pkgs; [
        xdg-desktop-portal-hyprland
        xdg-desktop-portal-gtk
      ];
      configPackages = [ pkgs.hyprland ];
    };
    # No separate polkit agent: the Quickshell shell is the agent
    # (config/quickshell/modules/polkit), and polkitd allows only one.
  };
}
