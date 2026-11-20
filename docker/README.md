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

---

# Lesson 6 – Docker Registry & Image Publishing

## 1. Goal

Learn how to publish a custom Docker image to a container registry and retrieve it for deployment.

Topics covered:

- Docker registries and repositories
- Docker image naming conventions
- Image tags and versioning
- Docker Hub authentication
- Publishing images with `docker push`
- Reusing Docker image layers
- Registry digests versus local Image IDs
- Retrieving images with `docker pull`
- Running an image retrieved from a registry
- Container cleanup and image persistence

## 2. What Is a Docker Registry?

A Docker registry is a service that stores and distributes container images.

Examples include:

- Docker Hub
- Azure Container Registry (ACR)
- GitHub Container Registry (GHCR)
- Amazon Elastic Container Registry (ECR)

Docker Hub is the default registry used by Docker when no registry hostname is specified.

A registry allows developers and CI/CD systems to share container images without rebuilding them on every deployment server.

Typical workflow:

```text
Developer workstation
        |
        | docker build
        v
Local Docker image
        |
        | docker tag
        v
Registry-compatible image name
        |
        | docker push
        v
Docker Hub
        |
        | docker pull
        v
Deployment server
        |
        | docker run
        v
Running application
```

In production, this workflow can be automated through GitHub Actions, Azure DevOps Pipelines, or other CI/CD tools.

## 3. Existing Docker Image

We reused the custom Nginx image created in Lesson 2.

Verify local images:

```bash
docker image ls
```

Relevant images:

```text
devops-nginx:v1
devops-nginx:v2
nginx:alpine
```

The Dockerfile from Lesson 2:

```dockerfile
FROM nginx:alpine

COPY index.html /usr/share/nginx/html/index.html

EXPOSE 80
```

Explanation:

- `FROM nginx:alpine` selects the base image.
- `COPY` adds our custom HTML page to the image.
- `EXPOSE 80` documents the container's listening port.

The `EXPOSE` instruction does not automatically publish a port on the host.

The existing image was:

```text
devops-nginx:v2
Image ID: 32bd9bf67c81
```

We reused this image instead of rebuilding it.

## 4. Understanding Docker Image Names

A Docker image reference commonly uses this format:

```text
[registry-host/]namespace/repository:tag
```

For our Docker Hub repository:

```text
tomislav1989/devops-nginx:v2
```

Components:

| Component | Value | Purpose |
|---|---|---|
| Registry | docker.io | Docker Hub |
| Namespace | tomislav1989 | Docker Hub account |
| Repository | devops-nginx | Image repository |
| Tag | v2 | Image version reference |

The fully qualified reference is:

```text
docker.io/tomislav1989/devops-nginx:v2
```

If a tag is omitted, Docker normally uses `latest`.

For example:

```bash
docker pull tomislav1989/devops-nginx
```

is interpreted as:

```bash
docker pull tomislav1989/devops-nginx:latest
```

However, `latest` does not automatically mean the newest application version.

It is simply a tag that can be assigned to an image.

For predictable deployments, explicit version tags or immutable digests are preferable.

## 5. Docker Image Tagging

We first created a temporary local tag:

```bash
docker tag devops-nginx:v2 registry-lab/devops-nginx:v2
```

Verify:

```bash
docker image ls
```

Both references had the same Image ID:

```text
devops-nginx:v2                 32bd9bf67c81
registry-lab/devops-nginx:v2    32bd9bf67c81
```

We verified the full Image IDs:

```bash
docker image inspect devops-nginx:v2 --format '{{.Id}}'

docker image inspect registry-lab/devops-nginx:v2 --format '{{.Id}}'
```

Both commands returned:

```text
sha256:32bd9bf67c81df589ab77eed0bfed46a34099f6ec4e27c8a98c15d3ab7a166fe
```

This proves that the two names refer to the same image.

Important:

`docker tag` does not rebuild the image or duplicate all of its layers.

It creates another reference to the existing image.

A separate `docker tag` command is unnecessary if the image was already built with the desired registry-compatible name.

For example:

```bash
docker build -t tomislav1989/devops-nginx:v2 ./docker/dockerfile-lab
```

would build the image with the correct name directly.

In our lab, we reused the existing image instead.

