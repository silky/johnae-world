{lib, config, ...}:
let
  inherit (lib) mkOption mkIf mkMerge mkForce types optional;
  inherit (builtins) concatStringsSep;
  cfg = config.services.k3s;
  k3sManifestsDir = "/var/lib/rancher/k3s/server/manifests";
in
{
  options.services.k3s.nodeID = mkOption {
    type = types.nullOr types.str;
    default = null;
  };
  options.services.k3s.autoDeployList = mkOption {
    type = types.listOf types.path;
    default = [];
  };
  options.services.k3s.skipDeployList = mkOption {
    type = types.listOf types.str;
    default = [];
  };
  options.services.k3s.disableFlannel = mkOption {
    type = types.bool;
    default = false;
  };
  options.services.k3s.extraFlagsList = mkOption {
    type = types.listOf types.str;
    default = [];
  };
  config = mkIf (cfg.nodeID != null) {
    systemd.enableUnifiedCgroupHierarchy = mkForce true;
    services.k3s.extraFlagsList = [ "--with-node-id ${cfg.nodeID}" ] ++ (optional (cfg.disableFlannel && cfg.role == "server") "--flannel-backend=none");
    services.k3s.extraFlags = concatStringsSep " " cfg.extraFlagsList;
    systemd.services.k3s.preStart = mkIf (cfg.role == "server") ''
    mkdir -p ${k3sManifestsDir}
    ${concatStringsSep "\n" (map (manifestName:
      "touch ${k3sManifestsDir}/${manifestName}.yaml.skip"
      ) cfg.skipDeployList)
    }
    ${concatStringsSep "\n" (map (manifestPath:
      "cp ${manifestPath} ${k3sManifestsDir}/"
      ) cfg.autoDeployList)
    }
    '';
  };
}
