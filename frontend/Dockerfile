# build stage — pin to Flutter 3.24.x which generates flutter_bootstrap.js
FROM ghcr.io/cirruslabs/flutter:3.24.5 AS builder
WORKDIR /app
COPY . .
RUN flutter pub get
# Note: --web-renderer html is deprecated in Flutter 3.24 and ignored.
# CanvasKit is the only renderer. Speed is improved via CDN loading in index.html.
RUN flutter build web --release --base-href /

# serve with nginx
FROM nginx:alpine
COPY --from=builder /app/build/web /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD wget --quiet --tries=1 --spider http://localhost/health || exit 1
