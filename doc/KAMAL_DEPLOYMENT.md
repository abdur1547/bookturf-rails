# Kamal Deployment Guide

## Overview

Kamal is a deployment tool that lets you deploy web apps anywhere using Docker with zero downtime. It's included in this Rails application for easy deployment to any server with SSH access and Docker installed.

## What is Kamal?

Kamal (formerly known as MRSK) deploys your application as Docker containers on any server. It handles:

- ✅ Zero-downtime deployments
- ✅ Rolling restarts
- ✅ Health checks
- ✅ SSL/TLS certificates (via Let's Encrypt)
- ✅ Environment variable management
- ✅ Database deployments
- ✅ Background job workers
- ✅ Multiple environments (staging, production)

## Prerequisites

### Local Machine

```bash
# Ruby 3.0+ (already installed)
# Docker (for building images locally)
# SSH access to your servers
```

### Remote Servers

Each server needs:

- Docker installed and running
- SSH access (preferably with key-based authentication)
- Open ports: 80 (HTTP), 443 (HTTPS), 22 (SSH)
- Minimum 1GB RAM recommended

### Docker Registry

You need a Docker registry to store your images:

- Docker Hub (free for public images)
- GitHub Container Registry (free)
- AWS ECR
- Google Container Registry
- Self-hosted registry

## Initial Setup

### 1. Install Kamal

Already included in Gemfile:

```ruby
gem "kamal", require: false
```

### 2. Configure Docker Registry

#### Using Docker Hub

```bash
# Login to Docker Hub
docker login

# Or set credentials
export KAMAL_REGISTRY_PASSWORD=your_docker_hub_token
```

#### Using GitHub Container Registry

```bash
# Create personal access token with read:packages, write:packages
# Login to GitHub Container Registry
echo $GITHUB_TOKEN | docker login ghcr.io -u YOUR_GITHUB_USERNAME --password-stdin
```

### 3. Set Up Server

On your production server:

```bash
# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Add your user to docker group
sudo usermod -aG docker $USER

# Start Docker
sudo systemctl enable docker
sudo systemctl start docker

# Verify
docker --version
```

### 4. Configure SSH Access

```bash
# Copy your SSH key to server
ssh-copy-id deploy@your-server.com

# Test connection
ssh deploy@your-server.com

# Ensure passwordless sudo for docker commands (if needed)
# On server: sudo visudo
# Add: deploy ALL=(ALL) NOPASSWD: /usr/bin/docker
```

## Configuration

### Main Configuration File

Edit `config/deploy.yml`:

```yaml
# Name of your application
service: rails_starter_template

# Image name for Docker registry
# Format: registry/organization/app-name
image: your-dockerhub-username/rails_starter_template

# Servers to deploy to
servers:
  web:
    hosts:
      - 192.168.1.100
    labels:
      traefik.http.routers.app.rule: Host(`yourdomain.com`)
      traefik.http.routers.app.entrypoints: websecure
      traefik.http.routers.app.tls.certresolver: letsencrypt
    options:
      network: "private"

# Specify the Docker registry details
registry:
  username: your-dockerhub-username
  password:
    - KAMAL_REGISTRY_PASSWORD

# Environment variables for your application
env:
  clear:
    DB_HOST: db
    RAILS_LOG_TO_STDOUT: true
    RAILS_SERVE_STATIC_FILES: true
  secret:
    - RAILS_MASTER_KEY
    - DATABASE_URL
    - SECRET_KEY_BASE
    - GOOGLE_CLIENT_ID
    - GOOGLE_CLIENT_SECRET
    - JWT_SECRET_KEY

# Accessories (additional services)
accessories:
  db:
    image: postgres:16
    host: 192.168.1.100
    port: 5432
    env:
      clear:
        POSTGRES_USER: rails_app
        POSTGRES_DB: new_rails_template_production
      secret:
        - POSTGRES_PASSWORD
    directories:
      - data:/var/lib/postgresql/data

  redis:
    image: redis:7
    host: 192.168.1.100
    port: 6379
    directories:
      - data:/data

# SSL via Traefik
traefik:
  options:
    publish:
      - "443:443"
    volume:
      - "/letsencrypt:/letsencrypt"
  args:
    entryPoints.web.address: ":80"
    entryPoints.websecure.address: ":443"
    certificatesResolvers.letsencrypt.acme.email: "your-email@example.com"
    certificatesResolvers.letsencrypt.acme.storage: "/letsencrypt/acme.json"
    certificatesResolvers.letsencrypt.acme.httpchallenge: true
    certificatesResolvers.letsencrypt.acme.httpchallenge.entrypoint: web

# Health check
healthcheck:
  path: /up
  port: 3000
  max_attempts: 10
  interval: 10s

# Boot command
boot:
  limit: 10
  wait: 2
```

### Environment Secrets

Store secrets in `.kamal/secrets`:

```bash
# Create secrets file
mkdir -p .kamal
touch .kamal/secrets
chmod 600 .kamal/secrets
```

Add to `.kamal/secrets`:

```bash
#!/bin/bash

# Docker registry
export KAMAL_REGISTRY_PASSWORD="your-docker-hub-token"

# Rails
export RAILS_MASTER_KEY="your-rails-master-key"
export SECRET_KEY_BASE="generate-with-rails-secret"

# Database
export DATABASE_URL="postgresql://user:password@db:5432/new_rails_template_production"
export POSTGRES_PASSWORD="secure-postgres-password"

# Authentication
export JWT_SECRET_KEY="your-jwt-secret-from-figaro"
export GOOGLE_CLIENT_ID="your-google-client-id"
export GOOGLE_CLIENT_SECRET="your-google-client-secret"

# Add other secrets from config/application.yml
```

**Important:** Add `.kamal/secrets` to `.gitignore`!

## Deployment Commands

### First-Time Setup

```bash
# 1. Initialize Kamal on the server
kamal setup

# This will:
# - Create necessary directories
# - Start Traefik (reverse proxy)
# - Set up Docker network
# - Start accessories (database, redis)
# - Deploy your application
```

### Regular Deployments

```bash
# Deploy with zero downtime
kamal deploy

# Deploy with verbose output
kamal deploy --verbose

# Deploy specific version/branch
kamal deploy --version=v1.2.3
```

### Managing the Application

```bash
# Check application status
kamal app status

# View logs
kamal app logs
kamal app logs --tail 100
kamal app logs --follow

# Execute commands in container
kamal app exec 'bin/rails console'
kamal app exec 'bin/rails db:migrate'
kamal app exec 'bundle exec rake -T'

# Restart application
kamal app restart

# Stop application
kamal app stop

# Start application
kamal app start

# Remove application
kamal app remove
```

### Managing Accessories (Database, Redis)

```bash
# Check accessory status
kamal accessory status db
kamal accessory status redis

# Restart accessories
kamal accessory restart db
kamal accessory restart redis

# View accessory logs
kamal accessory logs db
kamal accessory logs redis

# Execute commands in accessory
kamal accessory exec db 'psql -U rails_app'
kamal accessory exec redis 'redis-cli'

# Remove and recreate accessory
kamal accessory remove db
kamal accessory boot db
```

### Managing Traefik (Reverse Proxy)

```bash
# Boot Traefik
kamal traefik boot

# Restart Traefik
kamal traefik restart

# Remove Traefik
kamal traefik remove

# View Traefik logs
kamal traefik logs
```

### Database Management

```bash
# Run migrations
kamal app exec 'bin/rails db:migrate'

# Seed database
kamal app exec 'bin/rails db:seed'

# Rails console
kamal app exec 'bin/rails console'

# Database backup (from host)
ssh deploy@your-server.com 'docker exec kamal-db-postgres pg_dump -U rails_app new_rails_template_production > backup.sql'

# Restore database
cat backup.sql | ssh deploy@your-server.com 'docker exec -i kamal-db-postgres psql -U rails_app new_rails_template_production'
```

### Environment Variables

```bash
# View current environment variables
kamal app exec 'env | grep RAILS'

# Update environment variables (requires redeploy)
# Edit config/deploy.yml, then:
kamal deploy
```

### Rollback

```bash
# Rollback to previous version
kamal rollback

# Or specify a version
kamal rollback 20231106120000
```

## Multiple Environments

### Staging Environment

Create `config/deploy.staging.yml`:

```yaml
service: rails_starter_template-staging

image: your-dockerhub-username/rails_starter_template

servers:
  web:
    hosts:
      - staging.yourdomain.com
    labels:
      traefik.http.routers.app-staging.rule: Host(`staging.yourdomain.com`)

env:
  clear:
    RAILS_ENV: staging
  secret:
    - RAILS_MASTER_KEY
# ... rest of configuration
```

Deploy to staging:

```bash
kamal setup -d staging
kamal deploy -d staging
kamal app logs -d staging
```

### Production Environment

```bash
# Use default config/deploy.yml
kamal setup
kamal deploy
kamal app logs
```

## Common Workflows

### Deploying a New Feature

```bash
# 1. Merge feature to main branch
git checkout main
git pull origin main

# 2. Deploy to staging first
kamal deploy -d staging

# 3. Test on staging
curl https://staging.yourdomain.com

# 4. Deploy to production
kamal deploy

# 5. Run any migrations if needed
kamal app exec 'bin/rails db:migrate'

# 6. Verify deployment
kamal app status
kamal app logs --tail 50
```

### Handling Failed Deployments

```bash
# 1. Check logs
kamal app logs --tail 100

# 2. Check container status
kamal app status

# 3. Rollback if needed
kamal rollback

# 4. Fix issue and redeploy
kamal deploy
```

### Scaling

```bash
# Deploy to multiple servers
# Edit config/deploy.yml:
servers:
  web:
    hosts:
      - 192.168.1.100
      - 192.168.1.101
      - 192.168.1.102

# Deploy
kamal deploy

# Kamal will distribute traffic via Traefik
```

### Zero-Downtime Maintenance

```bash
# Kamal automatically does zero-downtime deployments
# Old containers stay running until new ones are healthy

# To manually control:
kamal app boot    # Start new containers
kamal app stop    # Stop old containers
```

## SSL/TLS Configuration

### Automatic SSL with Let's Encrypt

Already configured in `config/deploy.yml`:

```yaml
traefik:
  args:
    certificatesResolvers.letsencrypt.acme.email: "your-email@example.com"
    certificatesResolvers.letsencrypt.acme.storage: "/letsencrypt/acme.json"
    certificatesResolvers.letsencrypt.acme.httpchallenge: true
```

Certificates are automatically generated and renewed.

### Custom SSL Certificates

```yaml
traefik:
  options:
    volume:
      - "/path/to/certs:/certs"
  args:
    entryPoints.websecure.http.tls.certificates[0].certFile: "/certs/cert.pem"
    entryPoints.websecure.http.tls.certificates[0].keyFile: "/certs/key.pem"
```

## Monitoring and Troubleshooting

### Health Checks

```bash
# Check if application is responding
curl https://yourdomain.com/up

# Check Traefik dashboard
curl http://your-server:8080/api/http/routers
```

### Viewing Logs

```bash
# Application logs
kamal app logs --tail 100 --follow

# Traefik logs
kamal traefik logs --tail 50

# Database logs
kamal accessory logs db --tail 100

# All logs
kamal logs --tail 50
```

### Debugging

```bash
# SSH into server
ssh deploy@your-server.com

# List running containers
docker ps

# Inspect container
docker inspect kamal-rails_starter_template-web-latest

# View container logs directly
docker logs kamal-rails_starter_template-web-latest

# Execute shell in container
docker exec -it kamal-rails_starter_template-web-latest /bin/bash

# Check container resources
docker stats
```

### Common Issues

#### Container Won't Start

```bash
# Check logs
kamal app logs --tail 100

# Common causes:
# - Missing environment variables
# - Database connection issues
# - Port conflicts
# - Image build failures
```

#### Health Check Failing

```bash
# Verify health check endpoint
kamal app exec 'curl http://localhost:3000/up'

# Check application logs
kamal app logs --grep "health"
```

#### Database Connection Issues

```bash
# Check database is running
kamal accessory status db

# Test database connection from app
kamal app exec 'bin/rails runner "puts ActiveRecord::Base.connection.active?"'

# Check DATABASE_URL environment variable
kamal app exec 'echo $DATABASE_URL'
```

#### SSL Certificate Issues

```bash
# Check Traefik configuration
kamal traefik logs --tail 100

# Verify domain DNS points to server
dig yourdomain.com

# Check Let's Encrypt rate limits
# https://letsencrypt.org/docs/rate-limits/
```

## CI/CD Integration

### GitHub Actions

Create `.github/workflows/deploy.yml`:

```yaml
name: Deploy

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v3

      - name: Set up Ruby
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: 3.2
          bundler-cache: true

      - name: Install Kamal
        run: gem install kamal

      - name: Set up SSH
        run: |
          mkdir -p ~/.ssh
          echo "${{ secrets.SSH_PRIVATE_KEY }}" > ~/.ssh/id_rsa
          chmod 600 ~/.ssh/id_rsa
          ssh-keyscan -H ${{ secrets.SERVER_IP }} >> ~/.ssh/known_hosts

      - name: Set up environment
        run: |
          mkdir -p .kamal
          cat > .kamal/secrets << EOF
          export KAMAL_REGISTRY_PASSWORD="${{ secrets.KAMAL_REGISTRY_PASSWORD }}"
          export RAILS_MASTER_KEY="${{ secrets.RAILS_MASTER_KEY }}"
          export SECRET_KEY_BASE="${{ secrets.SECRET_KEY_BASE }}"
          export DATABASE_URL="${{ secrets.DATABASE_URL }}"
          export POSTGRES_PASSWORD="${{ secrets.POSTGRES_PASSWORD }}"
          export JWT_SECRET_KEY="${{ secrets.JWT_SECRET_KEY }}"
          export GOOGLE_CLIENT_ID="${{ secrets.GOOGLE_CLIENT_ID }}"
          export GOOGLE_CLIENT_SECRET="${{ secrets.GOOGLE_CLIENT_SECRET }}"
          EOF
          chmod 600 .kamal/secrets

      - name: Deploy
        run: kamal deploy
```

## Performance Optimization

### Docker Image Optimization

Edit `Dockerfile`:

```dockerfile
# Use multi-stage builds
FROM ruby:3.2-alpine AS builder

# Install only necessary packages
RUN apk add --no-cache build-base postgresql-dev

# Copy only necessary files
COPY Gemfile Gemfile.lock ./
RUN bundle install --without development test

# Final stage
FROM ruby:3.2-alpine
RUN apk add --no-cache postgresql-client
COPY --from=builder /usr/local/bundle /usr/local/bundle
```

### Caching Strategy

```yaml
# In config/deploy.yml
builder:
  cache:
    type: registry
    options:
      mode: max
```

## Security Best Practices

1. **SSH Keys**: Use key-based authentication, disable password auth
2. **Secrets**: Never commit secrets, use `.kamal/secrets` file
3. **Firewall**: Only open necessary ports (80, 443, 22)
4. **Updates**: Keep Docker and system packages updated
5. **Monitoring**: Set up logging and alerts
6. **Backups**: Regular database backups
7. **SSL**: Always use HTTPS in production

## Cost Optimization

### Server Sizing

```
Small app (< 1000 users):
- 1 server: 2GB RAM, 1 CPU
- PostgreSQL: 1GB RAM
- Cost: ~$10-20/month

Medium app (< 10000 users):
- 2 servers: 4GB RAM, 2 CPU each
- PostgreSQL: 2GB RAM
- Redis: 1GB RAM
- Cost: ~$40-80/month

Large app (> 10000 users):
- 3+ servers: 8GB RAM, 4 CPU each
- PostgreSQL: 8GB RAM
- Redis: 2GB RAM
- Cost: $150+/month
```

### Server Providers

- **DigitalOcean**: Droplets ($6-$40/month)
- **Linode**: Shared CPU ($5-$40/month)
- **Vultr**: Cloud Compute ($6-$40/month)
- **Hetzner**: Cloud Servers (€4-€30/month, EU-based)
- **AWS EC2**: Various instances (more expensive)

## Resources

- [Kamal Documentation](https://kamal-deploy.org/)
- [Kamal GitHub](https://github.com/basecamp/kamal)
- [Docker Documentation](https://docs.docker.com/)
- [Traefik Documentation](https://doc.traefik.io/traefik/)
- [Let's Encrypt Docs](https://letsencrypt.org/docs/)

## Quick Reference

```bash
# Setup
kamal setup                          # First-time setup

# Deploy
kamal deploy                         # Deploy application
kamal deploy -d staging              # Deploy to staging
kamal rollback                       # Rollback deployment

# Application
kamal app status                     # Check status
kamal app logs                       # View logs
kamal app exec 'command'             # Run command
kamal app restart                    # Restart app

# Accessories
kamal accessory status db            # Check database
kamal accessory logs redis           # View Redis logs
kamal accessory restart db           # Restart database

# Traefik
kamal traefik restart                # Restart proxy
kamal traefik logs                   # View proxy logs

# Environment
kamal deploy -d staging              # Staging
kamal deploy -d production           # Production

# Debugging
ssh deploy@server                    # SSH to server
docker ps                            # List containers
docker logs container-name           # View container logs
```

## Next Steps

1. ✅ Review `config/deploy.yml` and customize for your servers
2. ✅ Set up `.kamal/secrets` with actual credentials
3. ✅ Configure your Docker registry credentials
4. ✅ Set up SSH access to your production server(s)
5. ✅ Run `kamal setup` for first-time deployment
6. ✅ Test deployment with `kamal deploy`
7. ✅ Set up monitoring and alerts
8. ✅ Configure automated backups
9. ✅ Integrate with CI/CD (optional)

Happy deploying! 🚀
