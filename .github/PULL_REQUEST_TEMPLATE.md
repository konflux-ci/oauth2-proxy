## What

<!-- Brief description of the change -->

## Why

<!-- Motivation or link to Jira issue, e.g. KFLUXINFRA-1234 -->

## Verification

- [ ] `yamllint` passes on changed YAML files
- [ ] `hadolint Containerfile` passes (if Containerfile changed)
- [ ] `podman build -f Containerfile .` succeeds locally (if build-related change)
