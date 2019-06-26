FROM centos:latest

# bash
SHELL ["/bin/bash", "-c"]

# set timezone
RUN set -x && \
    /bin/cp -f /usr/share/zoneinfo/Asia/Tokyo /etc/localtime && \
    sed -i -e '/override_install_langs/s/$/,ja_JP.utf8/g' /etc/yum.conf

# devtoolset-8
RUN set -x && \
    yum update -y && \
    yum install -y \
        epel-release \
        centos-release-scl \
        scl-utils && \
    yum install -y --enablerepo=centos-sclo-rh --disablerepo=epel \
        devtoolset-8-gcc \
        devtoolset-8-gcc-c++ \
        devtoolset-8-gcc-gfortran \
        devtoolset-8-make \
        devtoolset-8-binutils \
        devtoolset-8-binutils-devel \
        devtoolset-8-gcc-plugin-devel \
        devtoolset-8-libstdc++-devel \
        devtoolset-8-libquadmath-devel && \ 
    yum clean all

RUN echo "source scl_source enable devtoolset-8" | tee -a /etc/profile.d/devtoolset8.sh && \
    source scl_source enable devtoolset-8
ENV PATH="/opt/rh/devtoolset-8/root/usr/bin:${PATH}"

# lib
RUN set -x && \
    yum install -y --disablerepo=epel \
        ipa-gothic-fonts \
        ipa-mincho-fonts \
        ipa-pgothic-fonts \
        ipa-pmincho-fonts \
        glibc-common \
        kernel-headers \
        glibc-devel \
        glibc-headers \
        make \
        cmake \
        cmake3 \
        pkgconfig \
        which \
        tar \
        bzip2-devel \
        bzip2-libs \
        xz-devel \
        xz-libs \
        zlib \
        zlib-devel \
        wget \
        curl \
        curl-devel \
        libcurl-devel \
        xml2 \
        libxml2-devel \
        xml-commons-apis \
        expat-devel \
        openssl-devel \
        libicu \
        libicu-devel \
        libX11 \
        libX11-devel \
        libxcb \
        libxcb-devel \
        libXau \
        libXau-devel \
        libXft-devel \
        libXrender-devel \
        xorg-x11-proto-devel \
        pcre \
        pcre-devel \
        tcl-devel \
        tk-devel \
        texinfo \
        texinfo-tex \
        texlive-epsf \
        fontconfig-devel \
        freetype-devel \
        pandoc \
        libffi \
        fftw-devel \
        libtiff-devel \
        cargo \
        mpfr \
        rpmdevtools \
        libuuid-devel \
        pam-devel \
        libmpc \
        pango-devel \
        ant \
        java-1.8.0-openjdk \
        java-1.8.0-openjdk-devel \
        libxslt-devel \
        mesa-libGL-devel \
        libXScrnSaver-devel \
        fakeroot \
        postgresql-devel\
        boost-devel \
        git \
        libgit2-devel \
        libssh2-devel \
        nginx && \
    yum clean all

RUN set -x && \
    yum install -y --enablerepo=epel \
        openblas \
        openblas-devel && \
#        lapack \
#        lapack-devel \
#        atlas \
#        atlas-devel && \
    yum clean all

ARG R_VER="3.5.3"
ARG CRAN_REPOS="https://cran.ism.ac.jp/"

# get MRO
RUN set -x && \
    wget --quiet https://mran.blob.core.windows.net/install/mro/${R_VER}/rhel/microsoft-r-open-${R_VER}.tar.gz && \
    tar -xf microsoft-r-open-${R_VER}.tar.gz && \
    ./microsoft-r-open/install.sh -u -a && \
    rm -rf microsoft-r-open-${R_VER}.tar.gz && \
    rm -rf microsoft-r-open && \
    yum clean all

RUN set -x && \
    sed -i 's/CXX11 = g++/CXX11 = g++ -std=c++11/' $(R RHOME)/etc/Makeconf && \ 
    sed -i 's/CXX11FLAGS = -DU_STATIC_IMPLEMENTATION -g -O2/CXX11FLAGS = -O3 -Wno-unused-variable -Wno-unused-function/' $(R RHOME)/etc/Makeconf && \ 
    sed -i 's/CXX11STD = -std=gnu++11/CXX11STD = -std=c++11/' $(R RHOME)/etc/Makeconf && \ 
    sed -i 's/CXX14 = /CXX14 = g++ -std=c++14/' $(R RHOME)/etc/Makeconf && \ 
    sed -i 's/CXX14FLAGS = /CXX14FLAGS = -O3 -Wno-unused-variable -Wno-unused-function/' $(R RHOME)/etc/Makeconf && \ 
    sed -i 's/CXX14PICFLAGS = /CXX14PICFLAGS = -fpic/' $(R RHOME)/etc/Makeconf && \ 
    sed -i 's/CXX14STD = /CXX14STD = -std=c++14/' $(R RHOME)/etc/Makeconf && \ 
    sed -i 's/CXX17 = /CXX17 = g++ -std=c++1z/' $(R RHOME)/etc/Makeconf && \ 
    sed -i 's/CXX17FLAGS = /CXX17FLAGS = -O3 -Wno-unused-variable -Wno-unused-function/' $(R RHOME)/etc/Makeconf && \ 
    sed -i 's/CXX17PICFLAGS = /CXX17PICFLAGS = -fpic/' $(R RHOME)/etc/Makeconf && \ 
    sed -i 's/CXX17STD = /CXX17STD = -std=c++1z/' $(R RHOME)/etc/Makeconf && \
    R CMD javareconf

RUN set -x && \
    Rscript -e "options(Ncpus = parallel::detectCores()); install.packages(pkgs = c('remotes', 'curl', 'httr', 'extrafont'), repos = c(CRAN = '${CRAN_REPOS}'), type = 'source')"
RUN set -x && \
    Rscript -e "options(Ncpus = parallel::detectCores()); remotes::install_cran(pkgs = c('tidyverse'), repos = c(CRAN = '${CRAN_REPOS}'), type = 'source')"

# 
#ENV LANG="ja_JP.UTF-8" \
#    LANGUAGE="ja_JP:ja" \
#    LC_ALL="ja_JP.UTF-8"
RUN set -x && \
    localedef -f UTF-8 -i ja_JP ja_JP.UTF-8 && \
    Rscript -e "extrafont::font_import(prompt = FALSE)"