## 6. Docker Hub Repository

We created a separate Docker Hub repository for the learning project.

Repository:

```text
tomislav1989/devops-nginx
```

Docker Hub URL:

https://hub.docker.com/r/tomislav1989/devops-nginx

The repository is separate from other application repositories.

This helps keep learning projects organized and makes the published image easier to identify.

## 7. Authentication to Docker Hub

Authenticate using:

```bash
docker login --username tomislav1989
```

Observed result:

```text
Login Succeeded
```

Docker Hub supports Personal Access Tokens (PATs) for CLI authentication.

Do not put passwords or tokens into README files, Git repositories, or shell scripts committed to Git.

During the lab, Docker displayed this warning:

```text
WARNING! Your credentials are stored unencrypted in '/home/tomislav/.docker/config.json'.
```

This indicates that a credential helper was not configured.

A credential helper is recommended for safer local credential storage.

The Docker configuration file containing authentication data must not be committed to Git.

## 8. Tagging for Docker Hub

We added the Docker Hub repository name to the existing image:

```bash
docker tag devops-nginx:v2 tomislav1989/devops-nginx:v2
```

Verify:

```bash
docker image ls tomislav1989/devops-nginx
```

Observed Image ID:

```text
32bd9bf67c81
```

The image contents did not change.

Only an additional image reference was created.

## 9. Publishing with Docker Push

Publish the image:

```bash
docker push tomislav1989/devops-nginx:v2
```

Observed output included:

```text
The push refers to repository [docker.io/tomislav1989/devops-nginx]

0a8a679fd835: Pushed
a0d10c4778f6: Mounted from library/nginx
7c65737affdd: Mounted from library/nginx
75f1d9657d88: Mounted from library/alpine
```

The final output was:

```text
v2: digest: sha256:36a0f49e5d41aeecf599a153d0e57293d1501c655eda93514c5fe842ec21897c size: 2196
```

Explanation:

- `Pushed`: a layer was uploaded to Docker Hub.
- `Mounted from library/nginx`: Docker Hub reused an existing compatible layer.
- `Mounted from library/alpine`: another existing layer was reused.
- `digest`: identifies the published image manifest.

Docker images are composed of layers.

Layers are content-addressed, allowing registries to reuse identical data instead of uploading it repeatedly.

Our image was based on `nginx:alpine`, so many of its layers were already available in Docker Hub.

The custom application layer needed to be uploaded.

This layer-reuse mechanism reduces unnecessary network transfer and storage duplication.

## 10. Local Image ID Versus Registry Digest

Local Image ID:

```text
sha256:32bd9bf67c81df589ab77eed0bfed46a34099f6ec4e27c8a98c15d3ab7a166fe
```

Registry digest:

```text
sha256:36a0f49e5d41aeecf599a153d0e57293d1501c655eda93514c5fe842ec21897c
```

These values are different because they identify different objects.

The local Image ID identifies the image configuration.

The registry digest identifies the published manifest, or an image index in some multi-platform scenarios.

A tag such as `v2` is a human-readable reference and can potentially be reassigned.

A digest identifies specific registry content.

For deployments that must use exactly the same published image, a digest reference can be used:

```text
tomislav1989/devops-nginx@sha256:36a0f49e5d41aeecf599a153d0e57293d1501c655eda93514c5fe842ec21897c
```

This is especially useful in production CI/CD pipelines.

## 11. Removing a Local Image Tag

To simulate retrieving the image from a registry, we removed its Docker Hub tag locally:

```bash
docker image rm tomislav1989/devops-nginx:v2
```

Observed output:

```text
Untagged: tomislav1989/devops-nginx:v2
Untagged: tomislav1989/devops-nginx@sha256:36a0f49e5d41aeecf599a153d0e57293d1501c655eda93514c5fe842ec21897c
```

The underlying image remained available through other tags:

```text
devops-nginx:v2
registry-lab/devops-nginx:v2
```

Both references pointed to Image ID:

```text
32bd9bf67c81
```

Removing a local tag does not delete the published image from Docker Hub.

It also does not necessarily remove image layers if other local references still use them.

## 12. Retrieving the Image with Docker Pull

Download the published image:

