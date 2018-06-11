# Docker-Volume-Sync
A docker volume container using [Unison](http://www.cis.upenn.edu/~bcpierce/unison/) for fast two-way folder sync. Created as an alternative to [slow docker for mac volumes on OS X](https://forums.docker.com/t/file-access-in-mounted-volumes-extremely-slow-cpu-bound/8076).

If the UNISON_HOST_DIR is used then this container does not require unison to be installed
on your host machine.

The container opens port 5001 after doing an initial sync. Any containers using
the synced volume can wait for this port to be open before using the volume.
There are several options for use for waiting like this: wait-for-it, wait-for, wait4ports

If this waiting strategy is used then a simple `docker-compose up` can be used for your
dev environment.

## Usage

### Configuration
This container has few envs that you can alter.

`UNISON_DIR` - This is the directory which receives data from unison inside the container.
This is also the directory which you can use in other containers with `volumes_from` directive.

`UNISON_HOST_DIR` - If this variable is defined the container will sync this directory with `UNISON_DIR` instead of running a server. The intention is that this HOST_DIR is a mounted host volume. This makes it possible to get fullspeed disk access without installing unison on the host.  

`UNISON_GID` - Group ID for the user running unison inside container.

`UNISON_UID` - User ID for the user running unison inside container.

`UNISON_USER` - User name for the sync user ( UID matters more )

`UNISON_GROUP` - Group name for the sync user ( GID matters more )

## Testing

There are no automated tests. But the docker-compose.yml, Dockerfile.reader, and
generate_test_files.sh can be used to run a manual test.

First run `generate_test_files.sh` this will generate 200 random files in a test_files
directory.

Then run `docker-compose up`. Docker compose will build two images and bring them up.
You should see the main container (called unison in docker-compose) syncing all of the
random files. And you should see the `reader` image waiting for the files to be sync'd
before printing the contents of the zzz.txt file.

## Credits
This is based off of https://github.com/onnimonni/docker-unison

The idea of bridging two volumes with unison running internally came from
[docker-sync](https://github.com/EugenMayer/docker-sync)

## License
This docker image is licensed under GPLv3 because Unison is licensed under GPLv3 and is included in the image. See LICENSE.
