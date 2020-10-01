FROM amd64/debian:buster
MAINTAINER Florian Lohoff <f@zz.de>

USER root 
RUN ( grep "^deb " /etc/apt/sources.list | sed -e 's/^deb/deb-src /' >>/etc/apt/sources.list ) \
	&& apt-get update \
        && echo 'APT::Install-Recommends "false";' >/etc/apt/apt.conf.d/99norecommends \
        && echo 'APT::Install-Suggests "false";' >/etc/apt/apt.conf.d/99nosuggests \
        && DEBIAN_FRONTEND=noninteractive apt-get -y dist-upgrade \
        && DEBIAN_FRONTEND=noninteractive apt-get -fy install build-essential \
		gcc-8-mipsel-linux-gnu binutils-mipsel-linux-gnu \
		gcc-8-mips-linux-gnu binutils-mips-linux-gnu \
		gcc-mips64el-linux-gnuabi64 binutils-mips64el-linux-gnuabi64 \
		git jq \
		flex bison libssl-dev gzip bzip2 lzma bc \
        && apt-get clean \
	&& ln -s /usr/bin/mips-linux-gnu-gcc-8 /usr/bin/mips-linux-gnu-gcc
