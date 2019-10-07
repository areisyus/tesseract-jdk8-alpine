FROM alpine:3.10 as builder

RUN set -x \
    # Add testing repository
    && echo "http://dl-cdn.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories \
    # Install SDK
    && apk update \
    && apk upgrade --no-cache apk-tools \
    && apk add --no-cache alpine-sdk \
    # Add user to build with
    && adduser -D -g "User" dev \
    && echo dev:dev | chpasswd \
    && echo "dev ALL=(ALL) ALL" >> /etc/sudoers \
    && echo "dev ALL=NOPASSWD: ALL" >> /etc/sudoers \
    && addgroup dev abuild \
    && mkdir -p /var/cache/distfiles \
    && chmod a+w /var/cache/distfiles

RUN set -x \
    # Add community repository
    && echo "http://dl-cdn.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories \
    # Install SDK
    && apk update \
    && apk add --no-cache autoconf-archive

# Add the APKBUILD File from
# https://git.alpinelinux.org/cgit/aports/tree/testing/tesseract-git/APKBUILD
ADD APKBUILD /home/dev/APKBUILD

# Add specific Patch files
ADD *.patch /home/dev/

USER dev

ARG SHA=5280bbcade4e2dec5eef439a6e189504c2eadcd9
ARG PKGVER=4.1.0
ARG PKGREL=1
ARG ADDITIONAL_OPTIONS

RUN set -x \
    && cd ~/ \
    # Prepare Environment
    && abuild-keygen -a -i -n \
    && abuild checksum \
    # Build
    && abuild -r

FROM openjdk:8-jdk-alpine

ENV LC_ALL C

# add required tessdata
RUN mkdir -p /usr/share/tessdata
ADD https://github.com/tesseract-ocr/tessdata/raw/master/eng.traineddata /usr/share/tessdata/eng.traineddata
ADD https://github.com/tesseract-ocr/tessdata/raw/master/deu.traineddata /usr/share/tessdata/deu.traineddata

RUN mkdir -p /tesseract

# Provide the packages in /tesseract folder
# Install using:
# apk add --allow-untrusted /tesseract/teseract-git-*
COPY --from=builder /home/dev/packages/home/x86_64/tesseract-git-* /tesseract/

# Update with full and community repositories
RUN apk add --update \
--repository http://dl-cdn.alpinelinux.org/alpine/edge/main \
--repository http://dl-cdn.alpinelinux.org/alpine/edge/community

# Add local repository for tesseract and install dependencies
RUN set -x \
    && echo "http://dl-cdn.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories \
    && apk add icu-libs icu-dev \
    && apk add --update --allow-untrusted /tesseract/tesseract-git-* \
    && rm -rf /tesseract \
    && rm /var/cache/apk/* \
    && echo "done"
