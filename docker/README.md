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
