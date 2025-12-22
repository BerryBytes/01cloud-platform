# 01Cloud Development Environment

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Last Commit](https://img.shields.io/github/last-commit/BerryBytes/01cloud-platform)](https://github.com/BerryBytes/01cloud-platform/commits)
[![Open Issues](https://img.shields.io/github/issues/BerryBytes/01cloud-platform)](https://github.com/BerryBytes/01cloud-platform/issues)
[![Open PRs](https://img.shields.io/github/issues-pr/BerryBytes/01cloud-platform)](https://github.com/BerryBytes/01cloud-platform/pulls)
[![Contributors](https://img.shields.io/github/contributors/BerryBytes/01cloud-platform)](https://github.com/BerryBytes/01cloud-platform/graphs/contributors)

A local, reproducible Kubernetes development environment for the 01Cloud platform. This repository orchestrates all 01Cloud microservices and dependencies using Kind, Helm, and Skaffold, and provides a single CLI, 01cloud, to bootstrap, run, seed, and manage the full stack on your machine.

- Project website: https://01cloud.io
- Demo URLs after setup:
  - UI console: https://console.staging.01cloud.dev
  - Admin console: https://admin.staging.01cloud.dev
  - API: https://api.staging.01cloud.dev

---

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Architecture and Components](#architecture-and-components)
- [Tech Stack](#tech-stack)
- [Prerequisites](#prerequisites)
- [Getting Started](#getting-started)
  - [1) Clone](#1-clone)
  - [2) Install prerequisites](#2-install-prerequisites)
  - [3) Create a Kind cluster](#3-create-a-kind-cluster)
  - [4) Bootstrap and run 01Cloud](#4-bootstrap-and-run-01cloud)
  - [5) Verify and open the apps](#5-verify-and-open-the-apps)
- [Usage](#usage)
  - [01cloud CLI](#01cloud-cli)
  - [Environments, hosts, and data](#environments-hosts-and-data)
  - [Seeding data](#seeding-data)
  - [Stopping and cleanup](#stopping-and-cleanup)
- [Configuration](#configuration)
  - [Helm values](#helm-values)
  - [Httproutes and hostnames](#httproute-and-hostnames)
  - [Images and building locally](#images-and-building-locally)
- [Alerting and Monitoring](#alerting-and-monitoring)
- [Contributing](#contributing)
- [License](#license)
- [Credits](#credits)

---

## Overview

01Cloud Development Environment is a batteries-included local stack to run the full 01Cloud platform on Kubernetes. It automates cluster setup, installs core controllers (Gateway API, Tekton, MetalLB), provisions databases and messaging, deploys all 01Cloud services via a Helm chart, and optionally seeds the system with sample configuration and data for an instant test drive.

What it does:
- Creates or prepares a local Kubernetes cluster (Kind)
- Installs Gateway API and load balancer controllers
- Deploys databases and queues (PostgreSQL, MongoDB, RabbitMQ)
- Deploys all 01Cloud microservices via Helm and Skaffold
- Sets up local hostnames and TLS for easy browsing
- Optionally seeds the platform with default settings and sample content

What problem it solves:
- Eliminates the friction of coordinating dozens of services and infra dependencies
- Provides a single-command developer workflow suitable for local iteration and demos
- Ensures a reproducible, documented path to run the entire platform

Who is it for:
- Application developers contributing to 01Cloud microservices
- DevOps engineers evaluating or customizing the 01Cloud stack
- Contributors who want a turnkey local environment to explore the platform

Why it was created:
- To standardize local development and testing
- To improve onboarding for new contributors and teams
- To reduce time-to-first-success for evaluating 01Cloud

---

## Features

- One-command bootstrap of the full stack via a friendly CLI
- Local Kubernetes with Kind and MetalLB, plus Gateway API Controller
- Tekton installation for CI/CD workflows inside the cluster
- Helm chart to deploy 01Cloud microservices with configurable values
- Skaffold integration for dev/run/build workflows
- Predefined services and httproute for UI, Admin, API, Terminal, etc.
- Data layer ready out-of-the-box: PostgreSQL, MongoDB, RabbitMQ
- Seeder utility to populate default configuration and sample data
- Hostname automation to route staging.* domains to your local cluster
- Clean teardown of services and data
- Integrated Auth0 authentication with KrakenD API Gateway

---

## Architecture and Components

Core components deployed by this environment:
- Controllers: Gateway API Controller, MetalLB, Tekton
- Data services: PostgreSQL, MongoDB, RabbitMQ
- 01Cloud services: UI, Admin, API, Core, Notifications, Payments, Support, Monitoring, Backup, Helm CD, Terminal
- Authentication: Auth0 + KrakenD API Gateway for JWT validation
- Observability hooks: optional logging and monitoring configuration
- TLS integration and httproute with hostnames like console.staging.01cloud.dev

All services are orchestrated via:
- Helm chart at charts/
- Skaffold for deploy workflows
- A bash CLI wrapper 01cloud for common operations

---

## Prerequisites

- OS: Linux (tested on Ubuntu) or macOS with Docker Desktop
- Hardware: 4+ CPUs and 8+ GB RAM recommended
- Tools:
  - Docker (or Docker Desktop)
  - Kind
  - kubectl
  - Helm 3.x
  - Skaffold 2.x
  - git, curl, jq
  - Configure Auth0 and KrankenD, see [Authentication Configuration Guide](AUTHENTICATION-CONFIGURATION.md) for detailed steps


Install snippets (Linux/Ubuntu):


### 1) Create a Kind cluster

You can create your own cluster or use the provided multi-node config for kind:

```bash
# Creates a 3-node cluster (1 control-plane, 2 workers)
kind create cluster --name 01cloud-dev --config test-cluster.yaml
```
Verify:

```bash
kubectl cluster-info
kubectl get nodes
```

### 2)Template preparation:
Fill the values [`Values.yaml`](charts/template/values.yaml)  and [`ConfigMap.yaml`](charts/template/configmap.yaml) inside the charts/template folder. These Template are necessary during provision for one to get features like 0Auth, mail service etc.

Ensure the `.env` file contains necessary key values according to the sample(`.env.sample`). This step is necessary during `DBseed` process for DNS creation.

### 3) Bootstrap and run 01Cloud


The 01cloud CLI automates cluster setup, hosts configuration, databases, deployment, and seeding. It may prompt for sudo to manage /etc/hosts.


Option A: Full install (recommended for first run)

```bash
# From the repo root
chmod +x ./01cloud
./01cloud install
```
Option B: Step-by-step

```bash
# Install MetalLB, Tekton, and Gateway API Controller
./01cloud setup

# Add hostnames (requires sudo)
./01cloud host

# Install databases and PVCs (RWO default, or pass 'rwx' for NFS RWX)
./01cloud dbrun

# Deploy the stack (skaffold run) or run in dev mode (skaffold dev)
./01cloud run
# or
./01cloud dev

# Optional: seed data once services are healthy
./01cloud dbseed
```
### 4) Verify and open the apps

```bash
kubectl get pods -n 01cloud-staging
kubectl get httproutes -A
```
Then open in your browser:
- https://console.staging.01cloud.dev
- https://admin.staging.01cloud.dev
- https://api.staging.01cloud.dev

If the domains don’t resolve, rerun:

```bash
./01cloud host
```
---

## Usage

### 01cloud CLI

Common commands:

```bash
./01cloud install [env [mode]]   # setup + host + dbrun + run (+ seed in install.sh)
./01cloud setup [env [mode]]     # install required controllers (Tekton, Gateway API, MetalLB)
./01cloud host [add|remove]      # map local LB IP to staging.* hostnames in /etc/hosts
./01cloud dbrun [rwo|rwx]        # install PostgreSQL, MongoDB, RabbitMQ with PVCs
./01cloud dbseed                 # seed sample data and defaults
./01cloud run                    # skaffold run (build+deploy once)
./01cloud dev                    # skaffold dev (watch & redeploy)
./01cloud build                  # skaffold build
./01cloud deploy                 # helm deploy via skaffold
./01cloud stop                   # skaffold delete (app resources)
./01cloud dbstop                 # delete DB resources
./01cloud clean                  # stop + DB stop + cleanup setup
```
Notes:
- env defaults to local, mode defaults to rwo
- host operation requires sudo to modify /etc/hosts
- dev/startup scripts will wait for readiness of critical services

### Environments, hosts, and data

- Namespace: 01cloud-staging
- Hostnames (mapped to your local LB IP via host):
  - console.staging.01cloud.dev
  - admin.staging.01cloud.dev
  - api.staging.01cloud.dev
  - terminal.staging.01cloud.dev
- PVC mode: RWO (default) or RWX (with OpenEBS NFS enabled by setup when you pass rwx)

### Seeding data

The seeder script populates default settings, packages, and example content via the API. Run once the API is ready:

```bash
./01cloud dbseed
```
Tip: Review seeder/seeder.sh to understand exactly what is being created and adjust to your needs before running in non-local environments.

### Stopping and cleanup

```bash
# Remove app resources
./01cloud stop

# Remove app + DB resources
./01cloud dbstop

# Remove all setup (Gateway API, controllers) and resources
./01cloud clean

# Optionally delete the Kind cluster when finished
kind delete cluster --name 01cloud-dev
```
---

## Alerting and Monitoring

This repo includes optional guidance for integrating Prometheus and Google Chat alerting. See alerting/README.md for:
- Installing Prometheus via Helm
- Installing the gchat alertmanager integration
- Configuring alertmanager webhook and custom notification templates

You can also review helper/logging.yaml for example logging setup with BanzaiCloud Logging and Loki (requires appropriate CRDs and operator set up).

---

## Contributing

We welcome contributions!

- Check open issues: https://github.com/BerryBytes/01cloud-development/issues
- Fork the repo and create a feature branch from main
- Keep changes small and focused; include tests or examples where applicable
- Run the local environment and verify your changes
- Open a pull request and fill in the PR template; link related issues

Before submitting:
- Lint YAML and bash where possible
- Avoid committing secrets; use placeholders and document configuration
- Ensure README and docs are updated if behavior/config changes

If you have questions or want to discuss ideas, open a GitHub Discussion or an issue.

---

## License

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

This project is licensed under the MIT License. See the LICENSE file for details.

---

## Credits

- 01Cloud team at [BerryBytes](https://01cloud.io/)
- Open-source projects that make this possible: Kubernetes, Kind, Helm, Skaffold, Tekton, MetalLB, Gateway API Controller, PostgreSQL, MongoDB, RabbitMQ, Loki, and others.

If your organization uses this environment or contributes improvements, consider adding yourself to CONTRIBUTORS.md in a future PR.

---

## Security Notes

- Do not use default or example secrets in production environments.
- Store sensitive credentials securely (e.g., as environment variables or in a secret manager) and inject via Helm values at deploy time.
- Review charts/templates/secret.yaml and charts/values.yaml and replace any example credentials/secrets with your own before public use.

---

## Troubleshooting

- No external IP for gatewway:
  - Ensure MetalLB installed and ready: kubectl get pods -n metallb-system
  - Re-run: ./01cloud setup
- Hostnames not resolving:
  - Re-run: ./01cloud host (requires sudo)
- Pods not starting:
  - Check: kubectl get pods -n 01cloud-staging
  - Inspect events/logs: kubectl describe pod/<name> -n 01cloud-staging; kubectl logs <name> -n 01cloud-staging
- Adjust resources:
  - Edit charts/values.yaml PVC and resource requests/limits as needed

Enjoy building with 01Cloud!
