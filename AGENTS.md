# oauth2-proxy (Konflux Build)

Konflux wrapper repo for the upstream [oauth2-proxy](https://github.com/oauth2-proxy/oauth2-proxy). The actual Go source lives in the `oauth2-proxy/` git submodule — this repo owns only the build configuration and CI plumbing.

## Build & Verify Commands

| Action | Command |
|---|---|
| Init submodule | `git submodule update --init --recursive` |
| Build image | `podman build --build-arg OAUTH2_PROXY_VERSION=<tag> -f Containerfile -t oauth2-proxy .` |
| Lint YAML | `yamllint <file>` |
| Lint Containerfile | `hadolint Containerfile` |
| Build upstream Go | `cd oauth2-proxy && make build` |
| Test upstream Go | `cd oauth2-proxy && make test` |
| Lint upstream Go | `cd oauth2-proxy && golangci-lint run` |

### Single-File Verification

- YAML: `yamllint path/to/file.yaml`
- Containerfile: `hadolint Containerfile`
- Shell scripts: `shellcheck path/to/script.sh`

## Project Layout

- `Containerfile` — multi-stage build (UBI10 Go toolset → UBI10 minimal)
- `oauth2-proxy/` — git submodule tracking upstream tags (currently `v7.15.2`)
- `.tekton/` — Konflux pipeline definitions (pull-request, push, pipeline)
- `.github/workflows/` — CI linting (yamllint, hadolint), auto-merge for bot PRs, dependency triage
- `CODEOWNERS` — PR approval routing (`@konflux-ci/infrastructure`)

## Key Conventions

- The submodule tracks tags, not branches — `git submodule update --remote` will not work. To update: `cd oauth2-proxy && git fetch --tags && git checkout <tag>`.
- Container builds are handled by Konflux, not GitHub Actions. GitHub Actions handle linting (`lint.yaml`), auto-merge (`auto-merge.yaml`), and dep-triage (`dep-triage.yaml`).
- The build injects the version via `-ldflags` using the `OAUTH2_PROXY_VERSION` build arg.
- A stub `jwt_signing_key.pem` is created at build time and copied to the runtime image at `/etc/ssl/private/`.
- Runtime image runs as non-root (UID 65532).
- Build produces a static binary (`CGO_ENABLED=0`).

## Multi-arch Builds

When updating base image digests in the Containerfile, always use the **manifest list** digest, not a platform-specific digest:

```bash
skopeo inspect --raw docker://registry.access.redhat.com/ubi10/go-toolset:<tag> \
  | sha256sum | cut -d' ' -f1
```

Platform-specific digests (e.g., from `podman inspect`) break non-amd64 builds silently.

## PR Conventions

- All changes via PR with CODEOWNERS approval.
- Submodule update commits: `chore: update oauth2-proxy to <tag>`.

## Gotchas

See `skills/` for detailed guides — load only what's relevant:
- `updating-submodule/` — tag checkout workflow, version injection
- `building-and-testing/` — local build, upstream test suite, golangci-lint
- `ci-cd-quirks/` — Tekton pipelines, GitHub Actions scope, multi-arch digests
