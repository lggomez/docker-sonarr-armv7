# syntax=docker/dockerfile:1

FROM debian:stable-slim

# set version label
ARG BUILD_DATE
ARG VERSION
ARG RADARR_RELEASE
LABEL build_version="Linuxserver.io armv7 fork version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="lggomez"

# environment settings
ENV XDG_CONFIG_HOME="/config/xdg"
ENV SONARR_CHANNEL="v4-stable"
ENV SONARR_BRANCH="main"

RUN \
  echo "**** install packages ****" && \
  apt-get -qy update && apt-get -qy upgrade && \
  DEBIAN_FRONTEND=noninteractive apt-get -qy install ca-certificates curl jq --no-install-recommends && \
  DEBIAN_FRONTEND=noninteractive apt-get -qy install sqlite3 libsqlite3-dev && \
  DEBIAN_FRONTEND=noninteractive apt-get -qy install \
    icu-devtools \
    xmlstarlet --no-install-recommends && \
  echo "**** install sonarr ****" && \
  mkdir -p /app/sonarr/bin && \
  if [ -z ${SONARR_VERSION+x} ]; then \
    SONARR_VERSION=$(curl -sX GET http://services.sonarr.tv/v1/releases \
    | jq -r "first(.[] | select(.releaseChannel==\"${SONARR_CHANNEL}\") | .version)"); \
  fi && \
  curl -o \
    /tmp/sonarr.tar.gz -L \
    "https://services.sonarr.tv/v1/update/${SONARR_BRANCH}/download?version=${SONARR_VERSION}&os=linux&runtime=netcore&arch=arm" && \
  tar xzf \
    /tmp/sonarr.tar.gz -C \
    /app/sonarr/bin --strip-components=1 && \
  echo -e "UpdateMethod=docker\nBranch=${SONARR_BRANCH}\nPackageVersion=${VERSION:-LocalBuild}\nPackageAuthor=[linuxserver.io](https://linuxserver.io)" > /app/sonarr/package_info && \
  echo "**** cleanup ****" && \
  rm -rf /var/lib/apt/lists/* && \
  rm -rf \
    /app/sonarr/bin/Sonarr.Update \
    /tmp/*

# copy local files
COPY root/ /

# ports and volumes
EXPOSE 8989

VOLUME /config

ENTRYPOINT ./app/sonarr/bin/Sonarr && bash