```bash
docker pull tomislav1989/devops-nginx:v2
```

Observed output:

```text
v2: Pulling from tomislav1989/devops-nginx

Digest: sha256:36a0f49e5d41aeecf599a153d0e57293d1501c655eda93514c5fe842ec21897c

Status: Downloaded newer image for tomislav1989/devops-nginx:v2
```

Verify:

```bash
docker image ls tomislav1989/devops-nginx

docker image inspect tomislav1989/devops-nginx:v2 --format '{{.Id}}'
```

Observed Image ID:

```text
sha256:32bd9bf67c81df589ab77eed0bfed46a34099f6ec4e27c8a98c15d3ab7a166fe
```

The Image ID matched the original local image.

This confirms that the published image could be retrieved through Docker Hub.

Because the same image layers were still available locally, Docker did not necessarily need to download every layer again.

A separate machine with no cached layers would provide a more independent download test.

## 13. Running the Published Image

Start a container using the Docker Hub image reference:

```bash
docker run -d \
  --name registry-nginx-test \
  -p 8081:80 \
  tomislav1989/devops-nginx:v2
```

Explanation:

- `-d`: run in detached mode.
- `--name`: assign a readable container name.
- `-p 8081:80`: map host port 8081 to container port 80.
- `tomislav1989/devops-nginx:v2`: image reference.

We used port 8081 to avoid conflicts with previous labs using port 8080.

Verify:

```bash
docker ps --filter name=registry-nginx-test
```

Observed result:

```text
STATUS: Up
PORTS: 0.0.0.0:8081->80/tcp
NAME: registry-nginx-test
```

Test the application:

```bash
curl http://localhost:8081
```

Observed HTML:

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Docker DevOps Lab</title>
</head>
<body>
    <h1>My Docker Image - Version 2</h1>
    <p>This website is running inside my own Docker container.</p>
    <p>Azure / DevOps Learning Roadmap</p>
</body>
</html>
```

The application served the expected Version 2 content.

This confirms that the published image could be retrieved and used to start a functioning container.

## 14. Inspecting Container Logs

Check the logs:

```bash
docker logs --tail 20 registry-nginx-test
```

The Nginx logs showed successful initialization and an HTTP request:

```text
"GET / HTTP/1.1" 200 286
```

Explanation:

- `GET /`: HTTP request for the website root.
- `200`: successful HTTP response.
- `286`: response body size in bytes.

The logs confirm that Nginx started and served the requested page.

In real deployments, logs are an important troubleshooting source.

## 15. Final Cleanup

Stop the test container:

```bash
docker stop registry-nginx-test
```

Remove it:

```bash
docker rm registry-nginx-test
```

Verify:

```bash
docker ps -a --filter name=registry-nginx-test
```

The command returned no matching containers.

Check that the image remains available:

```bash
docker image ls tomislav1989/devops-nginx
```

Observed result:

```text
tomislav1989/devops-nginx:v2   32bd9bf67c81
```

The test container was removed, but the image remained locally available.

The published image also remained available on Docker Hub.

This demonstrates the separation between:

- Containers
- Local images
- Registry-hosted images

## 16. How This Connects to CI/CD

A typical CI/CD workflow for a containerized application looks like this:

```text
Developer pushes code to GitHub
              |
              v
GitHub Actions workflow starts
              |
              v
Application tests run
              |
              v
Docker image is built
              |
              v
Image is tagged with a version or commit SHA
              |
              v
Image is pushed to a container registry
              |
              v
Deployment environment pulls the image
              |
              v
