# ❄️ Serenitea Pot

[![validate](https://github.com/codgician/serenitea-pot/actions/workflows/validate.yml/badge.svg)](https://github.com/codgician/nix-fleet/actions/workflows/validate.yml)
[![evergreen](https://github.com/codgician/serenitea-pot/actions/workflows/evergreen.yml/badge.svg)](https://github.com/codgician/nix-fleet/actions/workflows/evergreen.yml)
![Man hours](https://manhours.aiursoft.cn/r/github.com/codgician/serenitea-pot.svg)

![logo](https://github.com/codgician/serenitea-pot/assets/15964984/17d0e39c-9bee-4dd1-9aed-bb8d21f23daf)

My fleet of Nix-managed devices.

## Quick start

### Develop

Start developing with your own flavor of shell:

```bash
nix develop -c $SHELL
```

Don't have nix flake support? Try this instead:

```bash
nix-shell
```

Format the nix code:

```bash
nix fmt
```

To inspect evaluated values or do experiments, you may run REPL using:

```bash
nix run .#repl
```

### Deployment

This breif guide only covers NixOS hosts (excluding LXC containers).

First boot into NixOS Live CD and clone this repository.

#### Apply disk layout

This is required for hosts having `disks.nix` file declaring disk partition layout. This is made possible with [disko](https://github.com/nix-community/disko).

Navigate to host folder containing `disk.nix` and run following command:

```bash
sudo nix --experimental-features "nix-command flakes" run github:nix-community/disko -- --mode disko ./disks.nix
```

After running disko, the newly created partitions should be already mounted at `/mnt`.

#### Configure impermanence

For hosts with [impermanence](https://github.com/nix-community/impermanence) enabled, run following command:

```bash
sudo mkdir /mnt/nix/persist
```

Run following command to generate new ssh key pair:

```bash
sudo mkdir -p /mnt/nix/persist/etc/ssh/
sudo ssh-keygen -t ed25519 -f /mnt/nix/persist/etc/ssh/ssh_host_ed25519_key -C ""
```

Add generated public key to `/secrets/pubKeys.nix`, then navigate to `/secrets` and run following command to rekey all credentials:

```bash
agenix -r
```

#### Install NixOS

Before installation, please note:

- Lanzeboot requires generating keys with `sudo sbctl create-keys` before-hand. You may also temporarily disable Secure Boot and configure it after first boot.

Run following command under repo root path:

```bash
sudo nixos-install --flake .#hostname
```

You can now reboot from Live CD and boot into your newly installed device.
