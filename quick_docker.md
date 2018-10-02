Test Procedure
==============
- execution with hostname and init process and volume in the host for persistence:
`docker run -v /vagrant/sandbox:/volume --name arcserver --hostname arcserver --init app_minarc:latest`

- execution with hostname and init process and volume in the host for persistence:
`docker run -v volume_minarc:/volume --name arcserver --hostname arcserver --init app_minarc:latest`

- To obtain a console of a container already in running state:
`docker container exec -i -t arcserver /bin/bash`

- To get the volume mounted by the container:
`sudo docker inspect -f "{{json .Mounts}}" arcserver | jq .`

IMAGE(s) Management
===================
This section contains the cheat-list of commands to handle docker _images_.

- Create the image(s) driven by a given docker definition file:
`docker image build -t app_minarc:latest . -f Dockerfile.minarc`

- Remove all the images including unused ones:

`docker image rm -f $(sudo docker image ls -qa)`

`docker image pull ubuntu:latest`

`docker image build -t app_minarc:latest .`





`docker image prune -a --force`

`docker image prune --filter "dangling=true"`

`docker image prune --filter="label!=maintainer"`\`

CONTAINER Management
====================
This section contains the cheat-list of commands to handle docker _containers_.

`docker container run -d --name minarc
--network localnet_minarc app_minarc:latest`

- Run a container with a bash/console
`docker container run --name minarc -it app_minarc:latest /bin/bash`

`docker container run --name minarc -it app_minarc:latest`

To obtain a console / bash from a container already in running state.
`docker container exec -i -t <container_id> /bin/bash`

docker container run -it ubuntu:latest /bin/bash



docker container run --hostname minarcserver --name minarc -it app_minarc:latest /bin/bash



docker run -dit --name minarc --mount source=volume_minarcroot,destination=/volume/minarc_root app_minarc:latest

Execution
---------

- To execute a container loading an init process to rightly handle POSIX signals spawing children from PID=1:
`docker run --name <my_container_name> --hostname <hostname> --init <image_id>`

- To execute a container mounting a directory from the host into the container:
`docker run -v /Users/borja/Projects/dec/install/:/vagrant --name <my_container_name> --hostname <hostname> --init <image_id>`
  
- To stop execution of a given container:
`docker container stop <container_id / tag>`

- Start execution of a given container:
`docker container start <container_id / tag>`

- To remove a given container:
`docker container rm <container_id / tag>`

sudo docker rm $(sudo docker ps -a -q)

================================================

NETWORK
=======

- Create single-host bridge networks which are only visible in the host.

`docker network create -d bridge localnet_minarc`

`docker network ls`

`docker network inspect <name>`

- Get the IP address of a container
`docker inspect <containerNameOrId> | grep '"IPAddress"' | head -n 1`

- See container port forwarding from hostname 
`docker port <container_name>`


- Usual Linux networking tools can be used.

`ip link show docker0`

- List the Linux bridges currently defined in the system:

`brctl show`

- List of process listening to a given port number:
`lsof -i :8081`


Docker COMPOSE Install
======================



- Install docker-compose tool available in _https://github.com/docker/compose/releases_ :

		sudo curl -L https://github.com/docker/compose/releases/download/1.22.0/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose

- Update execution flags:
`chmod a+x /usr/local/bin/docker-compose`

#### Start service with compose
`docker-compose -f docker-compose.minarc.yml up -d`

#### Stop service with compose
`docker-compose -f docker-compose.minarc.yml down`

#### Container Process Status with compose
`docker-compose -f docker-compose.minarc.yml ps`

#### Container Top processes with compose
`docker-compose -f docker-compose.minarc.yml top`

VOLUME Images
=============
- Creation of a volume:
`docker volume create volume_minarcroot`

- Creation of the volume pointing to a directory in the host:
`docker volume create -d local -o type=none -o o=bind -o device=/vagrant/sandbox volume_minarc`







cf. host directory /var/lib/docker/volumes/volume_minarcroot


docker volume ls

docker volume inspect <name>

cf. host computer /var/lib/docker/<storage driver>
==================================================

docker run --volumes-from some-volume docker-image-name:tag

docker run -dit --name minarc --mount source=volume_minarcroot,destination=/volume/minarc_root app_minarc:latest

docker run -d --name minarc --mount source=volume_minarcroot,destination=/volume/minarc_root app_minarc:latest

docker run -d \\ --name devtest \\ --mount source=volume_minarcroot,target=/volume \\ minarc:latest


