## -*- docker-image-name: "open-as-cgw" -*-
#
# Open AS Communication Gateway Dockerfile
# https://github.com/open-as-team/open-as-cgw
#

FROM ubuntu:16.04
MAINTAINER Open AS Team <team@openas.org>

# Build-time env var.
ARG DEBIAN_FRONTEND=noninteractive

# Prepare non-interactive.
RUN echo "debconf debconf/frontend select noninteractive" | debconf-set-selections && \
    echo "mysql-server mysql-server/root_password password" | debconf-set-selections && \
    echo "mysql-server mysql-server/root_password_again password" | debconf-set-selections && \
    echo "postfix postfix/main_mailer_type select Internet Site" | debconf-set-selections && \
    echo "postfix postfix/mailname string antispam.localdomain" | debconf-set-selections

# Update, Upgrade & Install.
RUN apt-get -y -q update && \
    apt-get -y -q upgrade && \
    apt-get -y -q install software-properties-common && \
    add-apt-repository -y ppa:open-as-team/ppa && \
    apt-get -y -q update && \
    apt-get -q -y install open-as-cgw

# Expose Ports.
EXPOSE 22 25 443

# Launch CLI.
CMD ["openas-cli"]
