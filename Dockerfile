FROM inetsoftware/alpine-tesseract:4.1.0 as builder

# dummy builder container

FROM alpine

ENV LC_ALL C

# copy the packages
COPY --from=builder /tesseract/tesseract-git-* /tesseract/

RUN set -x \
    && echo "http://dl-cdn.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories \
    && apk add --update --allow-untrusted /tesseract/tesseract-git-* \
    && rm -rf /tesseract

USER root

RUN \
  apk add openjdk8 && \
  rm -rf /var/cache/apk/*

ENV JAVA_HOME /usr/lib/jvm/java-1.8-openjdk
