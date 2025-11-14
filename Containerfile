# Containerfile for Konflux build of oauth2-proxy

# Build arguments
ARG OAUTH2_PROXY_VERSION

# Build stage
FROM registry.access.redhat.com/ubi9/go-toolset:9.7-1763038106@sha256:380d6de9bbc5a42ca13d425be99958fb397317664bb8a00e49d464e62cc8566c AS builder

# Redeclare ARG for this stage
ARG OAUTH2_PROXY_VERSION

# Set working directory to the submodule location
WORKDIR /workspace/oauth2-proxy

# Copy go mod files first for better layer caching
COPY oauth2-proxy/go.mod oauth2-proxy/go.sum ./

# Download dependencies
RUN go mod download

# Copy the rest of the source code
COPY oauth2-proxy/ ./

# Build the binary
RUN CGO_ENABLED=0 go build -a -installsuffix cgo \
    -ldflags="-X github.com/oauth2-proxy/oauth2-proxy/v7/pkg/version.VERSION=${OAUTH2_PROXY_VERSION}" \
    -o oauth2-proxy github.com/oauth2-proxy/oauth2-proxy/v7 && \
    touch jwt_signing_key.pem

# Runtime stage
FROM registry.access.redhat.com/ubi9-micro:9.7-1762965531@sha256:e14a8cbcaa0c26b77140ac85d40a47b5e910a4068686b02ebcad72126e9b5f86

# Copy binary from builder stage
COPY --from=builder /workspace/oauth2-proxy/oauth2-proxy /bin/oauth2-proxy
COPY --from=builder /workspace/oauth2-proxy/jwt_signing_key.pem /etc/ssl/private/jwt_signing_key.pem

LABEL org.opencontainers.image.licenses=MIT \
    org.opencontainers.image.description="A reverse proxy that provides authentication with Google, Azure, OpenID Connect and many more identity providers. Built by Konflux." \
    org.opencontainers.image.documentation=https://oauth2-proxy.github.io/oauth2-proxy/ \
    org.opencontainers.image.source=https://github.com/oauth2-proxy/oauth2-proxy \
    org.opencontainers.image.title=oauth2-proxy \
    org.opencontainers.image.vendor=Konflux \
    org.opencontainers.image.version=${OAUTH2_PROXY_VERSION}

ENTRYPOINT ["/bin/oauth2-proxy"]
