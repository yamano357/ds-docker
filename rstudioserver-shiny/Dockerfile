FROM rpy-mlnlp

ARG RSTUDIO_VER="1.2.1335"
ARG SHINY_VER="1.5.9.923"
ARG CRAN_REPOS="https://cran.ism.ac.jp/"
ARG PASSWORD="rstudio"

RUN set -x && \
    yum update -y && \
    yum install -y \
        supervisor \
        nginx && \
    yum clean all
    
RUN set -x && \    
    Rscript -e "options(Ncpus = parallel::detectCores()); install.packages(pkgs = c('shiny', 'plumber'), repos = c(CRAN = '${CRAN_REPOS}'), type = 'source')"


# Install RStudio server & Shiny server
ENV PATH /usr/lib/rstudio-server/bin/:$PATH 
RUN set -x && \
    wget https://download2.rstudio.org/server/centos6/x86_64/rstudio-server-rhel-${RSTUDIO_VER}-x86_64.rpm --quiet && \
    yum install -y --nogpgcheck rstudio-server-rhel-${RSTUDIO_VER}-x86_64.rpm && \ 
    rm -rf rstudio-server-rhel-${RSTUDIO_VER}-x86_64.rpm && \
    yum clean all
RUN set -x && \
    echo 'www-port=8787' >> /etc/rstudio/rserver.conf && \
    echo "rsession-which-r=$(which R)" >> /etc/rstudio/rserver.conf && \
    echo 'session-timeout-minutes=0' >> /etc/rstudio/profiles && \
    groupadd rstudio && \
    useradd -g rstudio rstudio && \
    echo ${PASSWORD} | passwd rstudio --stdin

RUN set -x && \
    wget https://download3.rstudio.org/centos6.3/x86_64/shiny-server-${SHINY_VER}-x86_64.rpm --quiet && \
    yum install -y --nogpgcheck shiny-server-${SHINY_VER}-x86_64.rpm && \ 
    rm -rf shiny-server-${SHINY_VER}-x86_64.rpm && \
    yum clean all
COPY shiny-server.conf /etc/shiny-server/shiny-server.conf
RUN set -x && \
    mkdir -p /var/log/shiny-server && \
    chown shiny:shiny /var/log/shiny-server && \
    chown shiny:shiny -R /srv/shiny-server && \
    chmod 755 -R /srv/shiny-server && \
    chown shiny:shiny -R /opt/shiny-server/samples/sample-apps && \
    chmod 755 -R /opt/shiny-server/samples/sample-apps


COPY nginx.conf /etc/nginx/nginx.conf
RUN set -x && \
  chmod +x /etc/nginx/

COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
RUN set -x && \
    mkdir -p /var/log/supervisor && \ 
    chmod 755 -R /var/log/supervisor

EXPOSE 80
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"] 

