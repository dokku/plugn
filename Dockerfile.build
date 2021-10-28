FROM golang:1.12.0-stretch

RUN apt-get update \
    && apt install apt-transport-https build-essential curl gnupg2 lintian rpm rsync rubygems-integration ruby-dev ruby -qy \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN gem install --no-ri --no-rdoc --quiet rake fpm package_cloud

WORKDIR /src

RUN curl -fsSLO https://get.docker.com/builds/Linux/x86_64/docker-1.12.1.tgz && tar --strip-components=1 -xvzf docker-1.12.1.tgz -C /usr/local/bin
