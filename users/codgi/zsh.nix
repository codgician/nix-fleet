{ config, osConfig, lib, pkgs, ... }: {

  programs.zsh = {
    enable = true;
    oh-my-zsh = {
      enable = true;
      plugins = [
        "git"
        "ssh-agent"
      ] ++ lib.optionals pkgs.stdenvNoCC.isDarwin [
        "macos"
      ];
      theme = "half-life";
    };

    initExtra = ''
      zstyle :omz:plugins:ssh-agent quiet yes
    '' + lib.optionalString pkgs.stdenvNoCC.isDarwin (
      ''
        zstyle :omz:plugins:ssh-agent ssh-add-args --apple-load-keychain
      '' + lib.optionalString osConfig.homebrew.enable ''
        eval "$(/opt/homebrew/bin/brew shellenv)"
      ''
    );
  };
}
