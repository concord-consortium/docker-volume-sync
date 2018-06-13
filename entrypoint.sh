#!/usr/bin/env bash

# Create unison user and group
addgroup -g $UNISON_GID $UNISON_GROUP
adduser -u $UNISON_UID -G $UNISON_GROUP -s /bin/bash $UNISON_USER

# Create directory for filesync
if [ ! -d "$UNISON_DIR" ]; then
    echo "Creating $UNISON_DIR directory for sync..."
    mkdir -p $UNISON_DIR >> /dev/null 2>&1
fi

if [ ! -d "$UNISON_HOST_DIR" ]; then
    echo "Creating $UNISON_HOST_DIR directory for host sync..."
    mkdir -p $UNISON_HOST_DIR >> /dev/null 2>&1
fi

# /unison directory is created as a volume by onnimonni/unison
# make sure we can write to it
chown -R $UNISON_USER:$UNISON_GROUP /unison

# tell unison to use the /unison volume for its meta data,
# Because unison is writing to this often, it is better
# to be in a volume than on the root filesystem.
# However this is an anonymous volume, so it will be deleted if the container is
# removed.
export UNISON=/unison

# FIXME because the container might have been removed and the /unison folder cleared
#   it would be good to check if it is empty and if so then we delete the contents of
#   UNISON_DIR. This will force a full sync from UNISON_HOST_DIR

# FIXME it would be better to put the unison.log in a volume too, or just not log it
#    docker is logging this info anyhow

# Change data owner
chown -R $UNISON_USER:$UNISON_GROUP $UNISON_DIR

# Start process on path which we want to sync
cd $UNISON_DIR

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
