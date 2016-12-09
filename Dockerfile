FROM ruby:2.1.3
MAINTAINER Son Pham <son.pham@jmango360.com>
 
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys B97B0AFCAA1A47F044F244A07FCC7D46ACCC4CF8
RUN echo "deb http://apt.postgresql.org/pub/repos/apt/ precise-pgdg main" > /etc/apt/sources.list.d/pgdg.list
RUN apt-get update && apt-get -y -q install python-software-properties software-properties-common \
    && apt-get -y -q install postgresql-9.3 postgresql-client-9.3 postgresql-contrib-9.3 libpq-dev postgresql-server-dev-9.3

RUN apt-get -y install locales
RUN echo 'en_US.UTF-8 UTF-8'>>/etc/locale.gen
RUN locale-gen
ENV LANG en_US.UTF-8

RUN useradd -m cocoadocs && echo "cocoadocs:cocoadocs" | chpasswd && adduser cocoadocs sudo
RUN chown -R cocoadocs:cocoadocs /usr/local

USER cocoadocs

WORKDIR /home/cocoadocs/app
 
COPY . /home/cocoadocs/app
 
#!/bin/bash

RUN gem update bundler

RUN bundle install

## Install brew
RUN git clone https://github.com/Linuxbrew/brew.git ~/.linuxbrew
RUN export PATH="$HOME/.linuxbrew/bin:$PATH"
RUN export MANPATH="$HOME/.linuxbrew/share/man:$MANPATH"
RUN export INFOPATH="$HOME/.linuxbrew/share/info:$INFOPATH"

EXPOSE 5555