Application is deployed
```

In our future Azure/DevOps labs, we will extend this workflow with:

- GitHub Actions
- Azure Container Registry
- Automated image builds
- Secure registry authentication
- Deployment automation
- Kubernetes

The core principles remain the same regardless of the registry provider.

## 17. Key Takeaways

- A Docker registry stores and distributes container images.
- Docker Hub is Docker's default public registry.
- Docker image names include a repository and an optional explicit tag.
- `docker tag` creates another reference to an existing image.
- `docker login` authenticates the Docker CLI to a registry.
- `docker push` publishes an image to a registry.
- Registries can reuse existing image layers.
- A local Image ID and a registry digest identify different objects.
- Tags can change; digests identify specific published content.
- `docker pull` retrieves an image from a registry.
- Removing a local tag does not delete the registry-hosted image.
- Removing a container does not automatically delete its image.
- Image publishing is a fundamental step in CI/CD pipelines.

---

# Lesson 7 – Docker Multi-stage Builds, .dockerignore & Image Optimization

## 1. Lesson Objectives

This lesson demonstrates how to build smaller, more efficient Docker images by separating application compilation from the final runtime environment.

Topics covered:

- Docker build context
- Dockerfile instruction order
- Image names and tags
- Single-stage builds
- The `.dockerignore` file
- Multi-stage builds
- Go application compilation
- Image size optimization
- Docker image layers and history
- Runtime validation
- Container cleanup

The practical lab uses a small Go HTTP application.

The application is compiled inside Docker, so Go does not need to be installed on the host machine.

## 2. Lab Directory Structure

Project directory:

```text
docker/multistage-lab/
├── .dockerignore
├── Dockerfile.single
├── Dockerfile.multi
├── debug.log
├── go.mod
└── main.go
```

File responsibilities:

| File | Purpose |
|---|---|
| `main.go` | Go HTTP application source code |
| `go.mod` | Go module definition |
| `debug.log` | Demonstrates exclusion from the build context |
| `.dockerignore` | Defines files excluded from the Docker build context |
| `Dockerfile.single` | Single-stage image definition |
| `Dockerfile.multi` | Multi-stage image definition |

## 3. Docker Build Context

The build context is the collection of files available to Docker during an image build.

Example:

```bash
docker build -f Dockerfile.single -t devops-go:single .
```

Command breakdown:

| Argument | Meaning |
|---|---|
| `docker build` | Builds a Docker image |
| `-f Dockerfile.single` | Selects the Dockerfile |
| `-t devops-go:single` | Assigns the image name and tag |
| `.` | Uses the current directory as the build context |

The final dot is particularly important.

When executed from `docker/multistage-lab`, Docker uses that directory as the build context.

The build context is not the same as the final Docker image.

A file can be available during the build without necessarily being copied into the final image.

For example:

```dockerfile
COPY . .
```

copies all non-excluded files from the build context into the current working directory inside the image.

By contrast:

```dockerfile
COPY main.go .
```

copies only `main.go`.

The first dot in `COPY . .` identifies the source within the build context.

The second dot identifies the destination inside the image, relative to `WORKDIR`.

## 4. Go HTTP Application

File: `main.go`

```go
package main

import (
    "fmt"
    "log"
    "net/http"
)

func main() {
    http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
        fmt.Fprintln(w, "Hello from Docker Multi-stage Build Lab!")
    })

    log.Println("Server listening on port 8080")

    log.Fatal(http.ListenAndServe(":8080", nil))
}
```

Explanation:

- `package main` defines an executable Go program.
- `net/http` provides HTTP server functionality.
- `http.HandleFunc("/")` registers a handler for the root URL.
- `fmt.Fprintln` writes the response to the HTTP client.
- `http.ListenAndServe(":8080", nil)` starts the HTTP server on port 8080.
- `log.Fatal` reports a server error and terminates the application.

Expected HTTP response:

```text
Hello from Docker Multi-stage Build Lab!
```

File: `go.mod`

```go
module example.com/devops/multistage-lab

go 1.23
```

The application uses only the Go standard library and requires no external Go dependencies.

## 5. Single-stage Dockerfile

File: `Dockerfile.single`

```dockerfile
FROM golang:1.23-alpine

WORKDIR /app

COPY . .

RUN go build -o server .

EXPOSE 8080

