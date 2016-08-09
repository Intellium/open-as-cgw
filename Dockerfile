## -*- docker-image-name: "open-as-cgw" -*-
#
# Open AS Communication Gateway Dockerfile
# https://github.com/open-as-team/open-as-cgw
#

# Pull base image.
FROM ubuntu:xenial

# Maintainer.
MAINTAINER Open AS Team <team@openas.org>

# Install.
RUN \
  export DEBIAN_FRONTEND="noninteractive"  && \
  debconf-set-selections <<< "debconf debconf/frontend select noninteractive"  && \
  debconf-set-selections <<< "mysql-server mysql-server/root_password password"  && \
  debconf-set-selections <<< "mysql-server mysql-server/root_password_again password"  && \
  debconf-set-selections <<< "postfix postfix/main_mailer_type select Internet Site"  && \
  debconf-set-selections <<< "postfix postfix/mailname string antispam.localdomain"  && \
  add-apt-repository -y ppa:open-as-team/ppa  && \
  apt-get -y -q update && apt-get -y -q upgrade  && \
  apt-get -q -y install open-as-cgw

# Set environment variables.
ENV HOME /root

# Define working directory.
WORKDIR /root

# Define default command.
CMD ["bash"]
