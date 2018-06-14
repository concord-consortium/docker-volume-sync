FROM onnimonni/unison:latest
MAINTAINER Scott Cytacki <scytacki@concord.org>

# Install in one run so that build tools won't remain in any docker layers
# Install build tools
RUN apk add --update nmap-ncat && \
    rm -rf /var/cache/apk/*

# Overwrite the entrypoint included with docker-unison
COPY entrypoint.sh /entrypoint.sh

# Default host directory
ENV UNISON_HOST_DIR="/host_data"

EXPOSE 5001
ENTRYPOINT ["/sbin/tini", "--", "/entrypoint.sh"]
