# Docker Patterns

Production-grade Docker containerization patterns for building secure, optimized images.

## Overview

This skill covers Docker best practices for production environments including multi-stage builds, security hardening, and supply chain security.

## Key Topics

- **Multi-stage builds** - Minimize image size by separating build and runtime environments
- **Image optimization** - Layer caching, .dockerignore, minimal base images
- **Security hardening** - Non-root execution, read-only filesystems, security contexts
- **Supply chain security** - SBOM generation, image signing with Cosign, SLSA provenance
- **Docker Compose** - Production-grade compose configurations with resource limits

## Usage

Use this skill when:
- Writing new Dockerfiles
- Optimizing existing images for size or build speed
- Hardening containers for production
- Setting up Docker Compose for staging/production
- Implementing image signing and provenance

## Quick Reference

| Target | Recommendation |
|--------|---------------|
| Image size | < 100MB for simple services |
| Build time | < 5 minutes with caching |
| User | Non-root (UID > 10000) |
| Healthcheck | Required for production |
| Base image | Distroless or Alpine |
