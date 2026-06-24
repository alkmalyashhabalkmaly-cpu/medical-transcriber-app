# ── Stage 1: Build Flutter web ───────────────────────────────────────────────
FROM ghcr.io/cirruslabs/flutter:stable AS builder

WORKDIR /app
COPY pubspec.yaml pubspec.lock* ./
RUN flutter pub get

COPY . .
ARG API_BASE_URL=http://localhost:8000/api/v1
RUN flutter build web --dart-define=API_BASE_URL=$API_BASE_URL --release

# ── Stage 2: Serve with nginx ─────────────────────────────────────────────────
FROM nginx:alpine
COPY --from=builder /app/build/web /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
