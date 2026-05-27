# Stage 1: Build the Flutter web application
FROM debian:bookworm-slim AS build

# Install build dependencies
RUN apt-get update && apt-get install -y \
    curl \
    git \
    unzip \
    xz-utils \
    zip \
    libglu1-mesa \
    && rm -rf /var/lib/apt/lists/*

# Clone the Flutter stable SDK with a depth of 1 to minimize image size and download time
RUN git clone https://github.com/flutter/flutter.git -b stable --depth 1 /usr/local/flutter

# Add flutter to environment path
ENV PATH="/usr/local/flutter/bin:/usr/local/flutter/bin/cache/dart-sdk/bin:${PATH}"

# Pre-cache flutter development binaries and run doctor
RUN flutter doctor

# Set work directory
WORKDIR /app

# Copy dependencies manifest first to utilize docker cache
COPY pubspec.yaml pubspec.lock ./

# Fetch pub dependencies
RUN flutter pub get

# Copy the rest of the application files
COPY . .

# Build argument for target entry point (e.g. lib/main.dart or lib/admin_web_main.dart)
ARG ENTRY_POINT=lib/main.dart

# Build the web application targeting the specified entry point
RUN flutter build web --target=${ENTRY_POINT} --release

# Stage 2: Serve the compiled app with Nginx
FROM nginx:alpine

# Copy custom Nginx configuration for client-side routing fallback
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copy build output from Stage 1 to Nginx default public directory
COPY --from=build /app/build/web /usr/share/nginx/html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
