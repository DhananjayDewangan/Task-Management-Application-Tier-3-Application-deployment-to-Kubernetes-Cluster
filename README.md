# Task Management Application

A three-tier task management application built to demonstrate an end-to-end DevOps workflow using React, Node.js, PostgreSQL, Docker, Terraform, Kubernetes, GitHub Actions, and Docker Hub.

## Overview

This project implements a task management application with:

- A React frontend
- A Node.js/Express backend API
- A PostgreSQL database
- NGINX reverse proxying from the frontend to the backend
- Docker and Docker Compose for local containerized development
- Kubernetes deployment using Kind
- Terraform for Kubernetes infrastructure
- GitHub Actions for CI and Docker image publishing
- A local deployment script for applying the application to Kubernetes

## Architecture

```
                         GitHub
                           |
                           v
                    GitHub Actions
                    /            \
              CI checks       Docker Build
                                  |
                                  v
                             Docker Hub
                         :1.0 application images
                                  |
                                  v
                     ./scripts/deploy.sh
                                  |
                                  v
                         Terraform + kubectl
                                  |
                                  v
                    Kind Kubernetes Cluster
                         task-management
                                  |
              +-------------------+-------------------+
              |                   |                   |
              v                   v                   v
        Frontend Service     Backend Service     PostgreSQL
          NodePort              ClusterIP          ClusterIP
              |                   |                   |
              v                   v                   v
           NGINX             Express API          PostgreSQL
              |
              +---- /api/ ----> Backend

```

## Technology Stack

| Layer                             | Technology        |
| --------------------------------- | ----------------- |
| Frontend                          | React + Vite      |
| Backend                           | Node.js + Express |
| Database                          | PostgreSQL 17     |
| Web server / Reverse proxy        | NGINX             |
| Containers                        | Docker            |
| Local multi-container development | Docker Compose    |
| Infrastructure                    | Terraform         |
| Kubernetes                        | Kubernetes / Kind |
| CI                                | GitHub Actions    |
| Container registry                | Docker Hub        |
| Source control                    | Git + GitHub      |




## Project Structure
```
├── backend/
│   ├── src/
│   ├── .dockerignore
│   ├── .env.example
│   ├── Dockerfile
│   ├── package.json
│   └── package-lock.json
│
├── frontend/
│   ├── src/
│   ├── .dockerignore
│   ├── .env.example
│   ├── Dockerfile
│   ├── nginx.conf
│   ├── package.json
│   └── package-lock.json
│
├── kubernetes/
│   └── init.sql
│
├── scripts/
│   └── deploy.sh
│
├── terraform/
│   ├── main.tf
│   ├── variables.tf
│   └── .terraform.lock.hcl
│
├── .github/
│   └── workflows/
│       └── ci.yml
│
├── docker-compose.yml
├── .gitignore
└── README.md

```

## Application Features
The application supports task CRUD operations:

- Create a task
- List tasks
- Update a task
- Mark a task as completed
- Delete a task

The backend exposes a health endpoint:

```
GET /api/health
```

Expected response:
```
{
  "status": "ok",
  "service": "task-management-api"
}

```

## Local Development
#### Prerequisites

**Install:**
- Git
- Node.js 24
- npm
- Docker Desktop
- WSL2 if using Windows
- Kind
- kubectl
- Terraform


### Backend
```
cd backend
npm ci
npm start
```
The backend runs on:
```
http://localhost:3000
```
Backend configuration is provided through environment variables.
Use **.env.example** as the template for local configuration.

### Frontend
```
cd frontend
npm ci
npm run dev
```
The Vite development server provides the frontend during local development.

#### Docker Compose

