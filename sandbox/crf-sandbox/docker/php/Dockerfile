# Image de base épinglée par digest (immuable), tag conservé pour la lisibilité.
# Maintenu par Dependabot (écosystème docker). ADR 0084.
FROM php:8.5-apache@sha256:ede24dfd13fe79fb8ea0d0bac0ac45827a9a540d2a16e45c047f9afaf69c3eaf

# Install required PHP extensions for REDCap
RUN apt-get update && apt-get install -y \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libpng-dev \
    libzip-dev \
    libicu-dev \
    libldap2-dev \
    libxml2-dev \
    libcurl4-openssl-dev \
    unzip \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Configure and install PHP extensions.
# `opcache` est omis de `docker-php-ext-install` : compilé en statique
# dans php:8.5-apache, la commande échoue avec `cp: cannot stat 'modules/*'`
# car aucune extension partagée n'est produite. L'activation se fait via
# php.ini (bloc redcap-recommended ci-dessous).
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) \
        gd \
        mysqli \
        pdo_mysql \
        zip \
        intl \
        ldap \
        soap \
        curl

# Enable Apache modules
RUN a2enmod rewrite headers

# Configure Apache
RUN echo "ServerName localhost" >> /etc/apache2/apache2.conf

# Set recommended PHP settings for REDCap
RUN { \
    echo 'upload_max_filesize = 128M'; \
    echo 'post_max_size = 128M'; \
    echo 'max_execution_time = 600'; \
    echo 'max_input_time = 600'; \
    echo 'memory_limit = 512M'; \
    echo 'date.timezone = Europe/Paris'; \
    echo 'opcache.enable = 1'; \
    echo 'opcache.enable_cli = 1'; \
    echo 'opcache.memory_consumption = 128'; \
    echo 'opcache.max_accelerated_files = 10000'; \
    echo 'opcache.revalidate_freq = 2'; \
} > /usr/local/etc/php/conf.d/redcap-recommended.ini

# Set working directory
WORKDIR /var/www/html

# Expose port 80
EXPOSE 80
