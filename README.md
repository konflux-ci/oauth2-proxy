# OAuth2-Proxy Konflux Build

This repository contains the build configuration for creating OAuth2-Proxy container images using Konflux CI. The upstream OAuth2-Proxy project is included as a git submodule.

## Overview

This repository provides:

- **Containerfile**: Multi-stage build configuration using Red Hat UBI images
- **Git submodule**: Links to the upstream [oauth2-proxy](https://github.com/oauth2-proxy/oauth2-proxy) project
- **Konflux integration**: Automated CI/CD pipeline configuration

## Quick Start

1. **Initialize the submodule**:

   ```bash
   git submodule update --init --recursive
   ```

   **Note:** The submodule is configured to track tags (not branches) for automated dependency updates via MontMaker/Renovate. This means `git submodule update --remote` will not work as expected. To manually update the submodule to a different tag, navigate to the submodule directory and run:

   ```bash
   cd oauth2-proxy
   git fetch && git checkout <branch | tag-name>
   ```

   depending of if you want to checkout a branch or a tag.

2. **Build locally using Docker**:

   ```bash
   docker build -f Containerfile -t oauth2-proxy .
   ```

## Local Development

For local testing and development, you can use the upstream project's build system:

```bash
cd oauth2-proxy
make build
```

### Submodule Updates

This repository uses MintMaker/Renovate to automatically update the git submodule when new stable semantic version tags are released upstream. The `.gitmodules` file is configured with `branch = v7.12.0` to track tags rather than branches.

**⚠️ Important:** This configuration disrupts the native Git submodule update workflow. The standard `git submodule update --remote` command will fail with an error like `fatal: Unable to find refs/remotes/origin/v7.12.0 revision in submodule path...` because Git expects the `branch` field to reference an actual branch, not a tag.

To manually update the submodule to a specific tag:

```bash
cd oauth2-proxy
git fetch --tags
git checkout  <branch> | <tag-name>
cd ..
git add oauth2-proxy
git commit -m "Update submodule to <branch | tag-name>"
```

depending of if you want to checkout a branch or a tag.

Renovate will automatically create pull requests when new tags matching semantic versioning are available upstream.

### Version Information

- **Current stable version**: `v7.12.0`
- **Go version**: `1.24.6`
- **Supported architectures**: `linux/amd64`

## Upstream Project

For complete documentation, features, and usage instructions, please refer to the upstream project:

**📖 [OAuth2-Proxy Documentation](https://oauth2-proxy.github.io/oauth2-proxy/)**

**🔗 [Upstream Repository](https://github.com/oauth2-proxy/oauth2-proxy)**

## Konflux Integration

This repository is designed to work with Konflux CI/CD pipelines. The actual container builds are handled by Konflux using their own build task and the provided `Containerfile`.

### Konflux Build Process

- **Automated builds**: Konflux automatically builds containers when changes are pushed
- **Submodule management**: Konflux handles submodule updates via mintmaker
- **Security scanning**: Konflux runs security scans and compliance checks
- **Registry publishing**: Konflux pushes built images to configured registries

### Local Testing vs Konflux Builds

| Aspect | Local Docker Build | Konflux Build |
|--------|-------------------|---------------|
| **Purpose** | Local testing and validation | Production builds |
| **Trigger** | Manual execution | Automated on git changes |
| **Environment** | Your local machine | Konflux build environment |
| **Security** | Basic build validation | Full security scanning |
| **Registry** | Local/optional push | Automated registry push |
| **Compliance** | Not applicable | Full compliance checks |

### Containerfile Features

The `Containerfile` provides:

- **Red Hat UBI base images**: Uses UBI9 Go toolset for building and UBI9 minimal for runtime
- **Pinned image versions**: Uses specific SHA hashes for reproducible builds
- **Multi-stage builds**: Optimized image size with separate build and runtime stages
- **Layer caching optimization**: Dependencies downloaded only when `go.mod` changes
- **Cross-platform support**: Builds for multiple architectures
- **Security focused**: Minimal runtime image with only necessary dependencies
- **Proper labeling**: Traceability and compliance metadata

## License

This build configuration follows the same MIT license as the upstream OAuth2-Proxy project.
