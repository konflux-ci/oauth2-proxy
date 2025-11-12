# Containerfile for Konflux build of oauth2-proxy

# Build arguments
ARG OAUTH2_PROXY_VERSION

# Build stage
FROM registry.access.redhat.com/ubi9/go-toolset:9.7-1762230058@sha256:c06c8764041cceae3ef35962b44043bfea534ad336d2cb14cafb5d0c384a5b5e AS builder

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
FROM registry.access.redhat.com/ubi9-micro:9.6-1760515026@sha256:558422e68b6b0f3cf96e61a295655c55be56b082bb51154b35884b93f37ce11f

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
