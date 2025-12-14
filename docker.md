# Docker Deep Dive Documentation

## 1. The Problem Docker Solves

Traditional software deployment often results in "works on my machine"
issues due to differences in OS, dependencies, and configurations across
environments. Docker solves this by packaging applications and their
dependencies into portable, isolated containers that run consistently
across systems.

## 2. Virtual Machines vs Docker Containers

### Virtual Machines

-   Heavyweight: requires full guest OS
-   Slow startup time
-   Large resource consumption
-   Strong isolation

### Docker Containers

-   Lightweight, share host OS kernel
-   Fast startup
-   Efficient resource usage
-   Ideal for microservices & DevOps workflows

## 3. Docker Architecture -- What Gets Installed?

When installing Docker, these components are included: - **Docker CLI**:
The `docker` command interface. - **Docker Daemon (`dockerd`)**: Manages
images, containers, networking. - **containerd**: Container lifecycle
manager. - **runc**: Low-level OCI runtime. - **BuildKit**: Image
building engine. - **Docker Engine API**: Communication layer for
clients.

## 4. Dockerfile Deep Dive --- Explain Each Line

### Example Dockerfile

``` dockerfile
FROM node:20-alpine
WORKDIR /app
COPY package.json package-lock.json* yarn.lock* ./
RUN npm install
COPY . .
RUN npm run build
ENV NODE_ENV=production
EXPOSE 1337
CMD ["npm", "run", "start"]
```

### Explanation

-   **FROM**: Specifies base image.
-   **WORKDIR**: Sets working directory.
-   **COPY**: Copies dependency files for caching.
-   **RUN npm install**: Installs dependencies.
-   **COPY . .**: Copies full project code.
-   **RUN npm run build**: Builds Strapi production build.
-   **ENV**: Sets environment variable.
-   **EXPOSE**: Documents port the app listens on.
-   **CMD**: Command to start application.

## 5. Key Docker Commands

-   `docker build -t app .`
-   `docker run -d -p 1337:1337 app`
-   `docker ps`, `docker stop`, `docker logs`
-   `docker exec -it container sh`
-   `docker images`, `docker rmi`
-   `docker volume ls`
-   `docker network ls`

## 6. Docker Networking

-   **bridge**: Default network for containers on a single host.
-   **host**: Shares host network stack.
-   **none**: No network.
-   **overlay**: Multi-host networking.
-   Containers resolve each other by service name on user-defined
    networks.

## 7. Volumes & Persistence

-   **Named volumes**: Managed by Docker.
-   **Bind mounts**: Maps host directory to container.
-   Used to persist database data or uploads. Example:\
    `docker volume create data_vol`

## 8. Docker Compose

-   Used to run multi-container applications.
-   YAML-based configuration.
-   Handles networking, volumes, dependency order.

### Example docker-compose.yml

``` yaml
version: "3.8"
services:
  postgres:
    image: postgres:15
  strapi:
    build: .
    depends_on:
      - postgres
  nginx:
    image: nginx
```

Docker Compose simplifies orchestration of multi-service environments.
