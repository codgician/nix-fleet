{ config, lib, pkgs, ... }:
let
  dirs = builtins.readDir ./.;
  secretsDir = ../../secrets;
  secretsFile = secretsDir + "/secrets.nix";

  cfg = config.codgician.users;
  systemCfg = config.codgician.system;
  types = lib.types;

  agenixEnabled = (systemCfg?agenix && systemCfg.agenix.enable);
  concatAttrs = attrList: builtins.foldl' (x: y: x // y) { } attrList;
  getAgeSecretNameFromPath = path: lib.removeSuffix ".age" (builtins.baseNameOf path);

  # Use list of sub-folder names as list of available users
  users = builtins.filter (name: dirs.${name} == "directory") (builtins.attrNames dirs);

  # Define module options for each user
  mkUserOptions = name: {
    "${name}" = {
      enable = lib.mkEnableOption ''Enable user "${name}".'';

      createHome = lib.mkEnableOption ''Whether or not to create home directory for user "${name}".'';

      home = lib.mkOption {
        type = types.path;
        default = if pkgs.stdenvNoCC.isLinux then "/home/${name}" else "/Users/${name}";
        description = lib.mdDoc ''
          Path of home directory for user "${name}".
        '';
      };

      extraAgeFiles = lib.mkOption {
        type = types.listOf types.path;
        default = [ ];
        description = lib.mdDoc ''
          Paths to `.age` secret files owned by user "${name}" excluding `hashedPasswordAgeFile`.
          Only effective when agenix is enabled. 
        '';
      };

    } // lib.optionalAttrs pkgs.stdenvNoCC.isLinux {
      hashedPassword = lib.mkOption {
        type = with types; nullOr (passwdEntry str);
        default = null;
        description = lib.mdDoc ''
          Hashed password for user "${name}". Only effective when agenix is **NOT** enabled.
          To generate a hashed password, run `mkpasswd`.
        '';
      };

      hashedPasswordAgeFile = lib.mkOption {
        type = with types; nullOr path;
        default = null;
        description = lib.mdDoc ''
          Path to hashed password file encrypted managed by agenix.
          Should only be set when agenix is enabled.
        '';
      };

      extraGroups = lib.mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = lib.mdDoc ''
          Auxiliary groups for user "${name}".
        '';
      };
    };
  };

  # Create assertions for each user
  mkUserAssertions = name: lib.mkIf cfg.${name}.enable [
    {
      assertion = !(cfg.${name}?hashedPassword) || agenixEnabled || cfg.${name}.hashedPassword != null;
      message = ''User "${name}" must have `hashedPassword` specified because agenix module is not enabled.'';
    }

    {
      assertion = !(cfg.${name}?hashedPasswordAgeFile) || !agenixEnabled || cfg.${name}.hashedPasswordAgeFile != null;
      message = ''User "${name}" must have `hashedPasswordAgeFile` specified because agenix module is enabled.'';
    }
  ];

  # Make configurations for each user
  mkUserConfig = name: lib.mkIf cfg.${name}.enable (lib.mkMerge [
    # Import user specific options
    (import ./${name} { inherit config lib pkgs; })

    # Impermanence: persist home directory if enabled
    {
      environment = lib.optionalAttrs (systemCfg?impermanence) {
        persistence.${systemCfg.impermanence.path}.directories =
          lib.mkIf (systemCfg.impermanence.enable && cfg.${name}.createHome) [
            {
              directory = cfg.${name}.home;
              user = name;
              group = "users";
              mode = "u=rwx,g=rx,o=";
            }
          ];
      };
    }

    # Agenix: manage secrets if enabled
    {
      age.secrets = lib.optionalAttrs agenixEnabled (
        let
          mkSecretConfig = path: {
            "${getAgeSecretNameFromPath path}" = {
              file = path;
              mode = "600";
              owner = name;
            };
          };
        in
        concatAttrs (builtins.map mkSecretConfig (
          cfg.${name}.extraAgeFiles ++
          (lib.optionals (cfg.${name}?hashedPasswordAgeFile) [ cfg.${name}.hashedPasswordAgeFile ])
        ))
      );
    }

    # Common options
    {
      assertions = mkUserAssertions name;
      users.users.${name} = {
        createHome = cfg.${name}.createHome;
        home = cfg.${name}.home;
      } // lib.optionalAttrs (cfg.${name}?extraGroups) {
        extraGroups = cfg.${name}.extraGroups;
      } // lib.optionalAttrs pkgs.stdenvNoCC.isLinux {
        hashedPassword = lib.mkIf (!agenixEnabled) cfg.${name}.hashedPassword;
        hashedPasswordFile = lib.mkIf (agenixEnabled)
          config.age.secrets."${getAgeSecretNameFromPath cfg.${name}.hashedPasswordAgeFile}".path;
      };
    }
  ]);
in
{
  options.codgician.users = concatAttrs (builtins.map mkUserOptions users);
  config = lib.mkMerge (builtins.map mkUserConfig users);
}
