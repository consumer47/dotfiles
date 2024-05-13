{ config, pkgs, ... }:

{
  home.username = "dennis";
  home.homeDirectory = "/home/dennis";
  home.stateVersion = "23.05";
  home.packages = with pkgs; [
    neofetch
  ];
  programs.home-manager.enable = true;
}
