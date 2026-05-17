# Security DevSecOps

Infrastructure and DevSecOps security patterns for shifting security left.

## Overview

This skill covers security best practices for infrastructure including secrets management, container security, zero-trust architecture, and compliance automation.

## Key Topics

- **Secrets management** - HashiCorp Vault, dynamic secrets, External Secrets Operator
- **Container security** - Trivy scanning, OPA policies, CIS benchmarks
- **Zero trust** - mTLS, Istio authorization, default-deny network policies
- **Compliance automation** - OPA Gatekeeper, Kyverno, CIS compliance
- **Vulnerability management** - Dependabot, Trivy Operator
- **Cloud security** - IAM roles for service accounts, Security Hub
- **Incident response** - Runbooks, forensics, recovery

## Usage

Use this skill when:
- Implementing shift-left security in CI/CD
- Setting up secrets management with Vault
- Configuring container/K8s security policies
- Building compliance automation
- Responding to security incidents

## Quick Reference

| Check | Target |
|-------|--------|
| Critical vulnerabilities | 0 |
| High vulnerabilities | < 5 |
| CIS compliance | > 90% |
| Secrets rotation | 24h |
| Backup tested | Weekly |
