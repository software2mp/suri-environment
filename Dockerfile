# GCC support can be specified at major, minor, or micro version
# (e.g. 8, 8.2 or 8.2.0).
# See https://hub.docker.com/r/library/gcc/ for all supported GCC
# tags from Docker Hub.
# See https://docs.docker.com/samples/library/gcc/ for more on how to use this image
FROM ubuntu:14.04

USER root

RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install --yes --no-install-recommends \
        subversion \
        g++ \
        cmake \
        nsis \
        libglib2.0-0 \
        libgif-dev \
        libjpeg-turbo8-dev \
        zlib1g-dev \
        libtiff-dev \
        libgl1-mesa-dev \
        libglu1-mesa-dev \
        libgtk2.0-dev \
        libexpat1-dev \
        bc \
        autotools-dev \
        make \
        patch \
        libcurl4-openssl-dev \
        libgeotiff-dev \
        libhdf5-serial-dev \
        libgeos-dev \
        cppcheck \
        doxygen \
        graphviz \
        cccc \
        xauth \
        dos2unix \
        tofrodos \
        unzip \
        libglw1-mesa \
        libglw1-mesa-dev \
        libglu1-mesa-dev \
        libglu1 \
        autoconf \
        automake \
        bash \
        bison \
        bzip2 \
        flex \
        gettext \
        git \
        intltool \
        libffi-dev \
        libtool \
        libltdl-dev \
        libssl-dev \
        libxml-parser-perl \
        openssl \
        patch \
        perl \
        pkg-config \
        scons \
        sed \
        unzip \
        wget \
        xz-utils \
        mingw32 \
        fakeroot \
        debconf \
        mingw-w64-common \
        gcc-mingw-w64-base \
        gcc-mingw-w64-i686 \
        g++-mingw-w64-i686 \
        mingw-w64-i686-dev \
    && rm -rf /var/lib/apt/lists/*

RUN useradd builder --create-home --shell /bin/bash

USER builder 

WORKDIR /home/builder

ARG WINPREFIX="-i686-w64-mingw32"

# Windows environment
RUN mkdir -p /home/builder/environment/bin /home/builder/environment/scripts /home/builder/environment/src
COPY bin/* /home/builder/environment/bin/
COPY scripts/* /home/builder/environment/scripts/
# RUN chmod a+x /home/builder/environment/scripts/*.sh
COPY src/* /home/builder/environment/src/
RUN mkdir -p /home/builder/opt
RUN for i in $(ls -1 /home/builder/environment/bin/*.tar.bz2 | grep -i MinGW | grep -vi debug) ; do tar -jxvf $i -C /home/builder/opt ; done
RUN mv $HOME/opt/local $HOME/opt/local${WINPREFIX}
RUN cd $HOME/opt/local${WINPREFIX}/bin ; ./wx-config-change-prefix.sh "\/home\/builder\/opt\/local${WINPREFIX}"


# Linux environment
RUN mkdir -p /home/builder/environment/bin /home/builder/environment/scripts /home/builder/environment/src
COPY bin/* /home/builder/environment/bin/
COPY scripts/* /home/builder/environment/scripts/
# RUN chmod a+x /home/builder/environment/scripts/*.sh
COPY src/* /home/builder/environment/src/
RUN mkdir -p /home/builder/opt
RUN for i in $(ls -1 /home/builder/environment/bin/*.tar.bz2 | grep -vi MinGW | grep -vi debug) ; do tar -jxvf $i -C /home/builder/opt ; done
RUN tar -zxvf /home/builder/environment/bin/*x64*.tar.gz -C /home/builder/opt
RUN cd $HOME/opt/local/bin ; ./wx-config-change-prefix.sh "\/home\/builder\/opt\/local"

# to eliminate problems when trying to determine if it is version-tracked (when hosted on SVN)
RUN echo '#!/bin/bash\n\
\n\
[[ $1 == "-n" ]] && echo -n "26699" || true\n\
\n\
[[ "$1" == "-c" ]] && echo "691:21699" || true' > /home/builder/opt/local/bin/svnversion && chmod a+x /home/builder/opt/local/bin/svnversion

# Set environment variables for building
RUN echo '#!/bin/bash -x\n\
\n\
echo "Loading SuriLib environment"\n\
\n\
PREFIX=$HOME/opt/local\n\
WINPREFIX=${WINPREFIX}\n\
\n\
export LD_LIBRARY_PATH=${PREFIX}/lib:${PREFIX}${WINPREFIX}/lib:$LD_LIBRARY_PATH:/usr/lib:/lib\n\
export PATH=${PREFIX}/bin:${PREFIX}${WINPREFIX}/bin:${PREFIX}${WINPREFIX}/lib:$HOME/.local/bin:$PATH\n\
\n\
' >> $HOME/.build_environment

# Builds linux packages
RUN mv /home/builder/opt /home/builder/opt.bak
RUN mv /home/builder/environment/bin /home/builder/environment/bin.orig
RUN mkdir -p /home/builder/environment/bin
RUN cd environment/scripts/ ; bash ./build-all.sh
# to eliminate problems when trying to determine if it is version-tracked (when hosted on SVN)
RUN echo '#!/bin/bash\n\
\n\
[[ $1 == "-n" ]] && echo -n "26699" || true\n\
\n\
[[ "$1" == "-c" ]] && echo "691:21699" || true' > /home/builder/opt/local/bin/svnversion && chmod a+x /home/builder/opt/local/bin/svnversion
RUN mv /home/builder/environment/bin /home/builder/environment/bin.built
RUN mv /home/builder/environment/bin.orig /home/builder/environment/bin
RUN rm -rf /home/builder/opt
RUN mv /home/builder/opt.bak /home/builder/opt


# This command runs your application, comment out this line to compile only
CMD echo "Done"

LABEL Name=surilib-environment Version=2.0.0
