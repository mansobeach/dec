#########################################################################
#
#     Dockerfile.dec.naos.nl2-u-moc-srv-01.gsc4eo  
#
#########################################################################
#
# Dockerfile for DEC @ NAOS UAP
# 
# ALPINE
# https://hub.docker.com/_/alpine
# https://pkgs.alpinelinux.org/packages
#
FROM alpine:3.16
# ================================================
RUN apk update && apk add --no-cache build-base
RUN apk --no-cache add curl
RUN apk --no-cache add git
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
# RUN ln -s /usr/bin/entrypoint_dec_naos_nl2-s-aut-srv-01_gsc4eo.sh /    
# ------------------------------------------------
# RUN gem update
# ------------------------------------------------
# ------------------------------------------------
# Patch log4r
COPY ./install/patch/rollingfileoutputter.rb /usr/local/bundle/gems/log4r-1.1.10/lib/log4r/outputter/
# ------------------------------------------------
# ------------------------------------------------
SHELL ["/bin/bash", "-c"]
USER gsc4eo
# Install asdf
WORKDIR /home/gsc4eo
RUN echo $PWD
RUN git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.10.2
RUN source ~/.asdf/asdf.sh
ENV PATH="/home/gsc4eo/.asdf/bin:/home/gsc4eo/.asdf/shims:$PATH"
RUN asdf plugin add ruby https://github.com/asdf-vm/asdf-ruby.git
RUN asdf install ruby 3.1.2
RUN asdf local ruby 3.1.2; asdf reshim ruby
#
COPY ./install/gems/dec_latest.gem .
RUN gem install dec_latest.gem
#
COPY ./install/gems/aux_latest.gem .
RUN gem install aux_latest.gem
#
RUN   mkdir -p /home/gsc4eo/.ssh
COPY --chown=2020:2020 ./config/ssh/* /home/gsc4eo/.ssh/
COPY --chown=2020:2020 ./config/ssh/naos-aiv.id_rsa /home/gsc4eo/.ssh/id_rsa
# COPY --chown=2020:2020 ./config/ssh/known_hosts /home/gsc4eo/.ssh/known_hosts
ENV USER=gsc4eo HOSTNAME=dec GEM_HOME=/usr/local/bundle PATH="/usr/local/bundle/bin:${PATH}"
# "------------------------------------------------
# CMD [ "/bin/bash" ]
# ENTRYPOINT [ "/bin/bash" ]
ENTRYPOINT ["/usr/bin/entrypoint_dec_naos_nl2-s-aut-srv-01_gsc4eo.sh"]
