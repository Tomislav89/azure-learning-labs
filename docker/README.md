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
