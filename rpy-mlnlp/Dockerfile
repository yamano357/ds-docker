FROM r-centos7-devtoolset8

ARG CRAN_REPOS="https://cran.ism.ac.jp/"

RUN set -x && \
    yum install -y --enablerepo=epel \
    # "RODBC"
    unixODBC-devel \
    # "rgl"
    glibc \
    glibc-devel \
    libpng \
    libpng-devel \ 
    freeglut-devel \
    mesa-libGL-devel \
    freeglut-devel \
    # "gmp"
    gmp-devel \
    # "Rmpfr" 
    mpfr-devel \
    # "gsl" 
    gsl \
    gsl-devel \
    # "V8" 
    v8-devel \
    compat-libicu4 \
    # "nloptr" 
    NLopt \
    NLopt-devel \
    # "Rglpk"     
    glpk \ 
    glpk-devel \
    # Cairo
    cairo \
    cairo-devel \
    libXt-devel \
    libX11-devel \
    pango-devel \
    libtiff-devel \
    openjpeg \
    openjpeg-devel \
    libjpeg-turbo-devel \
    harfbuzz \
    harfbuzz-devel \
    # rsvg
    gobject-introspection \
    gobject-introspection-devel \
    cairo-gobject \
    cairo-gobject-devel \
    librsvg2 \
    librsvg2-devel \
    # "magick"
    ImageMagick-c++-devel \
    # bayesplot 
    pandoc \
    pandoc-citeproc \ 
    # imager
    fftw3 \
    libtif \
    # jqr
    jq-devel \
    # RPostgres
    libpq \
    # units,udunits2
    udunits-2 \
    # datapasta
    xsel \
    # MxNet
    openblas \
    openblas-devel \
    lapack \
    lapack-devel \
    atlas \
    atlas-devel \
    gperftools-devel \
    jemalloc-devel \
    opencv \
    opencv-devel \
    # Python3
    python36-devel \
    python36-setuptools && \
    yum clean all


COPY requirements.txt r-ml-requirements.txt r-userdef-requirements.txt install_rpkg.R ./
RUN set -x && \
    easy_install-3.6 pip && \
    pip3 --no-cache-dir install -U pip setuptools && \
    pip3 --no-cache-dir install -r requirements.txt

RUN set -x && \
    Rscript -e "remotes::install_version(package = 'remotes', version = '2.0.2', repos = c(CRAN = '${CRAN_REPOS}'))" && \
    Rscript install_rpkg.R r-ml-requirements.txt ${CRAN_REPOS} && \
    Rscript install_rpkg.R r-userdef-requirements.txt ${CRAN_REPOS}

RUN set -x && \
    git clone --recursive https://github.com/apache/incubator-mxnet.git && \
    cd incubator-mxnet && \ 
    make -j $(nproc) USE_OPENCV=1 USE_BLAS=openblas && \
    sed -i "s/, dependencies = TRUE)/, dependencies = TRUE, upgrade = 'always')/" Makefile && \ 
    make rpkg && \
    cd .. && \
    rm -rf incubator-mxnet

RUN set -x && \
  git clone --recursive https://github.com/microsoft/LightGBM && \
  cd LightGBM && \
  Rscript build_r.R && \
  cd .. && \
  rm -rf LightGBM

RUN set -x && \
  Rscript -e "remotes::install_github('catboost/catboost', subdir = 'catboost/R-package')"


# MeCab/CaboCha
RUN set -x && \
  wget http://packages.groonga.org/centos/7/x86_64/Packages/groonga-release-1.4.0-1.noarch.rpm --quiet && \
  rpm -ivh groonga-release-1.4.0-1.noarch.rpm && \
  rm groonga-release-1.4.0-1.noarch.rpm && \
  yum install -y --enablerepo=groonga \
    xz \
    mecab \
    mecab-devel \
    mecab-ipadic && \
  wget "https://drive.google.com/uc?export=download&id=0B4y35FiV1wh7QVR6VXJ5dWExSTQ" -O CRF++.tar.gz --quiet && \
  tar -zxf CRF++.tar.gz && \
  cd CRF++-0.58 && \
  ./configure && \
  make -j $(nproc) && \
  make install && \
  ldconfig && \
  cd .. && \
  DOWNLOAD_URL="https://drive.google.com`curl -s -c cookies.txt 'https://drive.google.com/uc?export=download&id=0B4y35FiV1wh7SDd1Q1dUQkZQaUU' | sed -r 's/"/\n/g' | grep id=0B4y35FiV1wh7SDd1Q1dUQkZQaUU | grep confirm | sed 's/&amp;/\&/g'`" && \
  curl -s -L -b cookies.txt -o cabocha.tar.bz2 "$DOWNLOAD_URL" && \
  tar -jxf cabocha.tar.bz2 && \
  cd cabocha-0.69 && \
  ./configure --with-mecab-config=`which mecab-config` --with-charset=UTF8 && \
  make -j $(nproc) && \
  make install && \
  ldconfig && \
  cd .. && \
  rm CRF++.tar.gz cabocha.tar.bz2 && \
  rm -rf CRF++* cabocha* && \
  yum clean all

RUN set -x && \
  pip3 --no-cache-dir install \
    mecab-python3 \
    cabocha-python && \  
  Rscript -e "options(Ncpus = parallel::detectCores()); install.packages(pkgs = 'RMeCab', repos = 'http://rmecab.jp/R', type = 'source')" && \
  yum clean all