CMD ["./server"]
```

Instruction breakdown:

### FROM

```dockerfile
FROM golang:1.23-alpine
```

Selects the base image containing the Go compiler and supporting build environment.

### WORKDIR

```dockerfile
WORKDIR /app
```

Sets `/app` as the working directory for subsequent instructions.

If the directory does not exist, Docker creates it.

### COPY

```dockerfile
COPY . .
```

Copies the available build context files into `/app`.

Without `.dockerignore`, this also copies unnecessary files such as `debug.log`.

### RUN

```dockerfile
RUN go build -o server .
```

Compiles the Go application during image creation.

Command breakdown:

- `go build` compiles the Go application.
- `-o server` names the generated executable `server`.
- `.` selects the Go package in the current directory.

The generated executable is stored at `/app/server` inside the image.

It is not automatically created in the host's project directory.

### EXPOSE

```dockerfile
EXPOSE 8080
```

Documents that the application listens on port 8080.

`EXPOSE` does not automatically publish the port to the host.

Port publishing requires a command such as:

```bash
docker run -p 8082:8080 devops-go:single
```

### CMD

```dockerfile
CMD ["./server"]
```

Defines the default command executed when the container starts.

Because `WORKDIR` is `/app`, the command runs `/app/server`.

A command supplied after the image name in `docker run` overrides this default `CMD`.

Example:

```bash
docker run --rm devops-go:single ls -la /app
```

This executes `ls -la /app` instead of starting the HTTP server.

## 6. Dockerfile Instruction Order

Dockerfile instructions are processed sequentially.

Instruction order matters when later operations depend on earlier ones.

For this application, the logical order is:

```text
FROM
  |
WORKDIR
  |
COPY
  |
RUN
  |
EXPOSE
  |
CMD
```

For example, the source code must be copied before running `go build`.

Otherwise, the compiler will not find the application source files.

However, not every instruction has a fixed mandatory position.

For example, `EXPOSE 8080` could appear earlier without changing how the application is compiled.

Instruction order also affects Docker build caching.

Changes to an earlier instruction or its inputs can invalidate the cache for subsequent build steps.

Production Dockerfiles are often organized to maximize cache reuse.

## 7. Building the Single-stage Image

Build command:

```bash
cd ~/workspace/azure-learning-labs/docker/multistage-lab

docker build \
  -f Dockerfile.single \
  -t devops-go:single \
  .
```

Inspect the image:

```bash
docker image ls devops-go
```

Inspect files inside the image:

```bash
docker run --rm devops-go:single ls -la /app
```

Observed files:

```text
Dockerfile.single
debug.log
go.mod
main.go
server
```

The `server` file is the compiled executable.

The `debug.log` file is unnecessary for the application but was copied because of `COPY . .`.

Observed single-stage image size:

```text
327 MB
```

This image includes the Go compiler, build environment, source code and compiled application.

## 8. The .dockerignore File

The `.dockerignore` file excludes matching files from the Docker build context.

File: `.dockerignore`

```dockerignore
debug.log
.git
*.tmp
```

Rules:

| Pattern | Meaning |
|---|---|
| `debug.log` | Excludes the debug log |
| `.git` | Excludes Git metadata when present within the context |
| `*.tmp` | Excludes matching temporary files |

The `.dockerignore` file does not delete files from the host filesystem.

It only controls which files are available in the Docker build context.

It can improve build efficiency and help prevent unnecessary files from entering images.

However, `.dockerignore` is not a substitute for proper secrets management.

Passwords, access tokens and private keys should not be embedded in Docker images.

## 9. Building the Image with .dockerignore

Build a new image using the same single-stage Dockerfile:

```bash
docker build \
  -f Dockerfile.single \
  -t devops-go:ignored \
  .
```

Inspect the image:

```bash
docker run --rm devops-go:ignored ls -la /app
```

Observed files:

```text
.dockerignore
Dockerfile.single
go.mod
main.go
server
```

The `debug.log` file is no longer present.

This demonstrates that `.dockerignore` excluded the file before `COPY . .` was executed.

The `.dockerignore` file itself remained available in the context and was copied by `COPY . .`.

Compare the image sizes:

```bash
docker image ls devops-go
```

Observed results:

| Image | Size |
|---|---:|
| `devops-go:single` | 327 MB |
| `devops-go:ignored` | 327 MB |

Excluding a small text file did not significantly reduce image size.

The Go compiler and build environment were still present.

This motivates using a multi-stage build.

## 10. Multi-stage Builds

A multi-stage Dockerfile contains multiple `FROM` instructions.

Each `FROM` starts a new build stage.

The main purpose is to separate application compilation from the final runtime environment.

In this lab:

1. The builder stage compiles the Go application.
2. The runtime stage starts from a smaller Alpine image.
3. Only the compiled executable is copied into the final image.

The final image does not include the Go compiler or application source files.

## 11. Multi-stage Dockerfile

File: `Dockerfile.multi`

```dockerfile
# Stage 1 - Build the application
FROM golang:1.23-alpine AS builder

