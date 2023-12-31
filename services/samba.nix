{ config, pkgs, ... }:
let
  sambaUsers = [ "codgi" "bmc" ];
in
{
  # Samba configurations
  services.samba = {
    enable = true;
    package = pkgs.sambaFull;

    securityType = "user";
    enableNmbd = true;
    openFirewall = true;

    invalidUsers = [ "root" ];

    extraConfig = ''
      server string = ${config.networking.hostName}
      netbios name = ${config.networking.hostName}

      #server signing = mandatory
      server min protocol = NT1
      #server smb encrypt = required
    '';

    # Shares
    shares = {
      "media" = {
        path = "/mnt/nas/media";
        browsable = "yes";
        writeable = "yes";
        "read only" = "no";
        "guest ok" = "yes";
        "create mask" = "0644";
        "directory mask" = "0755";
        "force user" = "codgi";
      };

      "iso" = {
        path = "/mnt/nas/iso";
        public = "yes";
        browsable = "yes";
        writeable = "yes";
        "guest ok" = "yes";
        "create mask" = "0644";
        "directory mask" = "0755";
        "force user" = "codgi";
      };

      "timac" = {
        path = "/mnt/timac/";
        "valid users" = "codgi";
        public = "no";
        writeable = "yes";
        "force user" = "codgi";
        "fruit:aapl" = "yes";
        "fruit:time machine" = "yes";
        "vfs objects" = "catia fruit streams_xattr";
      };
    };
  };

  # Make shares visible to Windows clients
  services.samba-wsdd.enable = true;

  # Make sure user passwords are updated
  system.activationScripts.sambaPasswordRefresh = {
    supportsDryActivation = false;
    text =
      let
        sambaPkg = config.services.samba.package;
        sambaUsersString = builtins.concatStringsSep "," sambaUsers;
        getCommand = user:
          let passwordFile = config.age.secrets."${user}Password".path;
          in ''(cat ${passwordFile}; cat ${passwordFile};) | ${sambaPkg}/bin/smbpasswd -s -a "${user}"'';
        commands = [
          ''echo -e "refreshing samba password for: ${sambaUsersString}"''
        ] ++ builtins.map getCommand sambaUsers;
        script = builtins.concatStringsSep "; " commands;
      in
      "${pkgs.sudo}/bin/sudo ${pkgs.bash}/bin/bash -c '${script}'";
  };
}
