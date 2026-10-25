# Shared host configuration and Home Manager users. Each host supplies its
# settings.nix and hardware-configuration.nix.
{ config, settings, ... }:

let
  # Optional host-specific Home Manager configuration.
  hostHome = ../../hosts + "/${settings.hostname}/home.nix";
in

{
  imports = [
    ./configuration.nix
  ];

  config = {
    home-manager.users = builtins.listToAttrs (
      map (user: {
        name = user;
        value = {
          imports = [
            ./home.nix
            ../user
          ]
          ++ (if builtins.pathExists hostHome then [ hostHome ] else [ ]);
          home.username = user;
          home.homeDirectory = config.users.users.${user}.home;
        };
      }) config.systemSettings.users
    );
  };
}
