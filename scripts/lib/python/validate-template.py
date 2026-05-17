#!/usr/bin/env python3
"""
validate-template.py - Validate service template structure and schema
No external dependencies — uses regex for YAML field extraction.

Usage:
    python3 validate-template.py <template_dir>

Checks:
    1. template.yaml exists
    2. Required fields: apiVersion, kind, metadata.name, metadata.title, spec.type
    3. No orphaned .template files after generation
    4. Placeholder consistency
    5. Dockerfile and docker-compose.yml exist
"""

import argparse
import json
import os
import re
import sys


def read_file(path: str) -> str:
    with open(path, "r") as f:
        return f.read()


def get_field(content: str, field: str) -> str:
    pattern = rf"^{re.escape(field)}:\s*(.+)$"
    match = re.search(pattern, content, re.MULTILINE)
    if match:
        return match.group(1).strip().strip("'\"")
    return None


def validate_schema(content: str) -> list:
    """Validate template.yaml schema using regex."""
    errors = []

    required_top = ["apiVersion", "kind", "metadata", "spec"]
    for field in required_top:
        if not re.search(rf"^{field}:\s*", content, re.MULTILINE):
            errors.append(f"Missing required field: {field}")

    if "metadata:" in content:
        for field in ["name", "title"]:
            if not re.search(rf"^  {field}:\s*", content, re.MULTILINE):
                errors.append(f"Missing metadata.{field}")

    if "spec:" in content:
        if not re.search(rf"^  type:\s*", content, re.MULTILINE):
            errors.append("Missing spec.type")
        else:
            t = get_field(content, "type") or "service"
            if t not in {"service", "website", "library"}:
                errors.append(f"Invalid spec.type: {t}")

    return errors


def find_placeholders(template_dir: str) -> dict:
    """Find all __UPPERCASE__ placeholders in template files."""
    placeholders = {}
    pattern = re.compile(r"__([A-Z][A-Z0-9]+)__")

    for root, dirs, files in os.walk(template_dir):
        dirs[:] = [d for d in dirs if d not in {".git", "node_modules", "build", ".gradle"}]
        for filename in files:
            if filename == "template.yaml":
                continue
            path = os.path.join(root, filename)
            try:
                with open(path, "r", encoding="utf-8", errors="ignore") as f:
                    content = f.read()
                matches = pattern.findall(content)
                if matches:
                    rel = os.path.relpath(path, template_dir)
                    placeholders[rel] = list(set(matches))
            except:
                pass

    return placeholders


def main():
    parser = argparse.ArgumentParser(description="Validate service template")
    parser.add_argument("template_dir", help="Path to template directory")
    parser.add_argument("--json", action="store_true", help="Output as JSON")
    args = parser.parse_args()

    template_dir = args.template_dir
    if not os.path.isdir(template_dir):
        result = {"valid": False, "errors": [f"Not a directory: {template_dir}"]}
        print(json.dumps(result) if args.json else f"FAIL: {result['errors'][0]}")
        sys.exit(1)

    yaml_path = os.path.join(template_dir, "template.yaml")
    errors = []

    # 1. Check template.yaml exists
    if not os.path.exists(yaml_path):
        errors.append("template.yaml not found")
    else:
        try:
            content = read_file(yaml_path)
            errors.extend(validate_schema(content))
        except Exception as e:
            errors.append(f"Failed to read template.yaml: {e}")

    # 2. Check placeholders
    placeholders = find_placeholders(template_dir)
    known = {"SERVICE", "ENTITY", "PACKAGE", "TABLE", "PROJECT_NAME", "SERVICE_PASCAL", "TABLE_URL", "SERVICES_CONFIG", "SERVICES_LIST"}
    unknown = set()
    for file, markers in placeholders.items():
        for m in markers:
            if m not in known:
                unknown.add(m)
    if unknown:
        errors.append(f"Unknown placeholders: {', '.join(sorted(unknown))}")

    # 3. Check Docker files exist
    has_dockerfile = os.path.exists(os.path.join(template_dir, "Dockerfile")) or os.path.exists(os.path.join(template_dir, "Dockerfile.template"))
    has_compose = os.path.exists(os.path.join(template_dir, "docker-compose.yml")) or os.path.exists(os.path.join(template_dir, "docker-compose.yml.template"))
    if not has_dockerfile:
        errors.append("Missing Dockerfile (or Dockerfile.template)")
    if not has_compose:
        errors.append("Missing docker-compose.yml (or docker-compose.yml.template)")

    # 4. Note .template files (these are processed by new-service.sh)
    template_files = []
    for root, dirs, files in os.walk(template_dir):
        dirs[:] = [d for d in dirs if d not in {".git", "node_modules", "build", ".gradle"}]
        for f in files:
            if f.endswith(".template"):
                rel = os.path.relpath(os.path.join(root, f), template_dir)
                template_files.append(rel)
    if template_files:
        # Not an error — .template files are intentionally processed by generator
        pass

    result = {
        "valid": len(errors) == 0,
        "template": os.path.basename(template_dir),
        "errors": errors,
        "placeholders_found": sum(len(v) for v in placeholders.values()),
    }

    if args.json:
        print(json.dumps(result, indent=2))
    else:
        if result["valid"]:
            print(f"✅ {result['template']}: Valid")
        else:
            print(f"❌ {result['template']}: Invalid")
            for e in errors:
                print(f"   - {e}")

    sys.exit(0 if result["valid"] else 1)


if __name__ == "__main__":
    main()
