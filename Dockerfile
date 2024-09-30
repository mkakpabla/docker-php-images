# Set the base image for subsequent instructions
FROM php:8.3-fpm

LABEL Maintainer="Michel AKPABLA <mk.akpabla@gmail.com>"
LABEL Description="Lightweight container with Nginx 1.26 & PHP 8.3"

# Install dependencies
RUN apt-get update && apt-get install -y \
    nginx \
    supervisor \
    build-essential \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    zip \
    curl \
    unzip \
    git \
    libzip-dev \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libpng-dev \
    libbz2-dev \
    libzip-dev \
    autoconf \ 
    bash \ 
    libtool

ARG PROTOBUF_VERSION="3.21.1"
RUN pecl channel-update pecl.php.net \
    && MAKEFLAGS="-j $(nproc)" pecl install protobuf-${PROTOBUF_VERSION} grpc

RUN mv "$PHP_INI_DIR/php.ini-development" "$PHP_INI_DIR/php.ini"

RUN docker-php-ext-configure gd \
    --with-jpeg \
    --with-freetype

RUN docker-php-ext-install \
    bcmath \
    bz2 \
    calendar \
    intl \
    mbstring \
    opcache \
    pdo_mysql \
    gd \
    exif \
    pcntl \
    bz2 \
    zip

RUN docker-php-ext-enable \
    protobuf \
    grpc

# Installer Node.js (version LTS) et Yarn
RUN curl -sL https://deb.nodesource.com/setup_16.x | bash - && \
    apt-get install -y nodejs && \
    npm install -g yarn

# Clear cache
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

COPY ./nginx/default.conf /etc/nginx/conf.d/default.conf

COPY ./supervisord.conf /etc/supervisor/conf.d/supervisord.conf


# Set working directory
WORKDIR /usr/share/nginx/html

# Override default nginx welcome page
COPY ./site /usr/share/nginx/html

EXPOSE 80

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]