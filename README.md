# Docker-Volume-Sync
A docker volume container using [Unison](http://www.cis.upenn.edu/~bcpierce/unison/) for fast two-way folder sync. It is much faster than basic docker bind mounts on either Mac OS X or Windows.  The Docker folks are working on [speeding up the Mac OS X bind mounts](https://docs.docker.com/storage/bind-mounts/#configure-mount-consistency-for-macos) but they are still much slower than native speed.

When the development environment is configured correctly with docker-volume-sync, a developer doesn't need to remember any special commands. They just run `docker-compose up` as they normally would.

docker-volume-sync opens port 5001 after doing an initial sync. Any containers using the synced volume should wait for this port to be open before using the volume. Otherwise they will probably try to access files in the volume that are not there yet. There are several options to use for waiting: [wait-for-it](https://github.com/vishnubob/wait-for-it), [wait-for](https://github.com/eficode/wait-for), and [wait4ports](https://github.com/erikogan/wait4ports).

## Usage

### Compose file

docker-volume-sync is designed to work with compose. Let's say you have a compose file like the one below. It is mounting the host directory `.` to `/app` in the container. The container simply prints the contents of a file and then exits.

```yaml
version: '3'
services:
  app:
    build:
      context: .
    command: ["cat", "/app/test_files/zzz.txt"]
    volumes:
      - .:/app
```

To use docker-volume-sync you would change it to look like this:

```yaml
version: '3'
services:
  sync:
    image: concordconsortium/docker-volume-sync
    volumes:
      - sync-volume:/data
      - .:/host_data
  app:
    build:
      context: .
    entrypoint: ["/bin/bash", "/usr/local/bin/wait-for-it.sh", "sync:5001", "-s", "-t", "30", "--"]
    command: ["cat", "/app/test_files/zzz.txt"]
    depends_on: [ sync ]
    volumes:
      - sync-volume:/app
volumes:
  sync-volume:
```

You also need to change the app image to install the wait-for-it script. See the Waiting for Port section below.

These changes to the compose file can also be done using an overlay, so your original compose file can remain untouched. This overlay would look like this:

```yaml
version: '3'
services:
  sync:
    image: concordconsortium/docker-volume-sync
    volumes:
      - sync-volume:/data
      - .:/host_data
  app:
    entrypoint: ["/bin/bash", "/usr/local/bin/wait-for-it.sh", "sync:5001", "-s", "-t", "30", "--"]
    depends_on: [ sync ]
    volumes:
      - sync-volume:/app
volumes:
  sync-volume:
```

### Waiting for Port

In the example above wait-for-it is used to wait for the port. The Dockerfile for that app service is this:

```Dockerfile
FROM alpine:edge

RUN apk --no-cache add bash ca-certificates

WORKDIR /usr/local/bin
RUN wget https://raw.githubusercontent.com/vishnubob/wait-for-it/ed77b63706ea721766a62ff22d3a251d8b4a6a30/wait-for-it.sh && \
    chmod +x wait-for-it.sh

CMD ["cat", "/app/test_files/zzz.txt"]
```

wait-for-it requires bash, so bash is added, then the  wait-for-it script is downloaded, and made executable.

### Ignoring files

The docker compose `command` can be used to pass additional options to Unison. A good usage for this
is to ignore files.  For example if you want to ignore all log files and dist files you can use this:

```yaml
...
services:
  sync:
    image: concordconsortium/docker-volume-sync
    command: ["-ignore", "Name *.log", "-ignore", "Path dist"]
    volumes:
      - sync-volume:/data
      - .:/host_data
...
```
More info about the syntax for ignoring files is here:
https://www.cis.upenn.edu/~bcpierce/unison/download/releases/stable/unison-manual.html#ignore

The options passed to Unison are appended to the default Unison options defined in `entrypoint.sh`. Any ignore options added using docker-compose `command` will augment not replace the defaults.

If you want to ignore a folder that is being updated on on your host system, you might be able to optimize performance further by adding an additional volume inside of host_data. This technique is described here:
https://stackoverflow.com/a/37898591
We don't currently have a need for this kind of optimization, so it hasn't been tested.

### Configuration

docker-volume-sync has a few environment variables that you can alter.

`UNISON_DIR` - This is the directory which receives data from unison inside docker-volume-sync. This is the directory you should use in other containers. The default is `/data`

`UNISON_HOST_DIR` - This should be the mounted host volume. docker-volume-sync will sync this directory with `UNISON_DIR`. The default is `/host_data`

`UNISON_GID` - Group ID for the user running unison inside container.

`UNISON_UID` - User ID for the user running unison inside container.

`UNISON_USER` - User name for the sync user ( UID matters more )

`UNISON_GROUP` - Group name for the sync user ( GID matters more )

### Without Waiting

If you can't modify the containers using the synced volume to wait for the port, then you shouldn't add the docker-volume-sync service to your app's docker compose file.  Instead you should run it separately. Then you should manually wait for the first sync to complete before starting any containers using the synced volume.

## Edge cases

docker-volume-sync tries to emulate a simple [docker bind mounted volume](https://docs.docker.com/storage/bind-mounts/). As such it treats the UNISON_HOST_DIR as the main source of the files. If there is a conflict it will use the file in the UNISON_HOST_DIR.  If the container is not running and a file is removed from UNISON_HOST_DIR but not UNISON_DIR, then docker-volume-sync will delete the file in UNISON_DIR when it starts up.

If docker-volume-sync has been removed and you make changes in UNISON_DIR, when docker-volume-sync starts up you will lose those changes. This is roughly what happens with a bind mount. If you unmount the bind mount, then add files to the unmounted directory, those changes will appear lost when the volume is mounted again. The difference is what the directory looks like when it is disconnected. With a bind mount the directory is empty, with docker-volume-sync the directory will continue to have the files in it. (assuming you just remove docker-volume-sync and don't remove the sync-volume). This has not been a problem in practice, if it causes problems for you, please file an issue, there might be a way to improve the behavior.

## Errors

Occasionally you might get an error like this:
> Fatal error: Warning: the archives are locked.
> If no other instance of unison is running, the locks should be removed.
> The file /unison/lk6a655cdeaa391792d60e9febcea4f06a on host 82ad9bbcb013 should be deleted

This error will prevent the sync container from starting. If the sync container can't start
then it is difficult to get into it and delete the lock file. There are a couple of
options:

1. remove the sync container and its anonymous volumes: `docker-compose rm -v sync`  
This command effectively removes the whole /unison folder so the problem should go away.
When you run `docker-compose up` again the sync container will be recreated.
This command does not remove the sync-volume, so it shouldn't take too long to resync.

1. mount the volumes used by the sync container in a new container
and delete the lock file:
    1. run `docker-compose ps` and find the sync container name
    1. run ` docker run --volumes-from [sync_container_name] -it --rm bash`
       this uses a generic bash image.
    1. now you should be able to remove the lock file from `/unison`

It should be possible to detect this error in the sync container and either automatically
handle it or at least leave the container running so the user can use `docker-compose exec`.
Pull requests are welcome. 😊

## Testing

There are no automated tests. But the files in `demo` can be used to run a manual test.

First cd into `demo`

Then run `generate_test_files.sh` this will generate 200 random files in a test_files directory.

Then run `docker-compose up`. Docker compose will build a image for a `sync` service and a image for a `app` service.  After these images are built you should see the `sync` service syncing all of the random files. And you should see the `app` image waiting for the files to be sync'd before printing the contents of the zzz.txt file.

This demo folder also includes an example of how to ignore a log file.

## Credits
This is based off of https://github.com/onnimonni/docker-unison

The idea of bridging two volumes with unison running internally came from [docker-sync](https://github.com/EugenMayer/docker-sync)

## License
This docker image is licensed under GPLv3 because Unison is licensed under GPLv3 and is included in the image. See LICENSE.
