#!/usr/bin/env bash

# Create unison user and group
addgroup -g $UNISON_GID $UNISON_GROUP
adduser -u $UNISON_UID -G $UNISON_GROUP -s /bin/bash $UNISON_USER

# Create directory for filesync
if [ ! -d "$UNISON_DIR" ]; then
    echo "Creating $UNISON_DIR directory for sync..."
    mkdir -p $UNISON_DIR >> /dev/null 2>&1
fi

# Create directory for unison meta
if [ ! -d "$UNISON_DIR/.unison" ]; then
    mkdir -p /unison >> /dev/null 2>&1
    chown -R $UNISON_USER:$UNISON_GROUP /unison
fi

# Symlink .unison folder from user home directory to sync directory so that we only need 1 volume
if [ ! -h "$UNISON_DIR/.unison" ]; then
    ln -s /unison /home/$UNISON_USER/.unison >> /dev/null 2>&1
fi

# Change data owner
chown -R $UNISON_USER:$UNISON_GROUP $UNISON_DIR

# Start process on path which we want to sync
cd $UNISON_DIR

if [ ! -d "$UNISON_HOST_DIR" ]; then
    echo "Creating $UNISON_HOST_DIR directory for host sync..."
    mkdir -p $UNISON_HOST_DIR >> /dev/null 2>&1
fi

# Use a bash array () to store the cmd to be used twice below
# Run as UNISON_USER
# Run unison syncing UNISON_HOST_DIR and UNISON_DIR
UNISON_CMD=(su-exec $UNISON_USER unison $UNISON_HOST_DIR $UNISON_DIR \
  -prefer $UNISON_HOST_DIR -auto -batch -ignore 'Path .git')

# do an initial sync so we can let other containers know we are ready to go
"${UNISON_CMD[@]}" "$@"

echo "Initial sync complete, opening port 5001 to let the world know"
ncat -k -l 5001 --sh-exec 'echo "unsion is running"' &

# replace this script with unison so it receives te signals
# run the sync continously watching for changes
exec "${UNISON_CMD[@]}" -repeat watch "$@"
