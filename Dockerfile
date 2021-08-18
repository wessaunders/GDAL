FROM ubuntu:focal

ENV DEBIAN_FRONTEND=noninteractive
ENV GDAL_VERSION 3.3.1
ENV SDKS_URL https://bin.extensis.com/download/developer
ENV MRSID_VERSION 9.5.4.4709-rhel6.x86-64.gcc482
ENV MRSID_NAME MrSID_DSDK-$MRSID_VERSION
ENV MRSID_DIR /usr/local/src/$MRSID_NAME

RUN apt-get -qq update && \
    apt-get -qq -y --no-install-recommends install autoconf \
    ant \
    automake \
    build-essential \
    curl \
    dpkg-dev \
    libcurl3-gnutls-dev \
    libepsilon-dev \
    libexpat-dev \
    libfreexl-dev \
    libgeos-dev \
    libgif-dev \
    libhdf4-alt-dev \
    libhdf5-serial-dev \
    libjpeg-dev \
    liblcms2-dev \
    liblzma-dev \
    libnetcdf-dev \
    libpcre3-dev \
    libproj-dev \
    libspatialite-dev \
    libsqlite3-dev \
    libtbb2 \
    libtiff-dev \
    libwebp-dev \
    libxerces-c-dev \
    libxml2-dev \
    netcdf-bin \
    openjdk-11-jdk \
    pkg-config \
    proj-bin \
    proj-data \
    python-dev \
    software-properties-common \
    sqlite3 \
    swig \
    unixodbc-dev \
    unzip \
    wget

RUN curl -s $SDKS_URL/$MRSID_NAME.tar.gz | tar xz -C /usr/local/src \
    && cp $MRSID_DIR/Raster_DSDK/lib/libltidsdk.so* /usr/lib \
    && cp $MRSID_DIR/Lidar_DSDK/lib/liblti_lidar_dsdk.so* /usr/lib

#update lt_platform.h to work with gcc version 5
RUN  sed -i "s|#if (defined(__GNUC__) || defined(__GNUG__)) && (3 <= __GNUC__ && __GNUC__ <= 5)|#if (defined(__GNUC__) || defined(__GNUG__)) && (3 <= __GNUC__) |g" \
    /usr/local/src/$MRSID_NAME/Raster_DSDK/include/lt_platform.h
#COPY lt_platform.h /usr/local/src/$MRSID_NAME/Raster_DSDK/include

RUN mkdir -p /usr/local/src && \
    curl -s http://download.osgeo.org/gdal/$GDAL_VERSION/gdal-$GDAL_VERSION.tar.gz | tar xz -C /usr/local/src

WORKDIR /usr/local/src/gdal-$GDAL_VERSION

RUN ./configure \
    --prefix=/usr/local \
    --without-libtool \
    --with-epsilon \
    --with-libkml \
    --with-liblzma \
    --with-mrsid=$MRSID_DIR/Raster_DSDK \
    --with-mrsid_lidar=$MRSID_DIR/Lidar_DSDK \
    --with-spatialite \
    --with-threads \
    --with-webp \
    && make \
    && make install \
    && ldconfig


ENV JAVA_HOME /usr/lib/jvm/java-11-openjdk-amd64
WORKDIR /usr/local/src/gdal-$GDAL_VERSION/swig/java

COPY java.opt /usr/local/src/gdal-$GDAL_VERSION/swig/java
RUN cd /usr/local/src/gdal-$GDAL_VERSION/swig/java \
    && make    
