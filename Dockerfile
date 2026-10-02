# syntax=docker/dockerfile:1
FROM docker.io/richarvey/nginx-php-fpm:3.1.6

WORKDIR /var/www/html

# Image config
ENV SKIP_COMPOSER 1
ENV WEBROOT /var/www/html/public
ENV PHP_ERRORS_STDERR 1
ENV RUN_SCRIPTS 1
ENV REAL_IP_HEADER 1

# Laravel config
ENV APP_ENV production
ENV APP_DEBUG false
ENV LOG_CHANNEL stderr

# Allow composer to run as root
ENV COMPOSER_ALLOW_SUPERUSER 1

# Install PHP dependencies. Kept ahead of the application code so the layer is
# only rebuilt when composer.json or composer.lock changes.
COPY composer.json composer.lock ./
RUN --mount=type=cache,target=/root/.composer/cache,sharing=locked \
    sh -c 'mkdir -p database/seeds database/factories && composer update \
        --no-dev \
        --optimize-autoloader \
        --no-scripts \
        --no-interaction \
        --no-progress \
        --prefer-dist \
        && cp composer.lock /composer.lock'

# Application code
COPY . .

# Keep the lock file that matches the installed vendor tree, so the
# composer install run at container start has nothing left to download.
RUN cp /composer.lock composer.lock

# Hand the writable paths to the web user at build time. This makes it safe to
# start the container with SKIP_CHOWN=1, which skips the recursive chown of the
# entire application tree that would otherwise dominate start-up time.
RUN chown -R nginx:nginx storage bootstrap/cache

CMD ["/start.sh"]
