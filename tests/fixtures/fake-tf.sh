#!/usr/bin/env bash
# Fake terraform/tofu CLI used by the tests (no network, deterministic output).
log="${FAKE_TF_LOG:-/tmp/fake-tf.log}"
echo "$(basename "$0") $*" >> "$log"
cmd=""
rest=()
for a in "$@"; do
  case "$a" in
    -chdir=*) cd "${a#-chdir=}" || { echo "Error: chdir failed"; exit 1; } ;;
    *)
      if [ -z "$cmd" ] && [[ "$a" != -* ]]; then cmd="$a"; else rest+=("$a"); fi
      ;;
  esac
done
detailed=0
out=""
for a in "${rest[@]}"; do
  case "$a" in
    -detailed-exitcode) detailed=1 ;;
    -out=*) out="${a#-out=}" ;;
  esac
done
case "$cmd" in
  fmt) exit 0 ;;
  init) echo "Terraform has been successfully initialized!"; exit 0 ;;
  validate) echo "Success! The configuration is valid."; exit 0 ;;
  plan)
    if [ -n "$out" ]; then echo "fake-plan-content" > "$out"; fi
    echo "  # null_resource.example will be created"
    echo "Plan: 1 to add, 0 to change, 0 to destroy."
    if [ "$detailed" = 1 ]; then exit 2; fi
    exit 0
    ;;
  show)
    if [ "${rest[0]}" = "-json" ]; then echo '{"resource_changes":[]}'; exit 0; fi
    echo "Terraform will perform the following actions:"
    echo ""
    echo "  # null_resource.example will be created"
    echo '  + resource "null_resource" "example" {}'
    echo ""
    echo "Plan: 1 to add, 0 to change, 0 to destroy."
    exit 0
    ;;
  apply) echo "Apply complete! Resources: 1 added, 0 changed, 0 destroyed."; exit 0 ;;
  version) echo "Terraform v1.9.0"; exit 0 ;;
  *) echo "Error: unknown command '$cmd'"; exit 1 ;;
esac