WORKDIR /app

COPY go.mod main.go ./

RUN CGO_ENABLED=0 go build -o server .

# Stage 2 - Run the application
FROM alpine:3.21

WORKDIR /app

COPY --from=builder /app/server ./server

EXPOSE 8080

CMD ["./server"]
```

### Builder stage

```dockerfile
FROM golang:1.23-alpine AS builder
```

Uses the Go base image and names the stage `builder`.

The stage name is referenced later when copying the compiled executable.

```dockerfile
COPY go.mod main.go ./
```

Copies only the files needed to build this application.

Unlike `COPY . .`, this does not copy unrelated project files.

```dockerfile
RUN CGO_ENABLED=0 go build -o server .
```

Compiles the Go application with CGO disabled.

For this simple application, this allows the executable to run without external C library dependencies.

### Runtime stage

```dockerfile
FROM alpine:3.21
```

Starts a new stage using a smaller Alpine Linux image.

The Go compiler is not included in this runtime base image.

```dockerfile
COPY --from=builder /app/server ./server
```

Copies the compiled executable from the builder stage into the runtime stage.

This is the key multi-stage instruction.

The source is `/app/server` inside the builder stage.

The destination is `./server`, relative to `/app` in the runtime stage.

The final image contains the compiled application and the Alpine runtime filesystem.

## 12. Building the Multi-stage Image

Build command:

```bash
docker build \
  -f Dockerfile.multi \
  -t devops-go:multi \
  .
```

Compare images:

```bash
docker image ls devops-go
```

Observed results:

| Image | Image ID | Size |
|---|---|---:|
| `devops-go:single` | `d87b92699efa` | 327 MB |
| `devops-go:ignored` | `2a068f33d297` | 327 MB |
| `devops-go:multi` | `ac833194a637` | 15.3 MB |

Inspect the runtime application directory:

```bash
docker run --rm devops-go:multi ls -la /app
```

Observed result:

```text
/app/
└── server
```

The final image does not contain:

- `main.go`
- `go.mod`
- `debug.log`
- `Dockerfile.single`
- Go compiler and build tools

Only the compiled application is present in `/app`.

The Alpine base image still provides its own runtime filesystem and utilities.

## 13. Image Size Optimization Results

The single-stage image was approximately:

```text
327 MB
```

The multi-stage image was approximately:

```text
15.3 MB
```

Approximate size reduction:

```text
327 MB - 15.3 MB = 311.7 MB
```

Percentage reduction:

```text
(327 - 15.3) / 327 * 100 = 95.3%
```

The multi-stage image is approximately 95.3% smaller.

Benefits of smaller images may include:

- Reduced image transfer times
- Lower storage requirements
- Faster image distribution
- Fewer unnecessary packages
- Reduced potential attack surface

A smaller image is not automatically secure.

Image security also depends on base image maintenance, dependency vulnerabilities, runtime permissions, secrets management and other controls.

## 14. Running and Testing the Multi-stage Application

Start the container:

```bash
docker run -d \
  --name devops-go-multi-test \
  -p 8082:8080 \
  devops-go:multi
