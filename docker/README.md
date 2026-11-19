# Docker – Azure/DevOps Learning Labs

## Lesson 1 – Docker Fundamentals

### What is Docker?

Docker is a containerization platform that packages applications and their dependencies into isolated containers.

Containers share the host Linux kernel, unlike virtual machines that run their own guest operating system and kernel.

### Docker Components

- Docker Engine: Manages containers, images, networks, and volumes.
- Dockerfile: Instructions for building a Docker image.
- Docker Image: An immutable application template.
- Docker Container: An instance created from an image.
- Docker Hub: A public container image registry.

### First Container

Commands:

    docker run hello-world
    docker images
    docker ps
    docker ps -a

The hello-world container prints a message and exits.

Exit code 0 means the process completed successfully.

### Running Nginx

    docker run -d --name nginx-lab -p 8080:80 nginx:alpine

Explanation:

- docker run: Creates and starts a container.
- -d: Detached mode.
- --name: Assigns a container name.
- -p 8080:80: Maps host port 8080 to container port 80.
- nginx:alpine: Nginx image based on Alpine Linux.

Verification:

    docker ps
    curl -I http://localhost:8080

Expected HTTP response: 200 OK.

### Inspecting Containers

    docker exec -it nginx-lab /bin/sh

Inside the container:

    hostname
    cat /etc/os-release
    ps
    ls -l /usr/share/nginx/html/
    cat /usr/share/nginx/html/index.html
    exit

The Nginx master process runs as PID 1.

When the main process exits, the container stops.

Exiting an additional shell started with docker exec does not stop the container.

### Container Lifecycle

    docker logs nginx-lab
    docker stop nginx-lab
    docker ps -a
    docker start nginx-lab
    docker stop nginx-lab
    docker rm nginx-lab

Important:

- docker run creates a new container.
- docker start starts an existing container.
- docker stop stops a running container.
- docker rm removes a container.
- docker rmi removes an image.
- docker logs displays container logs.
- docker exec runs commands inside an active container.

Removing a container does not remove its image.

---

## Lesson 2 – Dockerfile, Custom Images and Versioning

### Project Structure

    docker/
    ├── README.md
    └── dockerfile-lab/
        ├── Dockerfile
        └── index.html

### Dockerfile

Our Dockerfile:

    FROM nginx:alpine

    COPY index.html /usr/share/nginx/html/index.html

    EXPOSE 80

Explanation:

- FROM: Defines the base image.
- COPY: Copies index.html from the build context into the image.
- EXPOSE: Documents the container's listening port (80).
- EXPOSE does not publish the port to the host.
- Dockerfile instructions are used to construct the final image.

### Building a Custom Image

Navigate to the project:

    cd ~/workspace/azure-learning-labs/docker/dockerfile-lab

Build the first version:

    docker build -t devops-nginx:v1 .

Explanation:

- docker build: Builds a Docker image.
- -t: Assigns an image name and tag.
- devops-nginx: Image repository name.
- v1: Image version tag.
- . : Current directory is the build context.

The build context contains files Docker can access during the build.

Building an image does not start a container.

### Running Our Application

    docker run -d --name devops-web -p 8080:80 devops-nginx:v1

Verification:

    docker ps
    curl http://localhost:8080

Expected heading:

    <h1>My First Docker Image</h1>

### Docker Image Layers and Build Cache

Docker builds images using reusable layers.

When a build step and its inputs have not changed,
Docker may reuse a cached result.

This reduces unnecessary build work.

During this lab, Docker used the legacy builder and
displayed a deprecation warning.

BuildKit and Buildx will be covered in a later lesson.

### Creating Version 2

Update the HTML file:

    sed -i 's/My First Docker Image/My Docker Image - Version 2/' index.html

Build version 2:

    docker build -t devops-nginx:v2 .

List the images:

    docker images devops-nginx

Our image IDs:

- devops-nginx:v1: cf7e81db6a64
- devops-nginx:v2: 32bd9bf67c81

The two images contain different versions of the HTML page.

Image tags are mutable references, so production deployments
can use image digests for stronger version guarantees.

### Running Two Versions Simultaneously

Version 1:

    docker run -d --name devops-web -p 8080:80 devops-nginx:v1

