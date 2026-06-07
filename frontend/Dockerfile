# --- Stage 1: Build the Flutter Web App ---
FROM debian:bookworm-slim AS build-env

# 1. Install system prerequisites
RUN apt-get update && apt-get install -y curl git unzip xz-utils zip libglu1-mesa && rm -rf /var/lib/apt/lists/*

# 2. Clone Flutter (This will be cached unless you change the branch)
RUN git clone https://github.com/flutter/flutter.git -b stable /usr/local/flutter
ENV PATH="/usr/local/flutter/bin:/usr/local/flutter/bin/cache/dart-sdk/bin:${PATH}"

# 3. CRITICAL: Pre-download the Flutter/Dart SDK binaries BEFORE copying your code
RUN flutter doctor -v
RUN flutter precache --web

WORKDIR /app

# 4. Copy ONLY pubspec files first to cache your package dependencies
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

# 5. Copy the rest of your source code (Changes here won't re-download Flutter!)
COPY . .

# 6. Accept arguments and build
ARG WEB_API_URL
RUN flutter build web --release --dart-define=WEB_API_URL=$WEB_API_URL

# --- Stage 2: Serve via Nginx ---
FROM nginx:alpine
COPY --from=build-env /app/build/web /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]