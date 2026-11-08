{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.systemSettings.services;
  username = "axosis00x";
  userCfg = config.users.users.${username};
in
{
  options = {
    systemSettings.services = {
      enable = lib.mkEnableOption "Enable core system services";
    };
  };
  config = lib.mkIf cfg.enable {
    hardware.bluetooth.enable = true;
    services.blueman.enable = true;
    services.power-profiles-daemon.enable = true;

    # Audio services used by the desktop shell.
    services.pipewire = {
      enable = true;
      wireplumber.enable = true;
    };

    networking.firewall = {
      enable = false;
      #   allowedTCPPorts = [ ];
      #   allowedUDPPorts = [ ];
    };

    services.fstrim.enable = true;
    services.earlyoom.enable = true;
    services.fwupd.enable = true;

    services.printing.enable = true;
    zramSwap.enable = true;

    services.avahi = {
      enable = true;
      nssmdns4 = true;
      openFirewall = true;
    };

    security.rtkit.enable = true;

    services.gvfs.enable = true;
    services.udisks2.enable = true;

    services.timesyncd.enable = true;
    services.xserver.enable = true;
    services.xserver.excludePackages = [ pkgs.xterm ];

    services.openssh = {
      enable = false;
      settings.PasswordAuthentication = false;
    };

    services.mpd = {
      enable = true;
      user = username;
      musicDirectory = "${userCfg.home}/Music";
      settings = {
        audio_output = [
          {
            type = "pipewire";
            name = "PipeWire Output";
          }
        ];
      };
    };
    systemd.services.mpd.environment.XDG_RUNTIME_DIR = "/run/user/${toString userCfg.uid}";
  };
}