Version 2:

    docker run -d --name devops-web-v2 -p 8081:80 devops-nginx:v2

Verification:

    docker ps

    curl -s http://localhost:8080 | grep '<h1>'
    curl -s http://localhost:8081 | grep '<h1>'

Expected results:

Port 8080:

    <h1>My First Docker Image</h1>

Port 8081:

    <h1>My Docker Image - Version 2</h1>

Both containers listen on port 80 internally.

Different host ports allow both containers to run simultaneously.

### Updating the Application

Stop and remove the old container:

    docker stop devops-web
    docker rm devops-web

Create a new container using version 2:

    docker run -d --name devops-web -p 8080:80 devops-nginx:v2

Verification:

    curl -s http://localhost:8080 | grep '<h1>'

Expected:

    <h1>My Docker Image - Version 2</h1>

The existing container was replaced instead of modified.

This demonstrates an immutable deployment approach.

The manual replacement causes a short service interruption.

Production systems can use reverse proxies, load balancers,
or Kubernetes rolling updates to reduce downtime.

### Cleanup

    docker stop devops-web devops-web-v2
    docker rm devops-web devops-web-v2

    docker ps -a
    docker images

Removing containers does not automatically remove their images.

### Key DevOps Lessons

1. Dockerfiles define reproducible image builds.
2. Images are templates used to create containers.
3. A single image can run in multiple containers.
4. Image tags help identify application versions.
5. Building a new image does not update existing containers.
6. Containers can run different application versions simultaneously.
7. Port mapping connects host ports to container ports.
8. Build cache improves build efficiency.
9. Container replacement is a foundation of immutable deployments.
10. Docker images can be published to registries and deployed through CI/CD.

### Connection to Our Azure/DevOps Roadmap

These concepts will later be used with:

- GitHub Actions for automated Docker builds.
- Azure Container Registry (ACR) for image storage.
- Kubernetes for container orchestration.
- Azure Kubernetes Service (AKS) for managed Kubernetes.
- Terraform for provisioning the required Azure infrastructure.

---

## Lesson 3 – Docker Volumes and Persistent Storage

### Why Persistent Storage Matters

Containers have a writable layer that exists for the lifetime
of the container.

Stopping and restarting a container preserves its writable layer.

Removing the container deletes that writable layer.

Applications requiring persistent data should use appropriate
external storage, such as Docker volumes or bind mounts.

### Named Volumes

Create a Docker-managed volume:

    docker volume create devops-data

List and inspect volumes:

    docker volume ls
    docker volume inspect devops-data

In our environment, Docker reported this mountpoint:

    /var/lib/docker/volumes/devops-data/_data

The mountpoint is managed by Docker Engine.

Start a container with the volume:

    docker run -dit --name volume-lab \
      -v devops-data:/data alpine:latest sh

Write data:

    docker exec volume-lab sh -c \
      'echo "Hello from Docker Volume!" > /data/test.txt'

Read data:

    docker exec volume-lab cat /data/test.txt

Remove the container:

    docker stop volume-lab
    docker rm volume-lab

Read the same data from a new container:

    docker run --rm --name volume-lab-new \
      -v devops-data:/data alpine:latest cat /data/test.txt

Result:

    Hello from Docker Volume!

The data survived because it was stored in the named volume,
not in the removed container's writable layer.

The --rm option automatically removes the temporary container
when its main process exits. It does not remove the named volume.

### Bind Mounts

A bind mount maps a specific host directory into a container.

Create a directory and file on the WSL2 host:

    mkdir -p ~/workspace/docker-bind-lab

    echo "Hello from WSL2 Host!" \
      > ~/workspace/docker-bind-lab/message.txt

Read the host file from a container:

    docker run --rm --name bind-lab \
      -v ~/workspace/docker-bind-lab:/data \
      alpine:latest cat /data/message.txt

Modify the host file from a container:

    docker run --rm --name bind-lab \
      -v ~/workspace/docker-bind-lab:/data \
      alpine:latest \
      sh -c 'echo "Modified from Docker Container!" > /data/message.txt'

Verify on the host:

    cat ~/workspace/docker-bind-lab/message.txt

Result:

    Modified from Docker Container!

The host and container accessed the same underlying file.

### Named Volume vs Bind Mount

Named volume:

    -v devops-data:/data

