FROM php:8.2-apache

# Installation des dépendances
RUN apt-get update && apt-get install -y \
    libzip-dev \
    unzip \
    git \
    && docker-php-ext-install mysqli pdo pdo_mysql

# Installation Redis
RUN pecl install redis && docker-php-ext-enable redis

# Activer rewrite Apache
RUN a2enmod rewrite

# Copier les fichiers du projet
COPY . /var/www/html/

# Permissions
RUN chown -R www-data:www-data /var/www/html

EXPOSE 80