The complete three-tier application can be started with:
```
docker compose up -d --build
```
Check the running containers:
```
docker compose ps
```
Stop the application:
```
docker compose down
```
The Docker Compose architecture consists of:
```
Frontend / NGINX
       |
       v
Backend / Express
       |
       v
PostgreSQL
```
The frontend NGINX configuration proxies **/api/** requests to the backend container.

### Kubernetes Deployment
The project uses a local Kind cluster named:
```
task-management
```
Verify the current Kubernetes context:
```
kubectl config current-context
```
Expected:
```
kind-task-management
```
Check the cluster nodes:
```
kubectl get nodes
```

### Terraform
Terraform manages the Kubernetes resources, including:
- Namespace
- PostgreSQL Secret
- PostgreSQL PersistentVolumeClaim
- PostgreSQL Deployment and Service
- Backend Deployment and Service
- Frontend Deployment and Service

Initialize Terraform:
```
terraform -chdir=terraform init
```
Validate:
```
terraform -chdir=terraform validate
```
Review the plan:
```
terraform -chdir=terraform plan
```
Apply:
```
terraform -chdir=terraform apply
```

The database password is supplied through the local terraform/terraform.tfvars file.
Do not commit that file.

### Kubernetes Services
The application uses:
- Frontend: NodePort
- Backend: ClusterIP
- PostgreSQL: ClusterIP

The frontend is the externally accessible application entry point.

### Persistent Storage
PostgreSQL uses a Kubernetes PersistentVolumeClaim so that database data is stored independently from the PostgreSQL pod lifecycle.

Do not delete the PostgreSQL PVC unless intentionally resetting the database.

### Database Schema

The intended PostgreSQL schema is stored in `kubernetes/init.sql`.

The current Terraform configuration does not automatically mount or execute this file during PostgreSQL initialization. The file is retained as the version-controlled schema definition for the application database.

### Local Deployment Script
The repository contains:
```
scripts/deploy.sh
```
Run:
```
./scripts/deploy.sh
```
The script:
* Checks the active Kubernetes context.
* Checks Kubernetes node availability.
* Applies the Terraform configuration.
* Restarts the backend deployment.
* Restarts the frontend deployment.
* Waits for both rollouts to complete.

The context check helps prevent accidentally deploying this project to an unintended Kubernetes cluster.

### Docker Images

The application images are published to Docker Hub using the static 1.0 tag:
```
dhananjaydewangan/task-management-backend:1.0
dhananjaydewangan/task-management-frontend:1.0
```
Kubernetes uses:
```
imagePullPolicy: Always
```
The deployment script explicitly restarts the application deployments so that new pods pull the current 1.0 images.

This static-tag approach is intentionally simple for this local learning project.

For a production system, immutable versioned tags such as Git commit SHAs would generally provide stronger release traceability.

## CI Pipeline

GitHub Actions runs on pushes and pull requests targeting main.

The pipeline contains:

### Backend CI
- Checkout repository
- Set up Node.js 24
- Install dependencies with npm ci
- Validate backend syntax

### Frontend CI
- Checkout repository
- Set up Node.js 24
- Install dependencies with npm ci
- Run frontend linting
- Build the frontend

### Docker Build and Push
After the backend and frontend CI jobs succeed:

- Authenticate to Docker Hub
- Build the backend image
- Push the backend :1.0 image
- Build the frontend image
- Push the frontend :1.0 image

### GitHub-hosted runners are used for CI.

**The local Kind cluster is not automatically deployed from GitHub Actions.**

**Deployment to the local Kubernetes cluster is performed manually with:**
```
./scripts/deploy.sh
```
**Verification**
Kubernetes resources
```
kubectl get all -n task-management
```
**Backend health through the frontend**
```
kubectl run curl-test \
  -n task-management \
  --rm -it \
  --restart=Never \
  --image=curlimages/curl:8.10.1 \
  -- curl http://frontend/api/health
```
Expected:
```
{
  "status": "ok",
  "service": "task-management-api"
}
```
**Frontend access**
Forward the frontend service:
```
kubectl port-forward \
  -n task-management \
  service/frontend \
  8080:80
```
Then open:
```
http://localhost:8080
```
**Configuration and Secrets**

Sensitive/local configuration is intentionally excluded from Git.

Examples:
```
backend/.env
frontend/.env
terraform/terraform.tfvars
terraform/terraform.tfstate
```
Example configuration files are provided where appropriate:
```
backend/.env.example
frontend/.env.example
```
Never commit passwords, tokens, or other secrets to the repository.

### Design Decisions
Static Docker image tag

The project uses :1.0 for the application images to keep the learning workflow simple.
```
imagePullPolicy: Always
```
Because the same :1.0 tag can be updated, Kubernetes is configured to always pull the image when a new pod starts.

### Manual local deployment

GitHub-hosted runners cannot directly access the local Kind cluster.

Instead of introducing a self-hosted GitHub runner, deployment is intentionally performed locally with scripts/deploy.sh.

### Terraform for Kubernetes resources

Terraform provides a reproducible definition of the Kubernetes infrastructure rather than relying entirely on manually executed kubectl commands.

### Future Improvements

Possible future improvements include:
- Immutable Docker image tags based on Git commit SHA
- Automated deployment to a remote Kubernetes cluster
- Helm charts
- Kubernetes Ingress
- TLS
- External secret management
- Database initialization through Kubernetes configuration
- Automated integration tests
- Prometheus monitoring
- Grafana dashboards
- Centralized logging
- Kubernetes resource limits and autoscaling
- Production-grade PostgreSQL architecture

### Status

The project currently runs as a complete three-tier application on a local Kind Kubernetes cluster with Terraform-managed infrastructure, Dockerized application components, persistent PostgreSQL storage, GitHub Actions CI, and Docker Hub image publishing.