Bind mount:

    -v /home/tomislav/workspace/docker-bind-lab:/data

Both provide access to data outside the container's writable layer.

The main difference is storage management:

- Named volume: Docker manages the storage location.
- Bind mount: The user specifies the host directory.
- Named volumes are commonly used for database persistence.
- Bind mounts are commonly used for local development.

### Container Writable Layer

Start a container without a volume:

    docker run -dit --name no-volume-lab alpine:latest sh

Create a file:

    docker exec no-volume-lab sh -c \
      'echo "Important application data!" > /test.txt'

Stop and restart the container:

    docker stop no-volume-lab
    docker start no-volume-lab

Verify the file still exists:

    docker exec no-volume-lab cat /test.txt

Result:

    Important application data!

Remove the container:

    docker stop no-volume-lab
    docker rm no-volume-lab

Start a new container:

    docker run --rm --name no-volume-lab-new \
      alpine:latest sh -c 'ls -l /test.txt'

Result:

    ls: /test.txt: No such file or directory

The new container does not contain the deleted container's data.

### Important Storage Principles

1. docker stop does not delete container data.
2. docker start reuses an existing container.
3. docker rm deletes the container's writable layer.
4. Named volumes survive normal container removal.
5. Bind mounts use directories on the Docker host.
6. Multiple containers can reuse the same named volume.
7. Docker volumes are not automatically backed up.
8. Deleting a volume can permanently delete its data.
9. Persistent storage is essential for stateful applications.
10. Kubernetes provides PersistentVolumes and
    PersistentVolumeClaims for persistent storage management.

### Connection to Azure and Kubernetes

These concepts prepare us for:

- PostgreSQL and other stateful containerized applications.
- Kubernetes PersistentVolumes (PV).
- Kubernetes PersistentVolumeClaims (PVC).
- Azure Disk and Azure Files storage.
- Stateful workloads in Azure Kubernetes Service (AKS).

---

## Lesson 4 – Docker Networking

### Why Docker Networking Matters

Docker networking allows containers to communicate with each
other, with the Docker host, and with external services.

A typical application may contain multiple components:

- Frontend: receives requests from users.
- Backend: processes application requests.
- Database: stores application data.

Docker networks allow us to control which containers share
network connectivity.

### Docker Network Drivers

Docker supports several networking drivers.

- bridge: commonly used for containers on one Docker host.
- host: shares the Docker host's network namespace on Linux.
- none: disables normal network connectivity.
- overlay: supports networking across multiple Docker hosts,
  commonly in Docker Swarm environments.

In this lesson, we used user-defined bridge networks.

### Lab 1 – Create and Inspect a Docker Network

List existing networks:

    docker network ls

Create a user-defined bridge network:

    docker network create devops-network

Inspect its configuration:

    docker network inspect devops-network

Our Docker network received:

    Network: 172.18.0.0/16
    Gateway: 172.18.0.1
    Driver: bridge

Docker automatically allocated this subnet.

The network initially contained no containers.

### Lab 2 – Container-to-Container Communication

Start two Alpine containers on the same network:

    docker run -dit --name container-a \
      --network devops-network alpine:latest sh

    docker run -dit --name container-b \
      --network devops-network alpine:latest sh

List running containers:

    docker ps

Inspect their IP addresses:

    docker inspect -f \
      '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' \
      container-a

    docker inspect -f \
      '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' \
      container-b

Observed IP addresses:

    container-a: 172.18.0.2
    container-b: 172.18.0.3

Test communication:

    docker exec container-a ping -c 4 container-b

    docker exec container-b ping -c 4 container-a

Both tests succeeded with 0% packet loss.

### Docker DNS

User-defined Docker bridge networks provide automatic
container-name resolution through Docker's embedded DNS.

For example:

    docker exec container-a ping -c 4 container-b

Docker resolves the name container-b to its IP address.

Applications should generally use stable service names
rather than hardcoded container IP addresses.

Container IP addresses may change when containers are recreated.

### Lab 3 – Network Separation

Create a second network:

    docker network create isolated-network

Start another container:

    docker run -dit --name container-c \
      --network isolated-network alpine:latest sh

Attempt to resolve container-c from container-a:

    docker exec container-a ping -c 3 container-c

Observed result:

    ping: bad address 'container-c'

