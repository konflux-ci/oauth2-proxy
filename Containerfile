# Containerfile for Konflux build of oauth2-proxy

# Build arguments
ARG OAUTH2_PROXY_VERSION

# Build stage
FROM registry.access.redhat.com/ubi10/go-toolset:10.1-1763633883@sha256:182645783ad0a0af4a78d928f2d9167815d59c12cc156aa3c229cf3a49d636d9 AS builder

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
FROM registry.access.redhat.com/ubi10-micro:10.1-1763138307@sha256:fc8e116afac12a9164be775e21483da7b6e86f91d8e9e6e79dee23afe4e58468

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
