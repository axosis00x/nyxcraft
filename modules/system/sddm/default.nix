{
  config,
  lib,
  pkgs,
  inputs,
  settings,
  ...
}:
let
  cfg = config.systemSettings.sddm;
  mocu-xcursor = pkgs.callPackage ../../user/looks/mocu-xcursor.nix { };
in
{
  imports = [ inputs.silentSDDM.nixosModules.default ];
  options.systemSettings.sddm = {
    enable = lib.mkEnableOption "SilentSDDM display manager";
    theme = lib.mkOption {
      type = lib.types.str;
      default = "ken";
      description = "SilentSDDM theme to use.";
    };
    user = lib.mkOption {
      type = lib.types.str;
      default = settings.username;
      description = "User to set the SDDM avatar for.";
    };
    avatar = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      description = "Default avatar image, used until the user picks one (~/.face).";
      default = ../../../assets/pfp.png;
    };
  };
  config = lib.mkIf cfg.enable {
    programs.silentSDDM = {
      enable = true;
      theme = cfg.theme;
    };

    environment.systemPackages = [ mocu-xcursor ];
    services.displayManager.sddm.settings.Theme = {
      CursorTheme = "Mocu-Black-Right";
      CursorSize = "24";
    };
    # Set Qt's cursor theme and search path for the greeter.
    services.displayManager.sddm.settings.General.GreeterEnvironment =
      lib.mkForce "QML2_IMPORT_PATH=${config.programs.silentSDDM.package'}/share/sddm/themes/silent/components/,QT_IM_MODULE=qtvirtualkeyboard,XCURSOR_THEME=Mocu-Black-Right,XCURSOR_SIZE=24,XCURSOR_PATH=${mocu-xcursor}/share/icons";
    # Apply the cursor theme through X resources as well.
    services.displayManager.sddm.setupScript = ''
      export XCURSOR_PATH="${mocu-xcursor}/share/icons:/run/current-system/sw/share/icons"
      ${pkgs.xrdb}/bin/xrdb -merge - <<'EOF'
      Xcursor.theme: Mocu-Black-Right
      Xcursor.size: 24
      EOF
    '';

    systemd.tmpfiles.rules = lib.mkIf (cfg.avatar != null) [
      "f+ /var/lib/AccountsService/users/${cfg.user} 0600 root root - [User]\\nIcon=/var/lib/AccountsService/icons/${cfg.user}\\n"
    ];

    # Copy ~/.face to AccountsService for the greeter; use the default if absent.
    systemd.services.nyxcraft-pfp-sync = lib.mkIf (cfg.avatar != null) {
      description = "Copy the profile picture to the login screen";
      wantedBy = [ "multi-user.target" ];
      serviceConfig.Type = "oneshot";
      script =
        let
          face = "${config.users.users.${cfg.user}.home}/.face";
          icon = "/var/lib/AccountsService/icons/${cfg.user}";
          # Read as the user and cap the copied image at 16 MiB.
          asUser = "${pkgs.util-linux}/bin/runuser -u ${cfg.user} --";
        in
        ''
          mkdir -p /var/lib/AccountsService/icons
          if ! { ${asUser} test -f ${face} && ${asUser} head -c 16777216 ${face} > ${icon}.new; }; then
            cp -f ${cfg.avatar} ${icon}.new
          fi
          chmod 0644 ${icon}.new
          mv -f ${icon}.new ${icon}
        '';
    };
    systemd.paths.nyxcraft-pfp-sync = lib.mkIf (cfg.avatar != null) {
      wantedBy = [ "multi-user.target" ];
      pathConfig.PathChanged = "${config.users.users.${cfg.user}.home}/.face";
    };
  };
}
