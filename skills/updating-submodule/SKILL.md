---
name: updating-submodule
description: Use when updating the oauth2-proxy git submodule to a new upstream tag. Covers tag checkout workflow, version injection via ldflags, and commit conventions.
---

# Updating the oauth2-proxy Submodule

## Overview

The `oauth2-proxy/` submodule tracks upstream **tags** (not branches). `git submodule update --remote` will not work.

## When to Use

- Manually updating to a new upstream release
- Investigating whether a new version is buildable
- Reviewing a dependency update PR

## Update Procedure

Renovate/MintMaker handles this automatically — it updates both `.gitmodules` and the submodule pointer when a new upstream tag appears. For **manual** updates:

```bash
cd oauth2-proxy
git fetch --tags
git checkout <new-tag>
cd ..
# Update .gitmodules to reflect the new tracking tag
git config -f .gitmodules submodule.oauth2-proxy.branch <new-tag>
git add oauth2-proxy .gitmodules
git commit -m "chore: update oauth2-proxy to <new-tag>"
```

The `branch` field in `.gitmodules` is used by Renovate to know which tag the submodule tracks. If you update the submodule pointer without updating `.gitmodules`, Renovate may propose reverting your change.

## Version Injection

The Containerfile injects the version at build time via Go ldflags:

```dockerfile
-ldflags="-X github.com/oauth2-proxy/oauth2-proxy/v7/pkg/version.VERSION=${OAUTH2_PROXY_VERSION}"
```

The `OAUTH2_PROXY_VERSION` build arg should match the submodule tag.

## Go Version Compatibility

Check the upstream `go.mod` against the UBI go-toolset version:

```bash
grep '^go ' oauth2-proxy/go.mod
skopeo inspect docker://registry.access.redhat.com/ubi10/go-toolset:latest | jq -r '.Labels["version"]'
```

Unlike ESO, oauth2-proxy does not set `GOTOOLCHAIN=local` — a Go version mismatch will fail the build.

## Common Mistakes

| Mistake | Why It Breaks | Fix |
|---------|--------------|-----|
| `git submodule update --remote` | Submodule tracks tags, not branches | Use `git checkout <tag>` inside the submodule |
| Forgetting to `git add oauth2-proxy` | Submodule pointer not updated in parent | Always stage the submodule directory after checkout |
| Go version mismatch | No GOTOOLCHAIN=local fallback | Verify go.mod version vs UBI go-toolset before updating |
| Not updating `.gitmodules` branch field | Renovate still tracks the old tag | Run `git config -f .gitmodules submodule.oauth2-proxy.branch <new-tag>` |
