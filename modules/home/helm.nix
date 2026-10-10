{ pkgs, lib, ... }:

let
  helmBin = lib.getExe pkgs.kubernetes-helm;

  helmRepos = [
    {
      name = "metrics-server";
      url = "https://kubernetes-sigs.github.io/metrics-server/";
    }
    {
      name = "csi-driver-nfs";
      url = "https://kubernetes-csi.github.io/csi-driver-nfs";
    }
    {
      name = "projectcalico";
      url = "https://docs.tigera.io/calico/charts";
    }
    {
      name = "cilium";
      url = "https://helm.cilium.io/";
    }
  ];

  # Best-effort: an offline switch must not fail on repo sync.
  addRepoScript =
    lib.concatStringsSep "\n" (map (repo: ''
      if ! ${helmBin} repo list -o json 2>/dev/null | grep -q '"name": "${repo.name}"'; then
        ${helmBin} repo add ${repo.name} ${repo.url} \
          || echo "entry-plug: helm repo add ${repo.name} failed; run 'helm repo add ${repo.name} ${repo.url}' later" >&2
      fi
    '') helmRepos);
in

{
  programs.bash.bashrcExtra = lib.mkIf pkgs.stdenv.hostPlatform.isLinux ''
    if command -v helm >/dev/null; then
      source <(helm completion bash)
    fi
  '';

  programs.zsh.initContent = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin ''
    if command -v helm >/dev/null; then
      source <(helm completion zsh)
    fi
  '';

  home.activation.ensureHelmRepos = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    ${addRepoScript}
  '';
}
