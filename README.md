# Docker-Volume-Sync
A docker volume container using [Unison](http://www.cis.upenn.edu/~bcpierce/unison/) for fast two-way folder sync. Created as an alternative to [slow docker for mac volumes on OS X](https://forums.docker.com/t/file-access-in-mounted-volumes-extremely-slow-cpu-bound/8076).

The approach taken by this container does not require unison to run on your host machine.
It also can be used in a way that does not require any extra scripts be run on the host
machine.

The container opens port 5001 after doing an initial sync. Any containers using
the synced volume can wait for this port to be open before using the volume.
There are several options for use for waiting like this: wait-for-it, wait-for,
wait4ports.

With this waiting strategy a simple `docker-compose up` can be used for your
dev environment.

If you can't modify the containers using the synced volume, then you probably want
to make a script that launches this container outside of the compose project with a
docker command. Then you should wait for the first sync to complete before starting any
containers using the synced volume.

## Usage

### Configuration
This container has few envs that you can alter.

`UNISON_DIR` - This is the directory which receives data from unison inside the container.
This is the directory you should use in other containers. Either with the `volumes_from` directive, or using a named volume.

`UNISON_HOST_DIR` - This should be the mounted host volume. The container will sync this directory with `UNISON_DIR`.

`UNISON_GID` - Group ID for the user running unison inside container.

`UNISON_UID` - User ID for the user running unison inside container.

`UNISON_USER` - User name for the sync user ( UID matters more )

`UNISON_GROUP` - Group name for the sync user ( GID matters more )

## Edge cases

This container tries to emulate a simple docker bind mounted volume. As such it
treats the UNISON_HOST_DIR as the main source of the files. If there is a conflict
it will use the file in the UNISON_HOST_DIR.  If the container is not running and a file
is removed from UNSION_DIR but not UNISON_HOST_DIR, then it will delete the file in
UNISON_HOST_DIR when it starts up.

The one bad edge case I can think of is if the container isn't running and you make
changes in UNISON_DIR, when the container starts up you will loose those changes.
However, this is roughly what happens with a bind mount. If you disconnect the bind mount,
then do work in the unmounted directory, those changes will be lost. The difference is
that when the bind mount is disconnected the unmounted directory will be empty so that
is a good clue something is wrong.  In the case of this container the directory will
still be populated. I have not run into this issue yet in practice. If you do, please
file an issue, there might be a way to improve the behavior.

## Testing

There are no automated tests. But the files in `demo` can be used to run a manual test.

First cd into `demo`

Then run `generate_test_files.sh` this will generate 200 random files in a test_files
directory.

Then run `docker-compose up`. Docker compose will build a image for a `unison` service
and a image for a `reader` service.  After these images are built you should see the
`unison` service syncing all of the random files. And you should see the `reader` image
waiting for the files to be sync'd before printing the contents of the zzz.txt file.

## Credits
This is based off of https://github.com/onnimonni/docker-unison

The idea of bridging two volumes with unison running internally came from
[docker-sync](https://github.com/EugenMayer/docker-sync)

## License
This docker image is licensed under GPLv3 because Unison is licensed under GPLv3 and is included in the image. See LICENSE.
