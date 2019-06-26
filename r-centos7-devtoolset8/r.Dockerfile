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
        centos-release-scl \
        epel-release \
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
        readline-devel \
        libX11 \
        libX11-devel \
        libXt-devel \
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
        texlive \
        texlive-epsf \
        levien-inconsolata-fonts \
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
        lapack \
        lapack-devel \
        openblas \
        openblas-devel && \
    yum clean all

# https://community.rstudio.com/t/texlive-distribution-on-centos-for-rstudio-server-and-connect/2916/2
RUN set -x && \
    wget http://mirrors.ctan.org/install/fonts/inconsolata.tds.zip  && \
    mkdir inconsolata && \
    unzip inconsolata.tds.zip -d inconsolata && \
    cp -r inconsolata/* /usr/share/texmf && \
    mktexlsr && \
    rm inconsolata.tds.zip && \
    rm -rf inconsolata


ARG R_VER="3.6.0"
ARG CRAN_REPOS="https://cran.ism.ac.jp/"

# get R
RUN set -x && \
    wget --quiet https://cran.r-project.org/src/base/R-3/R-${R_VER}.tar.gz && \
    tar -xf R-${R_VER}.tar.gz && \
    cd R-${R_VER}/ && \
    ./configure --enable-memory-profiling --enable-R-shlib --with-blas --with-lapack && \
    make -j $(nproc) && \
    make install && \
    cd .. && \
    rm -rf R-${R_VER}.tar.gz && \
    rm -rf R-${R_VER} && \
    yum clean all

RUN set -x && \
    Rscript -e "options(Ncpus = parallel::detectCores()); install.packages(pkgs = c('remotes', 'curl', 'httr', 'extrafont'), repos = c(CRAN = '${CRAN_REPOS}'), type = 'source')"
RUN set -x && \
    Rscript -e "options(Ncpus = parallel::detectCores()); remotes::install_cran(pkgs = c('tidyverse'), repos = c(CRAN = '${CRAN_REPOS}'), type = 'source')"


ENV LANG="ja_JP.UTF-8" \
    LANGUAGE="en" \
    LC_ALL="ja_JP.UTF-8"
RUN set -x && \
    localedef -f UTF-8 -i ja_JP ja_JP.UTF-8 && \
    Rscript -e "extrafont::font_import(prompt = FALSE)"
