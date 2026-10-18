# Host settings; install.sh writes this file. See modules/settings.nix for
# available options and defaults.
{
  # Login name and home directory (/home/<username>).
  username = "axosis00x";
  fullName = "axosis00x";

  # Repo location; config/ is linked into ~/.config from here.
  repoPath = "/home/axosis00x/nyxcraft";

  # Git commit identity; empty values leave it unset.
  git = {
    name = "axosis00x";
    email = "130370071+axosis00x@users.noreply.github.com";
  };

  # Hostname comes from this folder name and selects the flake output.
  timezone = "Asia/Kathmandu";

  # Original install release; keep this value unchanged.
  stateVersion = "26.05";

  # Choose systemd-boot for UEFI or GRUB for legacy BIOS.
  boot = {
    loader = "systemd-boot";
    efiMount = "/boot";
    grubDevice = "";
  };

  # Machine-specific hardware; disable on other hosts.
  # Intel + NVIDIA Optimus laptop graphics.
  nvidiaOptimus = true;
  # Extra ext4 drive mounted at ~/DataSSD.
  dataDrive = true;
  # Enable guest integration when running in a VM.
  vm = false;

  # Optional software groups; the desktop is always installed.
  features = {
    virtualization = true; # virt-manager/libvirt VMs
    games = true; # Steam
    coding = true; # editors (Neovim, Zed), language toolchains, Claude Code
    apps = true; # browsers, Discord, LibreOffice, OBS, LocalSend, Obsidian…
    extras = true; # terminal toys and monitors (btop, cava, fastfetch, cmatrix…)
  };
}
