---
name: ci-cd-quirks
description: Use when CI checks fail unexpectedly, when modifying Tekton pipelines or GitHub Actions, or when debugging build failures. Covers pipeline structure, GitHub Actions scope, and image digest gotchas.
---

# CI/CD Quirks

## Pipeline Structure

| Pipeline | Trigger | Purpose |
|----------|---------|---------|
| `.tekton/oauth2-proxy-pull-request.yaml` | PR opened/updated | Build + security scans on PR |
| `.tekton/oauth2-proxy-push.yaml` | Merge to main | Production build + push to registry |
| `.tekton/oauth2-proxy-pipeline.yaml` | Shared pipeline definition | Referenced by PR and push configs |

**Builds run in Konflux, not GitHub Actions.** GitHub Actions handle:
- `lint.yaml` — yamllint + hadolint on PRs and pushes to main
- `auto-merge.yaml` — auto-merges bot PRs (Renovate/MintMaker)
- `dep-triage.yaml` — labels and triages dependency update PRs

## Multi-arch Build Digest Gotcha

The pipeline currently builds `linux/x86_64` and `linux/arm64`. When updating base image digests in the Containerfile, always use the **manifest list** digest. Platform-specific digests (e.g., from `podman inspect`) break arm64 builds (and any other non-amd64 platforms if added later).

```bash
# Get the correct manifest list digest
skopeo inspect --raw docker://registry.access.redhat.com/ubi10/go-toolset:<tag> \
  | sha256sum | cut -d' ' -f1

# Verify it's a manifest list (should show a "manifests" array)
skopeo inspect --raw docker://registry.access.redhat.com/ubi10/go-toolset:<tag> \
  | python3 -m json.tool | head -5
```

## Common CI Failures

| Symptom | Cause | Fix |
|---------|-------|-----|
| arm64 build: "image not known" | Platform-specific digest in Containerfile | Replace with manifest list digest |
| Go version mismatch | go.mod requires newer Go than UBI provides | Update go-toolset image or downgrade submodule |
| `jwt_signing_key.pem` not found | Build step skipped or failed | Ensure `touch jwt_signing_key.pem` runs in builder stage |
