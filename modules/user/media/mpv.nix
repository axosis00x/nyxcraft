{ config, lib, pkgs, ... }:
let
  cfg = config.userSettings.media;
in
{
  programs.mpv = lib.mkIf cfg.enable {
    enable = true;
    scripts = [
      pkgs.mpvScripts.uosc
      pkgs.mpvScripts.thumbfast
    ];

    bindings = {
      SPACE = "cycle pause; script-binding uosc/flash-pause-indicator";
      MBTN_LEFT = "cycle pause; script-binding uosc/flash-pause-indicator";
      UP = "no-osd add volume 5; script-binding uosc/flash-volume";
      DOWN = "no-osd add volume -5; script-binding uosc/flash-volume";
      Q = "quit ignore";
      q = "quit-watch-later";
      f = "cycle fullscreen";
      s = "screenshot";
      c = "cycle sub-visibility";
      h = "seek -10 exact";
      l = "seek 10 exact";
    };

    config = {
      keep-open = true;
      save-position-on-quit = true;
      autofit-larger = "90%x90%";

      osc = false;
      osd-bar = false;
      border = false;

      vo = "gpu";
      gpu-context = "wayland";

      hwdec = "vaapi";
      vaapi-device = "/dev/dri/renderD128";

      scale = "spline36";
      cscale = "spline36";
      dscale = "mitchell";
      correct-downscaling = true;
      linear-downscaling = true;
      dither-depth = "auto";

      screenshot-format = "png";
      screenshot-directory = "~/Pictures/Screenshots";
    };

    scriptOpts.uosc = {
      # YouTube-inspired bottom timeline and familiar compact control row.
      timeline_style = "bar";
      timeline_size = 32;
      timeline_step = 5;
      timeline_heatmap = "overlay";
      timeline_persistency = "paused";
      progress = "windowed";
      progress_size = 1;
      controls = "menu,gap,play-pause,<video>subtitles,space,<has_many_audio>audio,<has_many_video>video,<stream>stream-quality,gap,items,next,gap,fullscreen";
      controls_size = 30;
      controls_spacing = 6;
      controls_persistency = "paused";
      volume = "left";
      color = "foreground=ff0033,foreground_text=ffffff";
      autohide = true;
    };

    profiles.thumbfast = {
      network = false;
      audio = false;
      sub = false;
      video = false;
      hwdec = false;
      profile = "fast";
    };
  };
}
