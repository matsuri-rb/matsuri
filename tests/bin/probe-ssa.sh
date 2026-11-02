#!/bin/bash
set -euo pipefail

# Probes the creation protocol the seeds+SSA posture rests on, before any
# SSA code lands. Hard expectations (FAIL) pin the invariants the design
# assumes; REPORT legs are open questions whose answers shape the design.
#
# The seed that matters is the IMAGE: the ongoing declaration omits it
# (the container entry rides on its name key alone) and another writer
# delivers it. Replicas is the second seed; a declared env var is the
# ongoing manager's own changeable field.
#
#   F. seed via create under the seed owner (a disposable manager derived
#      from the ongoing one), then the ordinary declared SSA apply, then
#      remove the seed owner's managedFields entry with an atomic
#      test+remove JSON patch.
#      managedFields is never empty when an apply arrives (so the server
#      never invents before-first-apply), the seeds end unowned, and the
#      ongoing applier ends sole owner of the declared fields.
#      F1  EXPECT  create --field-manager=<seed owner> lands both seeds
#      F2  EXPECT  the declared apply is accepted with the image absent
#                  from the container entry (keyed-list partial), seeds
#                  untouched, and the ongoing manager never owns image
#      F3  EXPECT  test+remove of the seed owner's entry applies (<=3
#                  attempts; the test op makes a stale index a loud
#                  retry, not a wrong removal)
#      F4  EXPECT  values intact; seed owner entry gone; image AND replicas
#                  unowned; raw managedFields dumped for verification
#      F5  EXPECT  changing a declared value is clean -- the leg every
#                  refuted path failed -- and both seeds are untouched
#      F6  EXPECT  image delivery via kubectl set image (update-family)
#                  is clean, and the next omitting apply leaves the
#                  delivered image alone
#      F7  EXPECT  after kubectl scale, an omitting apply leaves
#                  replicas alone
#      F8  EXPECT  a different manager changing an owned field conflicts
#      F9  REPORT  diff --server-side surfaces that conflict (exit 2)
#      F10 EXPECT  re-running the seeded create is loud (AlreadyExists)
#      F11 REPORT  last-applied state; EXPECT it never carries a seed
#                  (the CSA prune trap)
#
# Ownership claims are live reads: owners() runs a fresh get
# --show-managed-fields per call and scans every entry's fieldsV1 for
# the field's path; the raw dumps in F4/F6/F7 print the entries
# verbatim (status/metadata pruned) so "unowned" is checkable against
# the record, not the filter.
#
# Refuted alternatives, pruned from the probe after earlier runs:
#   - create then SSA directly: the create manager's Update entry co-owns every
#     seeded field and never relinquishes; the first changed-value apply
#     conflicts permanently.
#   - create under the SAME name the applies use: an Update entry and an
#     Apply entry are distinct managers; the conflict remains.
#   - seed on the first SSA apply: the next apply that omits the seed
#     relinquishes the field and the server resets it.
#   - wipe managedFields BEFORE the first apply (patch or embedded in the
#     create body): an apply against empty managedFields attributes every
#     existing field to the synthetic manager before-first-apply, which
#     never relinquishes; the same dead end under another name.
#
# Start the cluster with bin/minikube-start.sh first. kubectl dials the
# VM: on macOS run from a Local Network-granted context (not tmux).

TESTS_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CONTEXT="${CONTEXT:-matsuri}"
MANAGER="${MANAGER:-matsuri}"
OTHER_MANAGER="${OTHER_MANAGER:-other}"
# Disposable but deliberate: the F3 removal predicate keys on this name,
# and a converge that dies before F3 strands an object whose managedFields
# should read as ours. The seed owner is derived from the ongoing manager
# (<manager>-seed), matching Tasks::Stacks::Seed.
CREATE_MANAGER="${CREATE_MANAGER:-${MANAGER}-seed}"
K8S="${TESTS_DIR}/k8s/ssa"
KUBECTL=(kubectl --context "${CONTEXT}" --namespace matsuri-probes)

fail()   { echo "FAIL: $*" >&2; exit 1; }
report() { echo "REPORT $*"; }

ssa() { "${KUBECTL[@]}" apply --server-side --field-manager="${MANAGER}" -f "$1"; }

