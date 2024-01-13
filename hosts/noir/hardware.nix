{ config, lib, pkgs, inputs, ... }:

{
  fileSystems = {
    "/" = {
      device = "/dev/disk/by-uuid/06366069-9e8d-4f11-b01c-01444c9034c4";
      fsType = "ext4";
    };
  };

  boot.initrd.luks.devices = {
    "LUKS-NOIR-ROOTFS" = {
      device = "/dev/disk/by-uuid/d38d7e73-fb30-4dbf-be5b-903bfd2c239e";
    };
  };

  nix.settings.max-jobs = lib.mkDefault 4;
}