```

Arguments:

| Argument | Meaning |
|---|---|
| `-d` | Runs the container in detached mode |
| `--name` | Assigns a container name |
| `-p 8082:8080` | Maps host port 8082 to container port 8080 |
| `devops-go:multi` | Selects the optimized image |

Check container status:

```bash
docker ps --filter name=devops-go-multi-test
```

Observed status:

```text
Up
```

Test the HTTP endpoint:

```bash
curl http://localhost:8082
```

Observed response:

```text
Hello from Docker Multi-stage Build Lab!
```

Check application logs:

```bash
docker logs devops-go-multi-test
```

Observed output:

```text
2026/11/20 09:51:15 Server listening on port 8080
```

This confirms that the application runs successfully in the final Alpine-based image without the Go compiler.

## 15. Understanding Docker Image Layers

Docker images are composed of filesystem layers and image metadata.

Instructions such as `COPY` and `RUN` can create filesystem layers.

Instructions such as `CMD`, `EXPOSE` and `WORKDIR` generally update metadata and may show a size of `0B` in image history.

Inspect the single-stage image:

```bash
docker history --human devops-go:single
```

Important observed history entries:

| History entry | Size |
|---|---:|
| Go base image layer | 237 MB |
| `RUN go build -o server .` | 80.5 MB |
| `COPY . .` | 564 B |
| Alpine base layer | 8.31 MB |

The Go build step added significantly more data than the final executable alone.

This can include compiler-generated intermediate build artifacts and caches.

Inspect the multi-stage image:

```bash
docker history --human devops-go:multi
```

Important observed history entries:

| History entry | Size |
|---|---:|
| Alpine base layer | 7.79 MB |
| `COPY /app/server ./server` | 7.46 MB |
| `WORKDIR /app` | 0 B |
| `EXPOSE 8080` | 0 B |
| `CMD ["./server"]` | 0 B |

The final image does not contain the Go builder stage layers.

The builder stage is used during compilation, but its filesystem is not included in the final runtime image.

The `<missing>` entries displayed by `docker history` are normal and do not mean that the image layers are missing or broken.

## 16. Container Cleanup

Stop the test container:

```bash
docker stop devops-go-multi-test
```

Remove the container:

```bash
docker rm devops-go-multi-test
```

Verify cleanup:

```bash
docker ps -a --filter name=devops-go-multi-test
```

Observed result:

```text
CONTAINER ID   IMAGE   COMMAND   CREATED   STATUS   PORTS   NAMES
```

No matching container remained.

The Docker images were retained for comparison.

The `--rm` option can also be used with `docker run` to automatically remove a container after it exits.

Example:

```bash
docker run --rm devops-go:multi ls -la /app
```

This removes the temporary container but does not delete the Docker image.

## 17. Production Considerations

The lab demonstrates important optimization techniques, but a production-ready Docker image requires additional considerations.

Recommended practices include:

- Use maintained and supported base images.
- Pin image versions or digests when reproducibility is important.
- Regularly rebuild images to receive security updates.
- Use `.dockerignore` to exclude unnecessary files.
- Copy only the files needed for each build stage.
- Separate build dependencies from runtime dependencies.
- Prefer running applications as a non-root user where practical.
- Avoid embedding secrets in Dockerfiles or image layers.
- Scan images for known vulnerabilities.
- Use automated image builds in CI/CD pipelines.
- Validate that the application runs correctly in the final runtime image.

The Go and Alpine image versions used in this lab are recorded for reproducibility of the exercise, not as a recommendation to use those exact versions indefinitely.

## 18. CI/CD Relevance

Multi-stage builds are especially useful in automated delivery pipelines.

A typical workflow is:

```text
Developer commits code
        |
        v
GitHub repository
        |
        v
CI pipeline
        |
        v
Docker multi-stage build
        |
        v
Optimized runtime image
        |
        v
Container registry
        |
        v
Deployment environment
```

The CI pipeline can build the application using a compiler image and publish only the optimized runtime image.

This keeps build tooling out of the deployed image.

The resulting image can be deployed to services such as Azure Container Apps, Azure Kubernetes Service or other container platforms.

## 19. Key Takeaways

- Docker build context defines which files are available during image construction.
- The final dot in `docker build ... .` selects the current directory as the build context.
- `COPY` controls which available files enter the image.
- Dockerfile instruction order matters when instructions depend on earlier steps.
- `-t` assigns a name and tag to an image.
- `go build -o server .` creates the compiled Go executable.
- `.dockerignore` excludes matching files from the build context.
- Excluding small files does not necessarily reduce image size significantly.
- Single-stage builds may retain unnecessary compilers and build artifacts.
- Multi-stage builds separate compilation from runtime execution.
- `COPY --from=builder` copies files from a previous build stage.
- The optimized image successfully ran the same Go HTTP application.
- The image size decreased from 327 MB to 15.3 MB.
- The measured reduction was approximately 95.3%.
- `docker history` helps inspect image construction and layer sizes.
- Smaller images can improve distribution efficiency and reduce unnecessary software.
- Multi-stage builds are an important building block for production CI/CD pipelines.
