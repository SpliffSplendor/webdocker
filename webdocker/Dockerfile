FROM php:7.4-apache-buster
MAINTAINER Spliff Splendor "<Spliff.Splendor@gmail.com>"
ENV DEBIAN_FRONTEND=noninteractive

WORKDIR /var/www/html

# Install components
RUN apt-get update -y && apt-get install -y \
		curl \
		git-core \
		gzip \
		libcurl4-openssl-dev \
		libgd-dev \
        libfreetype6-dev \
        libjpeg62-turbo-dev \
        libpng-dev \
		libldap2-dev \
		libmcrypt-dev \
		libtidy-dev \
		libxslt-dev \
		libzip-dev \
		zlib1g-dev \
		libicu-dev \
		g++ \
		openssh-client \
		unzip \
		zip \
		sudo \
	--no-install-recommends

RUN curl -sS https://silverstripe.github.io/sspak/install | php -- /usr/local/bin && \
	curl -sS https://getcomposer.org/installer | php && mv composer.phar /usr/local/bin/composer && \
	pecl install xdebug && \
	apt-get autoremove -y && \
	rm -r /var/lib/apt/lists/*


# Install PHP Extensions
RUN pecl install mcrypt-1.0.3
RUN docker-php-ext-enable mcrypt
RUN docker-php-ext-configure intl
RUN docker-php-ext-configure mysqli --with-mysqli=mysqlnd
RUN docker-php-ext-configure ldap --with-libdir=lib/x86_64-linux-gnu/ 
# Install GD extensions
RUN docker-php-ext-configure gd --with-freetype --with-jpeg

RUN docker-php-ext-install -j$(nproc) \
		zip \
		intl \
		gd \
		ldap \
		mysqli \
		pdo \
		pdo_mysql \
		soap \
		tidy \
		xsl


COPY xdebug.ini /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini
RUN docker-php-ext-enable xdebug

COPY timezone.ini /usr/local/etc/php/conf.d/timezone.ini

# Make webserver run with
RUN addgroup --gid 1000 user

RUN	a2enmod rewrite expires remoteip cgid && \
	usermod -u 1000 www-data && \
	usermod -G 1000 www-data

EXPOSE 80

RUN php --version
RUN php -r 'print_r(gd_info());'

CMD ["apache2-foreground"]