replicas() { "${KUBECTL[@]}" get deployment "$1" -o jsonpath='{.spec.replicas}'; }
image()    { "${KUBECTL[@]}" get deployment "$1" -o jsonpath='{.spec.template.spec.containers[0].image}'; }
declared() { "${KUBECTL[@]}" get deployment "$1" -o jsonpath='{.spec.template.spec.containers[0].env[?(@.name=="DECLARED")].value}'; }

# every manager/operation pair on the object
managers() { # managers <deployment>
  "${KUBECTL[@]}" get deployment "$1" --show-managed-fields -o json |
    jq -r '[.metadata.managedFields[]? | "\(.manager)/\(.operation)"] | join(" ")'
}

# manager/operation pairs owning the given field, from a fresh read
owners() { # owners <deployment> replicas|image|env
  local path
  case "$2" in
    replicas) path='["fieldsV1","f:spec","f:replicas"]' ;;
    image)    path='["fieldsV1","f:spec","f:template","f:spec","f:containers","k:{\"name\":\"pause\"}","f:image"]' ;;
    env)      path='["fieldsV1","f:spec","f:template","f:spec","f:containers","k:{\"name\":\"pause\"}","f:env","k:{\"name\":\"DECLARED\"}"]' ;;
  esac
  "${KUBECTL[@]}" get deployment "$1" --show-managed-fields -o json |
    jq -r --argjson p "${path}" '.metadata.managedFields[] | select(getpath($p) != null) | "\(.manager)/\(.operation)"' |
    paste -sd ' ' -
}

# the managedFields entries verbatim, status/metadata pruned for reading
managed_fields_raw() { # managed_fields_raw <deployment>
  "${KUBECTL[@]}" get deployment "$1" --show-managed-fields -o json |
    jq -c '.metadata.managedFields[]? | {manager, operation, subresource, fieldsV1: (.fieldsV1 | del(."f:status", ."f:metadata"))}' |
    sed 's/^/    /'
}

report "versions: $(kubectl --context "${CONTEXT}" version -o json 2>/dev/null | jq -r '"client \(.clientVersion.gitVersion) / server \(.serverVersion.gitVersion)"')"

kubectl --context "${CONTEXT}" apply -f "${K8S}/namespace.yaml"
"${KUBECTL[@]}" delete deployment seed-via-create --ignore-not-found --wait

echo '--- Path F: seed via create, declared apply, then remove the seed owner entry ---'

"${KUBECTL[@]}" create --field-manager="${CREATE_MANAGER}" -f "${K8S}/seed-via-create.yaml"
[ "$(replicas seed-via-create)" = "3" ] || fail "F1 create did not land the seeded replicas (replicas=$(replicas seed-via-create))"
[ "$(image seed-via-create)" = "registry.k8s.io/pause:3.9" ] || fail "F1 create did not land the seeded image (image=$(image seed-via-create))"
report "F1 managers at birth: [$(managers seed-via-create)]"

ssa "${K8S}/declared.yaml" || fail "F2 the declared apply was rejected -- a container entry cannot omit its image"
[ "$(replicas seed-via-create)" = "3" ] || fail "F2 declared apply disturbed the seeded replicas (replicas=$(replicas seed-via-create))"
[ "$(image seed-via-create)" = "registry.k8s.io/pause:3.9" ] || fail "F2 declared apply disturbed the seeded image (image=$(image seed-via-create))"
case " $(owners seed-via-create image) " in
  *" ${MANAGER}/"*) fail "F2 the ongoing manager owns the image it never sent" ;;
esac
report "F2 after declared apply: image owned by [$(owners seed-via-create image)], env owned by [$(owners seed-via-create env)]"

patched=""
for attempt in 1 2 3; do
  idx="$("${KUBECTL[@]}" get deployment seed-via-create --show-managed-fields -o json |
    jq --arg m "${CREATE_MANAGER}" '[.metadata.managedFields[].manager] | index($m)')"
  [ "${idx}" != "null" ] || fail "F3 no ${CREATE_MANAGER} entry to remove"
  if "${KUBECTL[@]}" patch deployment seed-via-create --type=json -p "[
      {\"op\":\"test\",\"path\":\"/metadata/managedFields/${idx}/manager\",\"value\":\"${CREATE_MANAGER}\"},
      {\"op\":\"remove\",\"path\":\"/metadata/managedFields/${idx}\"}
    ]"; then
    patched="yes"
    [ "${attempt}" = "1" ] || report "F3 removal needed ${attempt} attempts (object changed under the read)"
    break
  fi
done
[ -n "${patched}" ] || fail "F3 test+remove lost the race 3 times"
report "F3 managers after removal: [$(managers seed-via-create)]"

[ "$(replicas seed-via-create)" = "3" ] || fail "F4 the removal disturbed the seeded replicas (replicas=$(replicas seed-via-create))"
[ "$(image seed-via-create)" = "registry.k8s.io/pause:3.9" ] || fail "F4 the removal disturbed the seeded image (image=$(image seed-via-create))"
case " $(managers seed-via-create) " in
  *" ${CREATE_MANAGER}/"*) fail "F4 the ${CREATE_MANAGER} entry survived the removal" ;;
