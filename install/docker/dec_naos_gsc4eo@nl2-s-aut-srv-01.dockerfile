#########################################################################
#
# Git:
#     Dockerfile.dec.naos.nl2-s-aut-srv-01.gsc4eo  
#                          $Author: bolf$
#                          $Date: 2018-11-13T11:54:43+01:00$ 
#                          $Committer: bolf$
#                          $Hash: f3afa7c$
#
#########################################################################
#
# Dockerfile for DEC @ NAOS SAP
# 
# ALPINE
# https://pkgs.alpinelinux.org/packages
#
FROM ruby:3.1.2-alpine
# ================================================
RUN apk update && apk add --no-cache build-base
RUN apk --no-cache add curl
RUN apk --no-cache add openssl curl-dev
RUN apk --no-cache add bash
RUN apk --no-cache add jq
RUN apk --no-cache add ncftp
RUN apk --no-cache add openssh
RUN apk --no-cache add sshpass
RUN apk --no-cache add libxml2 libxml2-utils
RUN apk --no-cache add p7zip
# change default shell from ash to bash
RUN sed -i -e "s/bin\/ash/bin\/bash/" /etc/passwd
# RUN apt-get update && \
#    apt-get install -y apt-utils && \
#    apt-get install -y --no-install-recommends \
#    net-tools \
#    ftp \
#    jq \
#    libxml2 \
#    libxml2-utils \
#    xml-twig-tools \
#    p7zip-full \
#    sqlite3 \
#    libsqlite3-dev \
#    sshpass \
#    ncftp \
#    curl \
#    vim
# ------------------------------------------------
# RUN apt-get install -y postgresql-client
# ------------------------------------------------
# ------------------------------------------------
#
# https://stackoverflow.com/questions/49955097/how-do-i-add-a-user-when-im-using-alpine-as-a-base-image
# https://wiki.alpinelinux.org/wiki/Setting_up_a_new_user
#
RUN addgroup -g 2020 -S gsc4eo && adduser -u 2020 -S gsc4eo -G gsc4eo -s /bin/bash
# DEBIAN user management:
#RUN groupadd -g 2020 gsc4eo && \
#    useradd -u 2020 -ms /bin/bash -g gsc4eo -d /home/gsc4eo gsc4eo
# ------------------------------------------------
COPY ./install/scripts/entrypoint_dec_naos_nl2-s-aut-srv-01_gsc4eo.sh /usr/bin/
RUN ln -s /usr/bin/entrypoint_dec_naos_nl2-s-aut-srv-01_gsc4eo.sh /    
# ------------------------------------------------
RUN gem update
# ------------------------------------------------
# DEC GEM
COPY ./install/gems/dec_latest.gem .
RUN gem install dec_latest.gem
# ------------------------------------------------
# AUX GEM
COPY ./install/gems/aux_latest.gem .
RUN gem install aux_latest.gem
# ------------------------------------------------
# Patch log4r
COPY ./install/patch/rollingfileoutputter.rb /usr/local/bundle/gems/log4r-1.1.10/lib/log4r/outputter/
# ------------------------------------------------
# MKDIR p /volumes/dec
RUN mkdir -p /volumes/dec/log && \
    chown -R 2020:2020 /volumes/dec
# ------------------------------------------------
USER gsc4eo
RUN   mkdir -p /home/gsc4eo/.ssh
COPY --chown=2020:2020 ./config/ssh/* /home/gsc4eo/.ssh/
COPY --chown=2020:2020 ./config/ssh/naos-aiv.id_rsa /home/gsc4eo/.ssh/id_rsa
# COPY --chown=2020:2020 ./config/ssh/known_hosts /home/gsc4eo/.ssh/known_hosts
ENV USER=gsc4eo HOSTNAME=dec GEM_HOME=/usr/local/bundle PATH="/usr/local/bundle/bin:${PATH}"
# "------------------------------------------------
# CMD [ "/bin/bash" ]
# ENTRYPOINT [ "/bin/bash" ]
ENTRYPOINT ["/usr/bin/entrypoint_dec_naos_nl2-s-aut-srv-01_gsc4eo.sh"]
