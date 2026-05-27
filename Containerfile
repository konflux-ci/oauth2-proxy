# Containerfile for Konflux build of oauth2-proxy

# Build arguments
ARG OAUTH2_PROXY_VERSION

# Build stage
FROM registry.access.redhat.com/ubi10/go-toolset:10.2-1779831202@sha256:2a25b4be2dcc671b854a31c5b0269b9de0574a7f24f64dc1d6bf1c472ed18049 AS builder

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
FROM registry.access.redhat.com/ubi10/ubi-minimal@sha256:5af8e51abe2a81b4247f05219284a627d37fb9ccf1055b90528a246fac11bc4d

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
