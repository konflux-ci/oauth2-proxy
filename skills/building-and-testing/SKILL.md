---
name: building-and-testing
description: Use when building the container image locally, running upstream tests, or linting. Covers submodule init, podman build, make test, and golangci-lint.
---

# Building and Testing

## Quick Reference

| Action | Command |
|--------|---------|
| Init submodule | `git submodule update --init --recursive` |
| Build image | `podman build --build-arg OAUTH2_PROXY_VERSION=<tag> -f Containerfile -t oauth2-proxy .` |
| Build Go binary | `cd oauth2-proxy && make build` |
| Run tests | `cd oauth2-proxy && make test` |
| Lint Go | `cd oauth2-proxy && golangci-lint run` |
| Lint YAML | `yamllint <file>` |
| Lint Containerfile | `hadolint Containerfile` |

## Test Suite

Tests live in the upstream submodule and use Go's standard `testing` package with race detection and coverage enabled. Run `make test` in the submodule root.

## Container Build

The Containerfile is a two-stage build:
1. **Builder** (`ubi10/go-toolset`): compiles with `CGO_ENABLED=0` and version ldflags
2. **Runtime** (`ubi10/ubi-minimal`): copies binary + stub JWT signing key, runs as UID 65532

The build also creates a stub `jwt_signing_key.pem` — this is expected and used as a default placeholder.

## Linting

The upstream repo uses `golangci-lint` with a `.golangci.yml` config. Run it from the submodule directory:

```bash
cd oauth2-proxy && golangci-lint run
```

The upstream also supports multiple build variants (distroless, alpine) but the Konflux build only produces the UBI-based image.
