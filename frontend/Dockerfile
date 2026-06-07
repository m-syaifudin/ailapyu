# --- Stage 1: Build the Flutter Web App ---
FROM debian:bookworm-slim AS build-env

RUN apt-get update && apt-get install -y curl git unzip xz-utils zip libglu1-mesa && rm -rf /var/lib/apt/lists/*
RUN git clone https://github.com/flutter/flutter.git -b stable /usr/local/flutter
ENV PATH="/usr/local/flutter/bin:/usr/local/flutter/bin/cache/dart-sdk/bin:${PATH}"

WORKDIR /app
COPY . .

# 1. Accept the argument from docker-compose
ARG WEB_API_URL
# 2. Pass it into the build command using --dart-define
RUN flutter build web --release --dart-define=WEB_API_URL=$WEB_API_URL

# --- Stage 2: Serve via Nginx ---
FROM nginx:alpine
COPY --from=build-env /app/build/web /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]