esac
[ -z "$(owners seed-via-create image)" ] || fail "F4 image still owned by [$(owners seed-via-create image)] -- expected unowned"
[ -z "$(owners seed-via-create replicas)" ] || fail "F4 replicas still owned by [$(owners seed-via-create replicas)] -- expected unowned"
report "F4 seeds unowned, env owned by [$(owners seed-via-create env)]; managedFields verbatim:"
managed_fields_raw seed-via-create

ssa "${K8S}/declared-bumped.yaml" || fail "F5 changing a declared value conflicted -- the dead-end survives the seed-owner removal"
[ "$(declared seed-via-create)" = "two" ] || fail "F5 the declared change did not land (DECLARED=$(declared seed-via-create))"
[ "$(replicas seed-via-create)" = "3" ] || fail "F5 the declared change disturbed the unowned replicas (replicas=$(replicas seed-via-create)) -- a ghost manager came back"
[ "$(image seed-via-create)" = "registry.k8s.io/pause:3.9" ] || fail "F5 the declared change disturbed the unowned image (image=$(image seed-via-create)) -- a ghost manager came back"
echo "F5 changed-declared apply clean -- the ongoing-delivery dead-end is gone"
report "F5 env owned by [$(owners seed-via-create env)]"

"${KUBECTL[@]}" set image deployment/seed-via-create pause=registry.k8s.io/pause:3.10
[ "$(image seed-via-create)" = "registry.k8s.io/pause:3.10" ] || fail "F6 image delivery did not land (image=$(image seed-via-create))"
ssa "${K8S}/declared-bumped.yaml"
[ "$(image seed-via-create)" = "registry.k8s.io/pause:3.10" ] || fail "F6 omitting apply disturbed the delivered image (image=$(image seed-via-create))"
report "F6 delivered image stands; image owned by [$(owners seed-via-create image)]; managedFields verbatim:"
managed_fields_raw seed-via-create

"${KUBECTL[@]}" scale deployment seed-via-create --replicas=5
ssa "${K8S}/declared-bumped.yaml"
[ "$(replicas seed-via-create)" = "5" ] || fail "F7 omitting apply disturbed scaled replicas (replicas=$(replicas seed-via-create))"
report "F7 after scale: replicas owned by [$(owners seed-via-create replicas)]; managedFields verbatim:"
managed_fields_raw seed-via-create

if out="$("${KUBECTL[@]}" apply --server-side --field-manager="${OTHER_MANAGER}" -f "${K8S}/declared.yaml" 2>&1)"; then
  fail "F8 a different manager changed an owned field without conflict"
fi
echo "F8 cross-manager change conflicts (frontier intact)"

set +e
out="$("${KUBECTL[@]}" diff --server-side --field-manager="${OTHER_MANAGER}" -f "${K8S}/declared.yaml" 2>&1)"
rc=$?
set -e
report "F9 diff --server-side of the conflicting payload: exit=${rc} (2 = conflict surfaced)"
echo "${out}" | head -5 | sed 's/^/    /'

if out="$("${KUBECTL[@]}" create --field-manager="${CREATE_MANAGER}" -f "${K8S}/seed-via-create.yaml" 2>&1)"; then
  fail "F10 re-running the seeded create silently succeeded"
fi
echo "F10 re-running the seeded create is loud:"
echo "${out}" | sed 's/^/    /'

if la="$("${KUBECTL[@]}" apply view-last-applied deployment seed-via-create 2>/dev/null)"; then
  report "F11 last-applied content:"
  echo "${la}" | sed 's/^/    /'
  if echo "${la}" | grep -Eq 'replicas|image'; then
    fail "F11 last-applied carries a seed -- the CSA prune trap is loaded"
  fi
else
  report "F11 no last-applied annotation"
fi

echo "PASS: the creation protocol held; read the REPORT lines for ownership detail"
