### Shortcuts

`sudo docker container run -dit --name minarc --hostname minarc -v /home/vagrant/Volumes:/home/vagrant/Volumes/minarc_homevideo/ --init --publish 4567:4567 app_minarc:latest /bin/bash`

`sudo docker container run -dit --name minarc --hostname minarc --mount source=volume_minarc_homevideo,target=/home/vagrant/Volumes/minarc_homevideo --init --publish 4567:4567 app_minarc:latest /bin/bash`

### Docker for mac tips

-	Get a console to the host environment:  
	`screen ~/Library/Containers/com.docker.docker/Data/com.docker.driver.amd64-linux/tty`

-	Kill the console:  
	`screen -X quit`

---

Image(s) Management
===================

This section contains the cheat-list of commands to handle docker *images*.

-	Create the image(s) driven by a given docker definition file:  
	`docker image build -t app_minarc:latest . -f Dockerfile.minarc`

-	Remove all the images including unused ones:  
	`docker image rm -f $(sudo docker image ls -qa)`

-	Force removal of all images:  
	`docker image prune -a --force`

-	Save a Container into an Image:  
	`sudo docker commit --author "bolf" dec app_dec:latest`

-	Save an Image into a tar file:  
	`docker save --output app_dec.latest.tar app_dec:latest`

-	Load an Image from a tar file:  
	`docker load --input <tarfile>`

`docker image prune --filter "dangling=true"`

`docker image prune --filter="label!=maintainer"`\`

---

### CONTAINER Management

This section contains the cheat-list of commands to handle docker *containers*.  
- Run a container by executing an interactive bash (no ENTRYPOINT should have been defined)  
`sudo docker container run --name dec -i -t app_dec /bin/bash`

-	Run a container with an ENTRYPOINT to execute one command with argument(s):  
	`sudo docker container run --name dec  app_dec decUnitTests batchmode`

-	Run a container liaised to a given network:  
	`docker container run -d --name minarc
	--network localnet_minarc app_minarc:latest`

-	Run a container:  
	`docker container run --name minarc -it app_minarc:latest`

-	Run a container with a bash/console:  
	`docker container run --name minarc -it app_minarc:latest /bin/bash`

-	Run a container with defined environment variables:  
	`sudo docker container run --name orchestrator -it --env-file ./orc_test.env  app_orc:latest /bin/bash`

-	To obtain a console / bash from a container already in running state:  
	`docker container exec -i -t <container_id> /bin/bash`

-	To obtain a root console / bash from a container already in running state:`sudo docker container exec --user='root' -i -t dec /bin/bash`

-	To delete all Containers exited:  
	`docker rm $(docker ps --all -q -f status=exited)`

-	Save a Container into an Image  
	`docker container commit --author "BOLF" dec app_dec:latest`

---

### Execution

=========

-	To execute a container loading an init process to rightly handle POSIX signals spawing children from PID=1:`docker run --name <my_container_name> --hostname <hostname> --init <image_id>`

-	To execute a container mounting a directory from the host into the container:`docker run -v /Users/borja/Projects/dec/install/:/vagrant --name <my_container_name> --hostname <hostname> --init <image_id>`

-	To stop execution of a given container:  
	`docker container stop <container_id / tag>`

-	Start execution of a given container:  
	`docker container start <container_id / tag>`

-	To remove a given container:  
	`docker container rm <container_id / tag>`

-	To remove *all* containers:  
	`sudo docker rm $(sudo docker ps -a -q)`

---

### Networking

-	Specify the hostname variable at container execution time:  
	`--hostname`

-	Create single-host bridge networks which are only visible in the host:  
	`docker network create -d bridge localnet_minarc`

-	List available networks:  
	`docker network ls`

-	List network properties:  
	`docker network inspect <name>`

-	Get the IP address of a container:  
	`docker inspect <containerNameOrId> | grep '"IPAddress"' | head -n 1`

-	See container port forwarding from hostname:  
	`docker port <container_name>`

-	Usual Linux networking tools can be used:  
	`ip link show docker0`

-	List the Linux bridges currently defined in the system:  
	`brctl show`

-	List of process listening to a given port number:  
	`lsof -i :8081`

-	Port forwarding in mac os:  
	`pfctl -evf /etc/pf.anchors/forwarding.minarc`

---

Docker COMPOSE Install
======================

-	Install docker-compose tool available in *https://github.com/docker/compose/releases* :

	```
	sudo curl -L https://github.com/docker/compose/releases/download/1.22.0/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose
	```

-	Update execution flags:`chmod a+x /usr/local/bin/docker-compose`

#### Start service with compose

`docker-compose -f docker-compose.minarc.yml up -d`

#### Stop service with compose

`docker-compose -f docker-compose.minarc.yml down`

#### Container Process Status with compose

`docker-compose -f docker-compose.minarc.yml ps`

#### Container Top processes with compose

`docker-compose -f docker-compose.minarc.yml top`

---

VOLUME Images
=============

Docker volumes are created in the *host* directory /var/lib/docker/volumes/<volume_name>

-	Creation of a volume:  
	`docker volume create volume_minarcroot`

-	Creation of the volume pointing to a directory in the host:  
	`docker volume create -d local -o type=none -o o=bind -o device=/vagrant/sandbox volume_minarc`

-	List of volumes:  
	`docker volume ls`

-	Inspect the volume properties:  
	`docker volume inspect <name>`\`

-	Execute a container mounting a given named volume (with all goodies):  
	`docker container run -P -dit --name minarc --hostname minarc --mount source=volume_minarc_homevideo,target=/home/vagrant/Volumes/minarc_homevideo --init  app_minarc:latest`

---

---

Tools & Tips
============

`docker cp orc-0.0.6dev1_boa_app_s2boa@e2espm-inputhub.gem boa_app_s2boa:/tmp`


Test Procedure
==============

-	Creation of the volume pointing to a directory in the host:`docker volume create -d local -o type=none -o o=bind -o device=/vagrant/sandbox volume_minarc`

-	execution with hostname and init process and volume in the host for persistence:`docker run -v /vagrant/sandbox:/volume --name arcserver --hostname arcserver --init app_minarc:latest`

-	execution with hostname and init process and volume in the host for persistence:`docker run -v volume_minarc:/volume --name arcserver --hostname arcserver --init app_minarc:latest`

-	To obtain a console of a container already in running state:`docker container exec -i -t arcserver /bin/bash`

-	To get the volume mounted by the container:`sudo docker inspect -f "{{json .Mounts}}" arcserver | jq .`

---

cf. host computer /var/lib/docker/<storage driver>
==================================================

docker run --volumes-from some-volume docker-image-name:tag

docker run -dit --name minarc --mount source=volume_minarcroot,destination=/volume/minarc_root app_minarc:latest

docker run -d --name minarc --mount source=volume_minarcroot,destination=/volume/minarc_root app_minarc:latest

docker run -d \\ --name devtest \\ --mount source=volume_minarcroot,target=/volume \\ minarc:latest

References
==========

[how to start services in containers](https://stackoverflow.com/questions/25135897/how-to-automatically-start-a-service-when-running-a-docker-container)
