# Strapi Task-1 – Local Setup, Docker & Sample Content Type

This repository contains the work completed for **TASK-1**, including:
- Cloning the Strapi repository
- Running Strapi locally
- Exploring folder structure
- Creating a sample content type
- Dockerizing the project
- Documenting the setup

A Loom video walkthrough and Pull Request link are also included.

---

## 1-1. Clone the Strapi Repository

```bash
git clone https://github.com/strapi/strapi.git
cd strapi
```

---

## 1-2. Create a Local Strapi Project

```bash
npx create-strapi-app@latest my-project
cd my-project
```

Follow the prompts:  
- Database: SQLite (default)  
- Example content: Yes  
- TypeScript: Yes  
- Install dependencies: Yes

---

## 1-3. Install Dependencies

```bash
npm install
```

Or, if using Yarn:

```bash
yarn install
```

---

## 1-4. Run Strapi Locally

```bash
npm run develop
```

- Admin Panel: [http://localhost:1337/admin](http://localhost:1337/admin)  
- API Server: [http://localhost:1337](http://localhost:1337)

Register your first admin user on the first launch.

---

## 1-5. Explore Project Folder Structure

- `config/` – Configuration files  
- `src/api/` – API and content types  
- `src/components/` – Reusable components  
- `public/` – Static files  
- `.env` – Environment variables

---

## 1-6. Create a Sample Content Type

**Collection Type:** Blog Post  
Fields:  
- `title` (Text)  
- `content` (Rich Text)  
- `publishedAt` (DateTime)  

---

## Task-2. Dockerize the Project

### 2.1 Create a Dockerfile in `my-project/`

```Dockerfile
# Base image
FROM node:18-alpine

# Set working directory
WORKDIR /app

# Copy package files and install dependencies
COPY package.json package-lock.json* yarn.lock* ./
RUN npm install

# Copy the rest of the project
COPY . .

# Build the admin panel
RUN npm run build

# Set environment
ENV NODE_ENV=production

# Expose port
EXPOSE 1337

# Start Strapi
CMD ["npm", "run", "start"]
```

---

### 2.2 Create a `.env` File in `my-project/`

```env
# Server
HOST=0.0.0.0
PORT=1337

# Secrets
APP_KEYS=SrGRSHbSbHV/OUmId7doZg==,cL+QLmuRM9a9qlEl/adnyQ==,kp6YXYbOkeIqmu0YyevJTg==,XShDrs9TJTconCAJjL4SBw==
API_TOKEN_SALT=DyBgHklIZdboUlQAZZ/42g==
ADMIN_JWT_SECRET=BAtS+/RTXz97ztKthDHJ2g==
TRANSFER_TOKEN_SALT=kDiBX+hOa+bhAKPpSFR37A==
ENCRYPTION_KEY=8sPv6kraSJAPrV50wj2jpA==
ADMIN_AUTH_SECRET=H3F9oWqv7J2u1PcQ5tUyZg==

# Database
DATABASE_CLIENT=sqlite
DATABASE_FILENAME=.tmp/data.db
JWT_SECRET=q9O4SbGr3ewg3SktK8qieA==
DATABASE_SSL=false
```
<img width="1153" height="636" alt="image" src="https://github.com/user-attachments/assets/51c1cf45-97d0-48dc-ad9c-e047a14e7b00" />

---

### 2.3 Build and Run Docker Container

```bash
# Build Docker image
docker build -t strapi-app .

# Run container
docker run --env-file .env -p 1337:1337 strapi-app
```

- Admin Panel: [http://localhost:1337/admin](http://localhost:1337/admin)  
- API Server: [http://localhost:1337](http://localhost:1337)

---
<img width="1547" height="986" alt="Screenshot 2025-12-04 143304" src="https://github.com/user-attachments/assets/80830098-2b7f-419c-836a-ab3d18004dcb" />

<img width="1472" height="989" alt="Screenshot 2025-12-04 143247" src="https://github.com/user-attachments/assets/46acb48b-ad0a-4e52-ab5a-4386c5d73c72" />


<img width="1314" height="739" alt="Screenshot 2025-12-04 143031" src="https://github.com/user-attachments/assets/9a51d381-5823-4842-87c1-26740ebc6ed9" />


## 2.4. Push Project to GitHub

```bash
git branch
reshma-strap-api-task01
git push -u origin main
```
<img width="960" height="234" alt="Screenshot 2025-12-04 145808" src="https://github.com/user-attachments/assets/b674ea7a-9488-4c47-9680-9d1f9b794840" />
---

## 2-5. How to Run This Project

### Locally:

```bash
git clone https://github.com/strapi/strapi.git
cd My-Strapi
npm install
npm install -g yarn
yarn install
npx create-strapi-app@latest my-project
cd /my-project
npm run develop
```

### Using Docker:

```bash
git clone https://github.com/strapi/strapi.git
cd My-Strapi
docker build -t strapi-app .
docker run --env-file .env -p 1337:1337 strapi-app
```

Then open [http://localhost:1337/admin](http://localhost:1337/admin)

<img width="1658" height="980" alt="Screenshot 2025-12-04 143001" src="https://github.com/user-attachments/assets/5a8ca0e6-8330-41bb-b6e3-c1f5104a0dac" />

<img width="1314" height="739" alt="Screenshot 2025-12-04 143031" src="https://github.com/user-attachments/assets/9a51d381-5823-4842-87c1-26740ebc6ed9" />


## Task-3 Setting up a Dockerized Environment with Portgres and nginx Reverse Proxy
## 3-1. Docker Compose Setup

``` yaml
services:
  postgres:
    image: postgres:15
    container_name: postgres
    restart: unless-stopped
    environment:
      POSTGRES_USER: strapi
      POSTGRES_PASSWORD: strapi123
      POSTGRES_DB: strapi_db
    volumes:
      - ./postgres-data:/var/lib/postgresql/data
    networks:
      - strapi-net

  strapi:
    build: .
    container_name: my-project-strapi
    restart: unless-stopped
    env_file: .env
    depends_on:
      - postgres
    ports:
      - "1337:1337"
    networks:
      - strapi-net

  nginx:
    image: nginx:latest
    container_name: nginx
    restart: unless-stopped
    ports:
      - "80:80"
    volumes:
      - ./nginx.conf:/etc/nginx/conf.d/default.conf:ro
    depends_on:
      - strapi
    networks:
      - strapi-net

networks:
  strapi-net:
```

------------------------------------------------------------------------
## 3-2. Nginx Reverse Proxy(create a nginx.conf file in your folder)

``` nginx
server {
    listen 80;

    server_name localhost;

    location / {
        proxy_pass http://strapi:1337;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

------------------------------------------------------------------------
## 3-3. Postgres + Strapi Environment Variables (Update the existing .env file database setup like as shown below)

    HOST=0.0.0.0
    PORT=1337

    APP_KEYS=YOUR_KEYS
    API_TOKEN_SALT=YOUR_SALT
    ADMIN_JWT_SECRET=YOUR_SECRET
    TRANSFER_TOKEN_SALT=YOUR_SALT
    ENCRYPTION_KEY=YOUR_KEY
    ADMIN_AUTH_SECRET=YOUR_SECRET

    DATABASE_CLIENT=postgres
    DATABASE_HOST=postgres
    DATABASE_PORT=5432
    DATABASE_NAME=strapi_db
    DATABASE_USERNAME=strapi
    DATABASE_PASSWORD=strapi123
    DATABASE_SSL=false

------------------------------------------------------------------------

## 3-4. Run Docker Setup(To run the docker compose)

``` bash
docker compose up --build
```

Containers started: - postgres\
- my-project-strapi\
- nginx

Visit: 👉 http://localhost/admin

------------------------------------------------------------------------


## 9. Screenshots

Include: - Docker Desktop running containers\
- Strapi logs\
- Admin Panel screenshot

<img width="851" height="596" alt="Screenshot 2025-12-05 175411" src="https://github.com/user-attachments/assets/d4c45943-7023-451a-ae84-57552a1baed4" />


<img width="1400" height="860" alt="Screenshot 2025-12-05 173935" src="https://github.com/user-attachments/assets/97e30c7c-1a83-4712-bb54-3b3293b904a2" />

<img width="1364" height="853" alt="Screenshot 2025-12-05 174005" src="https://github.com/user-attachments/assets/2b69d250-d4b3-45c6-ab0e-146c76286c5c" />


## 9. Loom Video

Add your Loom link here.

---


## 10. Pull Request

Add your PR link here.

---





