#!/bin/bash
set -euo pipefail

# Starts the matsuri test cluster under its own profile. --keep-context
# leaves the user's kubectl context alone; scripts address the cluster
# with --context matsuri. Pass minikube flags through, e.g.
# bin/minikube-start.sh --kubernetes-version=v1.34.0.
# kubectl and minikube dial the VM over the local network: on macOS, run
# from a Local Network-granted context (not tmux).
PROFILE="${PROFILE:-matsuri}"

# vfkit is the darwin driver; the flake only ships it there.
case "$(uname -s)" in
  Darwin) DRIVER="${DRIVER:-vfkit}" ;;
  *) DRIVER="${DRIVER:-podman}" ;;
esac

minikube start \
  -p "${PROFILE}" \
  --driver="${DRIVER}" \
  --keep-context \
  "$@"

# The example repo's namespaces precede anything matsuri converges;
# they are raw manifests, applied outside matsuri.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
kubectl --context "${PROFILE}" apply -f "${SCRIPT_DIR}/../example/platform/namespaces"
