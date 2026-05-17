# Getting Started

Quick start guide for new developers setting up local development environment.

## Overview

This skill provides the essential steps to:
- Set up local development environment
- Understand project structure
- Make first API request
- Learn common development commands

## Quick Reference

| Command | Purpose |
|---------|---------|
| `./docker-start.sh` | Start infrastructure (Postgres, RabbitMQ, Keycloak) |
| `./gradlew build` | Full build with tests |
| `./gradlew :services:service:bootRun` | Run specific service |

## Key Concepts

- **Three-layer architecture**: Domain → Application → Infrastructure
- **Dependencies flow inward**: Domain has zero framework imports
- **One use case per class**: Follows Single Responsibility Principle

## When to Use

- Onboarding to a new project
- Setting up local environment for first time
- Need to make first API request
- Understanding where files go

## Related Skills

- [Patterns Guide](patterns-guide/) - Architectural patterns explained
- [Testing Guide](testing-guide/) - How to write tests
- [Create Service](reference/create-service.md) - Adding new services
