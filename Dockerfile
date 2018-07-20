ARG PLEX_VER=1.13.4.5271-200287a06
ARG PLEX_SHA=aa6c14a966188d486b99526144f9fd0012421e2b
ARG LIBSTDCPP_VER=6.3.0-18+deb9u1
ARG LIBGCC1_VER=6.3.0-18+deb9u1

FROM spritsail/debian-builder:stretch-slim as builder

ARG PLEX_VER
ARG PLEX_SHA
ARG LIBSTDCPP_VER
ARG LIBGCC1_VER

WORKDIR /tmp

RUN mkdir -p /output/usr/lib /output/{lib, sbin}

RUN curl -fsSL -o libstdcpp.deb http://ftp.de.debian.org/debian/pool/main/g/gcc-${LIBSTDCPP_VER:0:1}/libstdc++6_${LIBSTDCPP_VER}_amd64.deb \
 && curl -fsSL -o libgcc1.deb http://ftp.de.debian.org/debian/pool/main/g/gcc-${LIBGCC1_VER:0:1}/libgcc1_${LIBGCC1_VER}_amd64.deb \
 && dpkg-deb -x libstdcpp.deb . \
 && dpkg-deb -x libgcc1.deb . \
 # We only need the lib files, everything else is debian junk.
 && mv $PWD/usr/lib/x86_64-linux-gnu/* /output/usr/lib \
 # Maybe /lib
 && mv $PWD/lib/x86_64-linux-gnu/* /output/usr/lib

RUN curl -fsSL -o plexmediaserver.deb https://downloads.plex.tv/plex-media-server/${PLEX_VER}/plexmediaserver_${PLEX_VER}_amd64.deb \
 && echo "$PLEX_SHA  plexmediaserver.deb" | sha1sum -c - \
 && dpkg-deb -x plexmediaserver.deb . \
 && mv usr/lib/plexmediaserver /output/usr/lib


ADD start_pms /output/usr/sbin/start_pms
RUN chmod +x /output/usr/sbin/start_pms

#=========================

FROM spritsail/libressl

ARG PLEX_VER
ARG LIBSTDCPP_VER
ARG LIBGCC1_VER

LABEL maintainer="Spritsail <plex@spritsail.io>" \
      org.label-schema.vendor="Spritsail" \
      org.label-schema.name="Plex Media Server" \
      org.label-schema.url="https://www.plex.tv/downloads/" \
      org.label-schema.description="Tiny Docker image for Plex Media Server, built on busybox" \
      org.label-schema.version=${PLEX_VER} \
      io.spritsail.version.plex=${PLEX_VER} \
      io.spritsail.version.libstdcpp=${LIBSTDCPP_VER} \
      io.spritsail.version.libgcc1=${LIBGCC1_VER}

ENV SUID=900 SGID=900

COPY --from=builder /output/ /

HEALTHCHECK --interval=10s --timeout=5s \
    CMD [ "wget", "-O", "/dev/null", "-T", "10", "-q", "localhost:32400/identity" ]

WORKDIR /usr/lib/plexmediaserver

EXPOSE 32400

ENTRYPOINT ["/sbin/tini", "--"]
CMD ["/usr/sbin/start_pms"]
