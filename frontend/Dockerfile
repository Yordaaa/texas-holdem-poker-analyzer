# build stage
FROM ghcr.io/cirruslabs/flutter:latest AS builder
WORKDIR /app
COPY . .
RUN flutter pub get
RUN flutter build web --release

# serve with nginx
FROM nginx:alpine
COPY --from=builder /app/build/web /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD wget --quiet --tries=1 --spider http://localhost/health || exit 1
