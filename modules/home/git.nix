{ vars, ... }:

{
  programs.git = {
    enable = true;
    settings.user = {
      name = vars.gitUser;
      email = vars.gitEmail;
    };
  };
}
