{
  config,
  lib,
  pkgs,
  settings,
  ...
}:
let
  cfg = config.systemSettings.virtualization;
in
{
  options.systemSettings.virtualization = {
    enable = lib.mkEnableOption "virt-manager and libvirt";
  };
  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      virt-manager
      pkgs.wl-clipboard
    ];
    hardware.graphics.enable32Bit = true;
    virtualisation.libvirtd.enable = true;
    programs.virt-manager.enable = true;
    users.users.${settings.username}.extraGroups = [ "libvirtd" ];

    # Start libvirt's default NAT network after libvirtd on every boot.
    systemd.services.libvirt-default-network = {
      description = "Start libvirt's default NAT network";
      after = [ "libvirtd.service" ];
      requires = [ "libvirtd.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        virsh=${pkgs.libvirt}/bin/virsh
        $virsh net-info default | grep -q '^Active: *yes' || $virsh net-start default
      '';
    };
    # Let VMs on that network reach dnsmasq for DHCP and DNS.
    networking.firewall.trustedInterfaces = [ "virbr0" ];
  };
}
