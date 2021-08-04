FROM php:7.3-apache

ARG PSR_VERSION=1.0.1
ARG PHALCON_VERSION=3.4.4
ARG PHALCON_EXT_PATH=php7/64bits

ENV APACHE_DOCUMENT_ROOT=/var/www/html/public

COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

RUN set -xe && \
    # Download PSR, see https://github.com/jbboehr/php-psr
    curl -LO https://github.com/jbboehr/php-psr/archive/v${PSR_VERSION}.tar.gz && \
    tar xzf ${PWD}/v${PSR_VERSION}.tar.gz && \
    # Download Phalcon
    curl -LO https://github.com/phalcon/cphalcon/archive/v${PHALCON_VERSION}.tar.gz && \
    tar xzf ${PWD}/v${PHALCON_VERSION}.tar.gz && \
    docker-php-ext-install -j $(getconf _NPROCESSORS_ONLN) \
    ${PWD}/php-psr-${PSR_VERSION} \
    ${PWD}/cphalcon-${PHALCON_VERSION}/build/${PHALCON_EXT_PATH} \
    && \
    # Remove all temp files
    rm -r \
    ${PWD}/v${PSR_VERSION}.tar.gz \
    ${PWD}/php-psr-${PSR_VERSION} \
    ${PWD}/v${PHALCON_VERSION}.tar.gz \
    ${PWD}/cphalcon-${PHALCON_VERSION} \
    && \
    php -m \
    #1 development packages
    && apt-get update \
    && apt-get install --no-install-recommends -y \
    git \
    zip \
    curl \
    unzip \
    libzip-dev \
    libicu-dev \
    libbz2-dev \
    libpng-dev \
    libjpeg-dev \
    libmcrypt-dev \
    libreadline-dev \
    libfreetype6-dev \
    g++ \    
    && apt-get clean \
    # 2. apache configs + document root
    && sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf \
    && sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf \
    # 3. mod_rewrite for URL rewrite and mod_headers for .htaccess extra headers like Access-Control-Allow-Origin-
    && a2enmod rewrite headers \
    # 4. start with base php config, then add extensions
    && mv "$PHP_INI_DIR/php.ini-development" "$PHP_INI_DIR/php.ini" \
    && docker-php-ext-install \
    bz2 \
    intl \
    iconv \
    bcmath \
    opcache \
    calendar \
    pdo_mysql \
    zip \
    gd \
    #change uid and gid of apache to docker user uid/gid
    && usermod -u 1000 www-data && groupmod -g 1000 www-data \
    && chown -R www-data:www-data /var/www/html \
    && chmod g+w -R /var/www/html \
    #change timezone
    && export DEBIAN_FRONTEND=noninteractive \
    && ln -fs /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime \
    && apt-get install -y tzdata \
    && dpkg-reconfigure --frontend noninteractive tzdata

RUN composer global require phalcon/devtools \
    && ln -s ~/.composer/vendor/bin/phalcon /usr/local/bin/phalcon \
    && chmod ugo+x /usr/local/bin/phalcon
