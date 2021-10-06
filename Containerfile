FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get -y upgrade
RUN apt-get install -y git build-essential nginx autoconf pkg-config bison re2c wget \
    libxml2-dev zlib1g-dev libcurl4-openssl-dev libssl-dev libreadline-dev libsqlite3-dev \
    libwebp-dev libpng-dev libjpeg-dev libxpm-dev libfreetype6-dev

RUN git clone https://github.com/php/php-src
# checkout the commit previous to the fix
RUN git -C php-src checkout ab061f95ca966731b1c84cf5b7b20155c0a1c06a && git -C php-src checkout HEAD~1

WORKDIR php-src

RUN wget --output-document=freetype.patch 'https://git.archlinux.org/svntogit/packages.git/plain/trunk/freetype.patch?h=packages/php&id=475a03df88b890ab3a5c7c8feac79d13b941e964'
RUN patch -p1 -i freetype.patch

RUN ./buildconf --force && ./configure --prefix=/usr/ \
    --with-config-file-path=/etc \
    --with-config-file-scan-dir=/etc/php.d \
    --enable-fpm \
    --with-fpm-user=www-data \
    --with-fpm-group=www-data \
    --enable-bcmath \
    --enable-intl \
    --enable-mbstring \
    --enable-pcntl \
    --enable-sockets \
    --enable-xmlreader \
    --enable-zip \
    --with-curl \
    --with-openssl \
    --with-gd \
    --enable-gd-native-ttf \
    --with-freetype-dir=/usr/include/freetype2 \
    --with-pdo-sqlite \
    --with-readline \
    --with-zlib \
    --without-pear

RUN make -j4 && make install

RUN mkdir -p /nextcry-php/usr/bin/ /nextcry-php/usr/sbin/ /nextcry-php/usr/include/ /nextcry-php/DEBIAN /nextcry-php/etc/ /nextcry-php/usr/lib/systemd/system/

RUN cp /usr/bin/php /nextcry-php/usr/bin/ && cp /usr/sbin/php-fpm /nextcry-php/usr/sbin/ && cp -R /usr/include/php /nextcry-php/usr/include/php

COPY php-fpm.service /nextcry-php/usr/lib/systemd/system/
COPY php-fpm.conf    /nextcry-php/etc/
COPY php.ini         /nextcry-php/etc/
COPY DEBIAN/*        /nextcry-php/DEBIAN/

RUN dpkg-deb --build /nextcry-php

