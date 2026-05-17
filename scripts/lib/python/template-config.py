#!/usr/bin/env python3
"""
template-config.py - Read and extract configuration from template.yaml
No external dependencies — uses regex for simple field extraction.

Usage:
    python3 template-config.py --template <dir> [--get-infrastructure|--get-metadata]

Returns JSON to stdout.
"""

import argparse
import json
import sys
import os
import re


def read_file(path: str) -> str:
    with open(path, "r") as f:
        return f.read()


def get_field(content: str, field: str) -> any:
    """Extract a top-level field value using regex."""
    pattern = rf"^{re.escape(field)}:\s*(.+)$"
    match = re.search(pattern, content, re.MULTILINE)
    if match:
        val = match.group(1).strip()
        # Handle simple list
        if val.startswith("["):
            return [v.strip().strip("'\"") for v in val.strip("[]").split(",")]
        return val.strip("'\"")
    return None


def get_infrastructure(content: str) -> dict:
    """Extract infrastructure toggles from template.yaml."""
    result = {
        "kafka": False,
        "rabbitmq": False,
        "postgres": True,
        "redis": False,
    }

    # Find enableKafka, enablePostgres, etc. defaults
    for key in result:
        prop_name = f"enable{key.capitalize()}"
        if key == "rabbitmq":
            prop_name = "enableRabbitMQ"
        elif key == "postgres":
            prop_name = "enablePostgres"

        pattern = rf"{prop_name}:\s*(.+)$"
        match = re.search(pattern, content, re.MULTILINE | re.IGNORECASE)
        if match:
            val = match.group(1).strip().lower()
            result[key] = val in ("true", "yes", "on")

    return result


def get_metadata(content: str) -> dict:
    """Extract metadata from template.yaml."""
    return {
        "name": get_field(content, "name") or "",
        "title": get_field(content, "title") or "",
        "description": get_field(content, "description") or "",
        "tags": get_field(content, "tags") or [],
        "type": get_field(content, "type") or "service",
    }


def main():
    parser = argparse.ArgumentParser(description="Read template.yaml configuration")
    parser.add_argument("--template", required=True, help="Path to template directory")
    parser.add_argument("--get-infrastructure", action="store_true", help="Output infrastructure toggles")
    parser.add_argument("--get-metadata", action="store_true", help="Output metadata")
    args = parser.parse_args()

    yaml_path = os.path.join(args.template, "template.yaml")
    if not os.path.exists(yaml_path):
        print(json.dumps({"error": f"template.yaml not found in {args.template}"}))
        sys.exit(1)

    content = read_file(yaml_path)

    if args.get_infrastructure:
        print(json.dumps(get_infrastructure(content)))
    elif args.get_metadata:
        print(json.dumps(get_metadata(content)))
    else:
        print(json.dumps({"path": yaml_path, "size": len(content)}))


if __name__ == "__main__":
    main()
