FROM php:7.4.2-fpm

# install the PHP extensions we need
RUN set -ex; \
  \
  savedAptMark="$(apt-mark showmanual)"; \
  \
  apt-get update; \
  apt-get install -y --no-install-recommends \
    libjpeg-dev \
    libpng-dev \
    libzip-dev \
  ; \
  \
  docker-php-ext-configure gd --with-jpeg; \
  docker-php-ext-install gd mysqli opcache zip; \
  \
  # reset apt-mark's "manual" list so that "purge --auto-remove" will remove all build dependencies
  apt-mark auto '.*' > /dev/null; \
  apt-mark manual $savedAptMark; \
  ldd "$(php -r 'echo ini_get("extension_dir");')"/*.so \
    | awk '/=>/ { print $3 }' \
    | sort -u \
    | xargs -r dpkg-query -S \
    | cut -d: -f1 \
    | sort -u \
    | xargs -rt apt-mark manual; \
  \
  apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false; \
  \
  # install msmtp tp make sendmail work after borrowed wp code
  apt-get install -y \
    msmtp \
  ; \
  rm -rf /var/lib/apt/lists/*

WORKDIR /var/www
