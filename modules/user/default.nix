{
  config,
  lib,
  pkgs,
  settings,
  ...
}:

{
  imports = [
    ./hyprland
    ./coding
    ./git
    ./media
    ./games
    ./looks
    ./shell
    ./utils
    ./applications
    ./extra
    ./wayclick
  ];

  xdg.configFile = {
    btop.source = config.lib.file.mkOutOfStoreSymlink "${settings.repoPath}/config/btop";
    # Link CAVA files individually so apply-theme.sh can switch themes/current.
    "cava/config".source =
      config.lib.file.mkOutOfStoreSymlink "${settings.repoPath}/config/cava/config";
    "cava/shaders".source =
      config.lib.file.mkOutOfStoreSymlink "${settings.repoPath}/config/cava/shaders";
    "cava/themes/solarized_dark".source =
      config.lib.file.mkOutOfStoreSymlink "${settings.repoPath}/config/cava/themes/solarized_dark";
    "cava/themes/tricolor".source =
      config.lib.file.mkOutOfStoreSymlink "${settings.repoPath}/config/cava/themes/tricolor";
    eww.source = config.lib.file.mkOutOfStoreSymlink "${settings.repoPath}/config/eww";
    fastfetch.source = config.lib.file.mkOutOfStoreSymlink "${settings.repoPath}/config/fastfetch";
    hypr.source = config.lib.file.mkOutOfStoreSymlink "${settings.repoPath}/config/hypr";
    kitty.source = config.lib.file.mkOutOfStoreSymlink "${settings.repoPath}/config/kitty";
    nvim.source = config.lib.file.mkOutOfStoreSymlink "${settings.repoPath}/config/nvim";
    quickshell.source = config.lib.file.mkOutOfStoreSymlink "${settings.repoPath}/config/quickshell";
    themes.source = config.lib.file.mkOutOfStoreSymlink "${settings.repoPath}/config/themes";
    tmux.source = config.lib.file.mkOutOfStoreSymlink "${settings.repoPath}/config/tmux";
    wayclick.source = config.lib.file.mkOutOfStoreSymlink "${settings.repoPath}/config/wayclick";
    yazi.source = config.lib.file.mkOutOfStoreSymlink "${settings.repoPath}/config/yazi";
    zed.source = config.lib.file.mkOutOfStoreSymlink "${settings.repoPath}/config/zed";
  };

  # Remove the old ~/.config/cava directory link before creating per-file links;
  # otherwise Home Manager would create self-referencing links inside the repo.
  home.activation.cavaFolderLink = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
    if [ -L "$HOME/.config/cava" ]; then
      run rm "$HOME/.config/cava"
    fi
  '';

  # Initialize ignored, machine-local theme state on first install.
  home.activation.nyxcraftState =
    let
      repo = settings.repoPath;
    in
    lib.hm.dag.entryAfter [ "linkGeneration" ] ''
      if [ -f ${repo}/config/quickshell/scripts/apply-theme.sh ]; then
        run ${pkgs.bash}/bin/bash ${repo}/config/quickshell/scripts/apply-theme.sh --init ||
          echo "nyxcraft: couldn't set up the default theme" >&2
        [ -e ${repo}/config/hypr/hyprland-gui.lua ] || run touch ${repo}/config/hypr/hyprland-gui.lua
      else
        echo "nyxcraft: no repo at ${repo}; set repoPath in this host's settings.nix" >&2
      fi
    '';
}
