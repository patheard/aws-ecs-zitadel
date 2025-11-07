FROM ghcr.io/zitadel/zitadel:v3.4.3@sha256:953be2d2d40348cf7cb504a65300f9208d0ab4df45b167425487ee95853dee20

# Copy configuration and certificates
COPY --chown=zitadel:zitadel ./*.yaml ./certificate.crt ./private.key /app/
