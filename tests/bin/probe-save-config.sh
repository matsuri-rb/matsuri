#!/bin/bash
set -euo pipefail

# Probes the mechanics the seed model rests on: a create WITHOUT
# --save-config (the kubectl default) keeps seeded fields out of
# last-applied, so ongoing applies of a manifest that omits them never
# prune them, and another controller (an HPA) takes ownership
# uncontested.
#
# Sequence:
#   1. create from the seeded manifest (replicas: 3), no --save-config
#   2. apply the declared manifest (no replicas) -> replicas must stay 3
#   3. scale to 5 (stands in for the HPA taking ownership)
#   4. apply the declared manifest again -> replicas must stay 5
#
# Start the cluster with bin/minikube-start.sh first. kubectl dials the
# VM: on macOS run from a Local Network-granted context (not tmux).

TESTS_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CONTEXT="${CONTEXT:-matsuri}"
K8S="${TESTS_DIR}/k8s/save-config"
KUBECTL=(kubectl --context "${CONTEXT}" --namespace matsuri-probes)

fail() { echo "FAIL: $*" >&2; exit 1; }

replicas() {
  "${KUBECTL[@]}" get deployment save-config-probe -o jsonpath='{.spec.replicas}'
}

kubectl --context "${CONTEXT}" apply -f "${K8S}/namespace.yaml"
"${KUBECTL[@]}" delete deployment save-config-probe --ignore-not-found --wait

"${KUBECTL[@]}" create -f "${K8S}/deployment-seeded.yaml"
[ "$(replicas)" = "3" ] || fail "create did not land the seed (replicas=$(replicas))"

"${KUBECTL[@]}" apply -f "${K8S}/deployment-declared.yaml"
[ "$(replicas)" = "3" ] || fail "first apply pruned the seeded replicas (replicas=$(replicas))"

"${KUBECTL[@]}" scale deployment save-config-probe --replicas=5
"${KUBECTL[@]}" apply -f "${K8S}/deployment-declared.yaml"
[ "$(replicas)" = "5" ] || fail "apply clobbered controller-owned replicas (replicas=$(replicas))"

echo "last-applied for the record (replicas must be absent):"
"${KUBECTL[@]}" apply view-last-applied deployment save-config-probe

echo "PASS: seeded create + ongoing applies leave replicas controller-owned"
