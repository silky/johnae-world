{lib, config, hostName,...}:
let
  cfg = config.services.k3s;
in
{
  services.k3s.enable = true;
  services.k3s.extraFlagsList = [
    "--node-label hostname=${hostName}"
  ];
  networking.firewall.allowedTCPPorts = lib.mkIf (cfg.role == "server") [ 6443 ];
  environment.state."/keep" = {
    directories = [
      "/var/lib/dockershim"
      "/var/lib/rancher"
      "/var/lib/kubelet"
      "/var/lib/cni"
      "/var/lib/containerd"
    ];
  };
}
