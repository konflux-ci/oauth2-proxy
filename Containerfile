# Containerfile for Konflux build of oauth2-proxy

# Build arguments
ARG OAUTH2_PROXY_VERSION

# Build stage
FROM registry.access.redhat.com/ubi10/go-toolset:10.2-1786959166@sha256:26d2558491a2ec993c46fc13c68ebb7638737661825d9876b40311f5e585d7c2 AS builder

# Redeclare ARG for this stage
ARG OAUTH2_PROXY_VERSION

# Set working directory to the submodule location
WORKDIR /opt/app-root/src

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
FROM registry.access.redhat.com/ubi10/ubi-minimal@sha256:61f820b7893b6226e499e928db99c59a0a9135aa17e4e056fdaf1015908cca14

# Copy binary from builder stage
COPY --from=builder /opt/app-root/src/oauth2-proxy /bin/oauth2-proxy
COPY --from=builder /opt/app-root/src/jwt_signing_key.pem /etc/ssl/private/jwt_signing_key.pem
USER 65532:65532

LABEL org.opencontainers.image.licenses=MIT \
    org.opencontainers.image.description="A reverse proxy that provides authentication with Google, Azure, OpenID Connect and many more identity providers." \
    org.opencontainers.image.documentation=https://oauth2-proxy.github.io/oauth2-proxy/ \
    org.opencontainers.image.source=https://github.com/oauth2-proxy/oauth2-proxy \
    org.opencontainers.image.title=oauth2-proxy \
    org.opencontainers.image.vendor=Konflux \
    org.opencontainers.image.version=${OAUTH2_PROXY_VERSION} \
    com.redhat.component=oauth2-proxy \
    description="A reverse proxy that provides authentication with Google, Azure, OpenID Connect and many more identity providers." \
    distribution-scope=public \
    io.k8s.description="A reverse proxy that provides authentication with Google, Azure, OpenID Connect and many more identity providers." \
    name=oauth2-proxy \
    release=${OAUTH2_PROXY_VERSION} \
    url=https://github.com/oauth2-proxy/oauth2-proxy \
    vendor="Red Hat, Inc." \
    version=${OAUTH2_PROXY_VERSION} \
    maintainer="Konflux Infrastructure Team <konflux-infra@redhat.com>"

ENTRYPOINT ["/bin/oauth2-proxy"]
