{ pkgs, lib, ... }:

{
  # macOS ships no shuf and `godsWords` needs one; the g prefix (gshuf, gls, ...)
  # is what keeps GNU coreutils from shadowing the BSD tools, where the same flags
  # mean other things: GNU `ls -G` is --no-group, not colour, and BSD `date -j`
  # and `stat -f` do not exist in GNU
  home.packages =
    (with pkgs; [
      curl
      htop
      kubectl
      ripgrep
      rsync
      tree
      wget
    ])
    ++ lib.optional pkgs.stdenv.hostPlatform.isDarwin pkgs.coreutils-prefixed;
}