The containers did not share a user-defined network,
so container-a could not resolve container-c by name.

Connect container-c to devops-network:

    docker network connect devops-network container-c

Repeat the test:

    docker exec container-a ping -c 3 container-c

The test succeeded with 0% packet loss.

Container-c was reachable at 172.18.0.4.

### Lab 4 – Multiple Networks per Container

Inspect container-c:

    docker inspect -f \
      '{{json .NetworkSettings.Networks}}' container-c

Display network names and IP addresses:

    docker inspect -f \
      '{{range $name, $network := .NetworkSettings.Networks}}{{printf "%s -> %s\n" $name $network.IPAddress}}{{end}}' \
      container-c

Observed results:

    devops-network -> 172.18.0.4
    isolated-network -> 172.19.0.2

List containers connected to each network:

    docker network inspect -f \
      '{{range .Containers}}{{println .Name .IPv4Address}}{{end}}' \
      devops-network

    docker network inspect -f \
      '{{range .Containers}}{{println .Name .IPv4Address}}{{end}}' \
      isolated-network

A container can have multiple network interfaces and IP
addresses when connected to multiple Docker networks.

Connecting a container to two networks does not automatically
make it a router between those networks.


### Lab 5 – Frontend, Backend and Database Networking

We simulated a three-tier architecture using Alpine containers.

Network design:

    frontend-network:
      frontend
      backend

    backend-network:
      backend
      database

The backend container was connected to both networks.

Create networks:

    docker network create frontend-network
    docker network create backend-network

Start frontend:

    docker run -dit --name frontend \
      --network frontend-network alpine:latest sh

Start backend:

    docker run -dit --name backend \
      --network frontend-network alpine:latest sh

Connect backend to the second network:

    docker network connect backend-network backend

Start database:

    docker run -dit --name database \
      --network backend-network alpine:latest sh

Test frontend-to-backend communication:

    docker exec frontend ping -c 3 backend

Result:

    3 packets transmitted, 3 received, 0% packet loss

Test backend-to-database communication:

    docker exec backend ping -c 3 database

Result:

    3 packets transmitted, 3 received, 0% packet loss

Test frontend-to-database name resolution:

    docker exec frontend ping -c 3 database

Result:

    ping: bad address 'database'

Frontend and database did not share a Docker network.

This demonstrated Docker DNS visibility and network segmentation.

Important: DNS resolution failure alone is not a complete
network security test. Application connectivity should also
be tested using the relevant TCP ports.

### Docker Networking Cleanup

Remove lab containers:

    docker rm -f \
      container-a \
      container-b \
      container-c \
      frontend \
      backend \
      database

Remove lab networks:

    docker network rm \
      devops-network \
      isolated-network \
      frontend-network \
      backend-network

Verify cleanup:

    docker ps -a
    docker network ls
    docker volume ls

After cleanup, only the standard Docker networks remained:

    bridge
    host
    none

The named volumes devops-data and minikube were preserved.

### Important Docker Networking Principles

1. Docker containers can communicate over shared networks.
2. User-defined bridge networks provide embedded DNS.
3. Container names can resolve to IP addresses on shared networks.
4. Container IP addresses are not guaranteed to remain unchanged.
5. One container can connect to multiple Docker networks.
6. Each network connection can have its own IP address.
7. Network separation helps reduce unnecessary connectivity.
8. DNS failure does not by itself prove complete isolation.
9. Published ports are different from internal container networking.
10. Network configuration should follow least-privilege principles.

### Connection to Azure and Kubernetes

Docker networking provides useful foundations for understanding:

- Azure Virtual Networks and subnets.
- Network segmentation.
- Kubernetes Pods and Services.
- Kubernetes DNS-based service discovery.
- Kubernetes NetworkPolicies.
- Azure Kubernetes Service networking.

Docker bridge networking and Azure Virtual Networks are
different technologies, but they share important networking
concepts.

### Lesson 4 – Final Outcome

Successfully completed:

- Creating and inspecting Docker bridge networks.
- Assigning containers to specific networks.
- Inspecting container IP addresses.
- Testing communication using Docker DNS.
- Connecting running containers to additional networks.
- Simulating frontend, backend and database segmentation.
- Removing lab containers and networks safely.

Next lesson: Docker Compose.

---

