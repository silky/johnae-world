{...}: {
  publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN3wV0xe1C2JtwQHwHNL3yYnGsXPfnQAvElF37ux7qkc";

  imports = [
    ../../profiles/hcloud.nix
    ../../profiles/hcloud-k3s-agent.nix
    ../../profiles/hcloud-remote-unlock.nix
    ../../profiles/disk/disko-basic.nix
    ../../profiles/tailscale.nix
    ../../profiles/zram.nix
  ];

  services.k3s.settings.server = "https://\"$(awk -F- '{print \"master-\"$2\"-0\"}' < /etc/generated-hostname)\":6443";
  services.k3s.settings.node-name = "\"$(cat /etc/generated-hostname)\"";

  age.secrets = {
    ts-google-9k-hcloud.file = ../../secrets/ts-google-9k-hcloud.age;
    k3s-token.file = ../../secrets/k3s/token.age;
  };

  services.tailscale.auth = {
    enable = true;
    args.advertise-tags = ["tag:server" "tag:hcloud"];
    args.ssh = true;
    args.accept-routes = false;
    args.accept-dns = true;
    args.advertise-exit-node = true;
    args.auth-key = "file:/var/run/agenix/ts-google-9k-hcloud";
    args.hostname = "\"$(cat /etc/generated-hostname)\"";
  };

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIzm5RyD+1nfy1LquvkEog4SZtPgdhzjr49jSC8PAinp"
  ];
}