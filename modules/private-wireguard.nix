{pkgs, config, lib, ...}:

## really just a wrapper so that it's easier to specify through toml (eg. the preSetup hook with a pkg ref)
let
  inherit (lib) mkEnableOption mkOption mkIf types;
  cfg = config.networking.private-wireguard;
  peers = types.submodule {
    options = {
      allowedIPs = mkOption {
        type = types.listOf types.str;
      };
      endpoint = mkOption {
        type = types.str;
      };
      publicKey = mkOption {
        type = types.str;
      };
    };
  };
in
{
  options.networking.private-wireguard = {
    enable = mkEnableOption "Enable private wireguard vpn connection";
    privateKeyFile = mkOption {
      type = types.str;
    };
    interfaceNamespace = mkOption {
      type = types.str;
      default = "private";
    };
    peers = mkOption {
      type = types.listOf peers;
    };
    ips = mkOption {
      type = types.listOf types.str;
    };
  };

  config = mkIf (cfg.enable) {
    networking.wireguard.interfaces.private = {
      inherit (cfg) privateKeyFile interfaceNamespace peers ips;
      preSetup = ''
        ${pkgs.iproute2}/bin/ip netns add ${cfg.interfaceNamespace}
      '';
    };
  };
}