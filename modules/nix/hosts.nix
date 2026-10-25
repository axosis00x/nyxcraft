# Build one NixOS configuration for each folder under hosts/.
{
  inputs,
  ...
}:
let
  lib = inputs.nixpkgs.lib;
  hostsDir = ../../hosts;
  hostNames = lib.attrNames (
    lib.filterAttrs (
      name: type: type == "directory" && builtins.pathExists (hostsDir + "/${name}/settings.nix")
    ) (builtins.readDir hostsDir)
  );

  mkSettings =
    hostname:
    let
      file = hostsDir + "/${hostname}/settings.nix";
      settings =
        (lib.evalModules {
          modules = [
            ../../modules/settings.nix
            file
            { inherit hostname; }
          ];
        }).config;
    in
    lib.throwIf (settings.boot.loader == "grub" && settings.boot.grubDevice == "")
      "${toString file}: boot.loader = \"grub\" needs boot.grubDevice (the boot disk, e.g. /dev/sda)."
      settings;

  mkHost =
    hostname:
    let
      settings = mkSettings hostname;
    in
    lib.nixosSystem {
      specialArgs = {
        inherit inputs settings;
      };
      modules = [
        { nixpkgs.hostPlatform = settings.system; }
        ../../modules/host
        (hostsDir + "/${hostname}/hardware-configuration.nix")
        inputs.home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.backupFileExtension = "backup";
          home-manager.extraSpecialArgs = { inherit inputs settings; };
        }
      ];
    };
in
{
  flake.nixosConfigurations = lib.genAttrs hostNames mkHost;
}