# Lesson 5 – Docker Compose

## 1. Goal

Learn how to define, run, manage, and troubleshoot multi-container applications using Docker Compose.

Topics covered:
- Docker Compose V2 installation
- YAML configuration and services
- Container lifecycle management
- Default networks and Docker DNS
- Named volumes and persistent storage
- Data preservation and deletion
- Container startup versus application readiness

## 2. Docker Compose Installation

Environment:
- Ubuntu 22.04 LTS on WSL2
- Docker Engine 29.1.3
- Docker Compose V2 2.40.3
- Docker Buildx 0.30.1

Install the plugins from Ubuntu repositories:

```bash
sudo apt install -y docker-compose-v2 docker-buildx
```

Verify the installation:

```bash
docker compose version
docker buildx version
docker --version
docker info --format '{{.ServerVersion}}'
docker ps
```

Docker Compose defines and manages containerized applications through a YAML configuration file.

Instead of manually creating each container, network, and volume, we declare the desired application configuration and let Compose manage the resources.

Docker Buildx provides extended image-building functionality through BuildKit.

## 3. First Compose Project

Create the project directory:

```bash
cd ~/workspace/azure-learning-labs
mkdir -p docker/compose-lab
cd docker/compose-lab
```

Initial `compose.yaml`:

```yaml
services:
  web:
    image: nginx:alpine
    ports:
      - "8080:80"
```

Explanation:

- `services`: defines the application's services.
- `web`: logical service name.
- `image`: Docker image used to create the container.
- `ports`: publishes a container port on the host.
- `8080:80`: host port 8080 maps to container port 80.

Validate the configuration:

```bash
docker compose config
```

This command parses and normalizes the Compose configuration.

It may display additional settings such as the default network and expanded port mappings.

It does not start containers or create Docker resources.

Start the application:

```bash
docker compose up -d
```

The `up` command creates and starts the services. The `-d` option runs them in detached mode.

Verify:

```bash
docker compose ps
curl -I http://localhost:8080
docker network ls
```

Observed results:

- Container `compose-lab-web-1` started.
- Nginx returned HTTP 200 OK.
- Network `compose-lab_default` was created automatically.

Compose generally uses the project name as a prefix when naming its resources.

## 4. Compose Application Lifecycle

Stop the application:

```bash
docker compose stop
docker compose ps -a
docker network ls
```

`stop` stops the containers but preserves them and their network.

Restart existing containers:

```bash
docker compose start
docker compose ps
```

`start` starts existing containers without recreating them.

Remove the application:

```bash
docker compose down
docker compose ps -a
docker network ls
```

`down` removes the project's containers and default networks.

It does not remove named volumes by default.

| Command | Behavior |
|---|---|
| `docker compose up -d` | Creates or updates and starts services |
| `docker compose stop` | Stops existing containers |
| `docker compose start` | Starts existing containers |
| `docker compose ps` | Lists project containers |
| `docker compose down` | Removes project containers and networks |
| `docker compose down -v` | Also removes declared named volumes and anonymous volumes |

## 5. Multiple Services and Docker DNS

Extend `compose.yaml`:

```yaml
services:
  web:
    image: nginx:alpine
    ports:
      - "8080:80"

  client:
    image: alpine:latest
    command: sleep infinity
```

The `client` service uses Alpine Linux.

`sleep infinity` keeps the container running so we can execute commands inside it.

Validate and start:

```bash
docker compose config
docker compose up -d
docker compose ps
```

Test communication between services:

```bash
docker compose exec client wget -qO- http://web
```

Explanation:

1. `docker compose exec client` executes a command inside the running Alpine container.
2. `wget` sends an HTTP request to `http://web`.
3. Docker DNS resolves the service name `web` to the Nginx container's IP address.
4. Nginx returns its HTML page.

The service name is used instead of a hardcoded IP address.

Communication between the containers uses Nginx's internal port 80. The published host port 8080 is not needed for this connection.

Inspect the network:

```bash
docker network inspect compose-lab_default
```

Observed addresses:

- `compose-lab-client-1`: `172.18.0.2`
- `compose-lab-web-1`: `172.18.0.3`

These IP addresses are dynamically assigned and can change after recreation.

Both containers were connected to the automatically created `compose-lab_default` bridge network.

