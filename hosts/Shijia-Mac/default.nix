{ config, pkgs, ... }: {

  # Nix settings
  nix = {
    settings = {
      auto-optimise-store = true;
      sandbox = true;
    };

    # Garbage collection
    gc = {
      automatic = true;
      interval.Hour = 24 * 7;
    };
  };

  # Users
  users.users.codgi = {
    name = "codgi";
    description = "Shijia Zhang";
    home = "/Users/codgi";
    openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM/Mohin9ceHn6zpaRYWi3LeATeXI7ydiMrP3RsglZ2r codgi-ssh" ];
  };

  # System packages
  environment.systemPackages = with pkgs; [
    direnv neofetch jdk
  ];

  # Fonts
  fonts = {
    fontDir.enable = true;
    fonts = with pkgs; [ cascadia-code ];
  };

  # zsh
  programs.zsh.enable = true;

  # Enable Touch ID for sudo
  security.pam.enableSudoTouchIdAuth = true;

  # Homebrew: not added to PATH by design, 
  # as everything is designed to be managed by nix
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
      upgrade = true;
      cleanup = "zap";
    };

    # GUI applications from Mac AppStore
    masApps = {
      "Pages" = 409201541;
      "Numbers" = 409203825;
      "Keynote" = 409183694;
      "iMovie" = 408981434;
      "Garageband" = 682658836;

      "Swift Playgrounds" = 1496833156;
      "Testflight" = 899247664;
      "Developer" = 640199958;
      "Apple Configurator" = 1037126344;

      "Microsoft Word" = 462054704;
      "Microsoft Excel" = 462058435;
      "Microsoft PowerPoint" = 462062816;
      "Microsoft Outlook" = 985367838;
      "Microsoft OneNote" = 784801555;
      "Microsoft To Do" = 1274495053;
      "Microsoft Remote Desktop" = 1295203466;

      "Telegram" = 747648890;
      "WeChat" = 836500024;
      "QQ" = 451108668;
      "VooV" = 1497685373;

      "WireGuard" = 1451685025;
      "Infuse" = 1136220934;
      "LocalSend" = 1661733229;

      "IT之家" = 570610859;
    };

    # Homebrew casks
    casks = [ 
      "qv2ray" "visual-studio-code" "microsoft-edge"
      "iina" "minecraft" "bilibili" "logi-options-plus"
    ];
  };

  # Home manager
  home-manager.users.codgi = { config, pkgs, ... }: {
    home.stateVersion = "23.05";
    home.packages = with pkgs; [ xray v2ray-geoip v2ray-domain-list-community ];

    programs.git = {
      enable = true;
      lfs.enable = true;
      package = pkgs.gitFull;

      userName = "codgician";
      userEmail = "15964984+codgician@users.noreply.github.com";
      extraConfig.credential.helper = "osxkeychain";
    };
    
    programs.zsh = {
      enable = true;
      enableCompletion = true;
      oh-my-zsh = {
        enable = true;
        plugins = [ "git" ];
        theme = "half-life";
      };
    };
  };
}
