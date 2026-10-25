# Host-specific Home Manager settings: SSH keys and a second GitHub account.
{ ... }:
{
  programs.ssh.settings = {
    "github.com" = {
      Hostname = "github.com";
      User = "git";
      IdentityFile = "~/.ssh/github";
      IdentitiesOnly = true;
    };
    # Second account (dikchya355): use git@github-dikchya:owner/repo.git.
    "github-dikchya" = {
      Hostname = "github.com";
      User = "git";
      IdentityFile = "~/.ssh/github-dikchya";
      IdentitiesOnly = true;
    };
  };

  programs.git = {
    settings.alias = {
      # Set this repo's commit identity and SSH remote for the other account.
      as-dikchya = "!git config user.name dikchya355 && git config user.email 189239361+dikchya355@users.noreply.github.com && git remote set-url origin \"$(git remote get-url origin | sed -E 's#git@github(-dikchya)?(\\.com)?:#git@github-dikchya:#')\" && git whoami";
      as-axosis = "!git config --unset user.name; git config --unset user.email; git remote set-url origin \"$(git remote get-url origin | sed -E 's#git@github(-dikchya)?(\\.com)?:#git@github.com:#')\" && git whoami";
    };

    # Use dikchya355's identity and SSH key for repos under this directory.
    includes = [
      {
        condition = "gitdir:~/Projects/thirdparty/dikchya/";
        contents = {
          user = {
            name = "dikchya355";
            email = "189239361+dikchya355@users.noreply.github.com";
          };
          url."git@github-dikchya:".insteadOf = [
            "git@github.com:"
            "https://github.com/"
          ];
        };
      }
    ];
  };
}