## 6. Persistent Storage with Named Volumes

Final `compose.yaml`:

```yaml
services:
  web:
    image: nginx:alpine
    ports:
      - "8080:80"
    volumes:
      - web-data:/usr/share/nginx/html

  client:
    image: alpine:latest
    command: sleep infinity

volumes:
  web-data:
```

There are two different uses of `volumes`:

1. The service-level `volumes` section mounts storage into the container.
2. The top-level `volumes` section declares the named volume managed by Compose.

The mapping:

```yaml
- web-data:/usr/share/nginx/html
```

means:

- `web-data`: logical Docker volume name.
- `/usr/share/nginx/html`: directory inside the Nginx container.

Compose creates a Docker volume named `compose-lab_web-data`.

This is Docker-managed storage, not a directory inside the Git repository.

Validate and start:

```bash
docker compose config
docker compose up -d
docker compose ps
docker volume ls
```

The lab confirmed that Compose created the volume and attached it to the Nginx container.

## 7. Writing Data to the Volume

Write a custom HTML page:

```bash
docker compose exec web sh -c \
  'echo "<h1>Docker Compose Persistent Storage Works!</h1>" > /usr/share/nginx/html/index.html'
```

Explanation:

- `docker compose exec web`: executes a command in the running Nginx container.
- `sh -c`: executes the quoted command through a shell.
- `echo`: produces the HTML content.
- `>`: writes the content to the file, replacing its previous contents.
- `/usr/share/nginx/html/index.html`: file inside the mounted volume.

Verify:

```bash
curl http://localhost:8080
```

Observed response:

```html
<h1>Docker Compose Persistent Storage Works!</h1>
```

Although the file is accessed through the container filesystem, the data is stored in the Docker named volume.

## 8. Persistence After Container Removal

Remove the Compose application:

```bash
docker compose down
```

Check the volumes:

```bash
docker volume ls
```

The lab confirmed that `compose-lab_web-data` remained available.

Recreate the application:

```bash
docker compose up -d
```

Verify the HTML content:

```bash
curl http://localhost:8080
```

The custom HTML content remained available because the new container mounted the existing volume.

This demonstrates that named volume data is independent of the container lifecycle.

During the lab, the first HTTP request immediately after recreation returned:

```text
curl: (56) Recv failure: Connection reset by peer
```

A later request succeeded, and the Nginx logs showed:

```text
"GET / HTTP/1.1" 200 50
```

This is consistent with the application not yet being ready when the first request was sent, although the output alone does not prove the exact cause.

A running container does not necessarily mean its application is ready to serve requests.

In production, application readiness can be monitored using health checks.

## 9. Removing Persistent Data

Remove containers, networks, and volumes:

```bash
docker compose down -v
docker volume ls
```

The lab confirmed that `compose-lab_web-data` was removed.

Existing unrelated volumes, including `devops-data` and `minikube`, remained available.

Recreate the application:

```bash
docker compose up -d
```

Verify:

```bash
curl http://localhost:8080
```

The original Nginx welcome page appeared:

```html
<h1>Welcome to nginx!</h1>
```

The custom HTML content was no longer available because its volume had been deleted.

When a new empty named volume is mounted over a non-empty directory in the image, Docker normally copies the directory's initial contents into that volume.

Important distinction:

- `docker compose down` preserves named volumes.
- `docker compose down -v` removes declared named volumes and anonymous volumes attached to the project's containers.

Be careful with `down -v`, especially when working with databases and other stateful applications.

## 10. Final Cleanup

Clean up the Compose lab:

```bash
docker compose down -v
docker compose ps -a
docker volume ls
```

Verified results:

- Both Compose containers removed.
- Compose network removed.
- Compose named volume removed.
- Existing `devops-data` and `minikube` volumes preserved.
- `compose.yaml` retained for version control.

## 11. Key Takeaways

Docker Compose provides a declarative way to manage containerized applications.

Important concepts:

- Application services are defined in `compose.yaml`.
- Compose creates and manages containers and networks.
- Services can communicate using Docker DNS and service names.
- Published host ports are separate from internal container ports.
- Named volumes preserve data independently of containers.
- `down` and `down -v` have different effects on persistent data.
- Container startup and application readiness are different concepts.
- Compose configurations can be version-controlled in Git.
