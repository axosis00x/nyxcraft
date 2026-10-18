# Checks and formatting run on the build machine's platform.
{ self, ... }:
{
  systems = [ "x86_64-linux" ];

  perSystem =
    { pkgs, ... }:
    let
      repoCheck =
        name: tools: script:
        pkgs.runCommand "nyxcraft-${name}" { nativeBuildInputs = tools; } ''
          cd ${self}
          ${script}
          touch $out
        '';
    in
    {
      formatter = pkgs.nixfmt-tree.override {
        settings.formatter.nixfmt.excludes = [ "hosts/*/hardware-configuration.nix" ];
      };

      checks = {
        format = repoCheck "format" [ pkgs.nixfmt ] ''
          find . -name '*.nix' ! -path './hosts/*/hardware-configuration.nix' -print0 |
            xargs -0 nixfmt --check
        '';
        shellcheck = repoCheck "shellcheck" [ pkgs.shellcheck ] ''
          find . -name '*.sh' -print0 | xargs -0 shellcheck -S warning
        '';
        lua = repoCheck "lua" [ pkgs.lua5_4 ] ''
          find . -name '*.lua' -print0 | xargs -0 -n1 luac -p
        '';
      };
    };
}
