#!/usr/bin/env python3
"""
template-processor.py - Process skeleton fragments by replacing Backstage syntax

Usage:
    python3 template-processor.py --input <fragment_dir> --output <out_dir> --values <json>

Replaces ${{ values.key | default('xyz') }} with actual values.
"""

import argparse
import json
import os
import re
import sys
import shutil


def parse_value_expr(expr: str) -> tuple:
    """Parse ${{ values.key | default('xyz') }} -> (key, default_value)."""
    # Remove outer syntax
    inner = expr.strip()[3:-3].strip()  # remove ${{ and }}
    # Remove "values." prefix
    inner = inner.replace("values.", "", 1)

    # Extract default if present
    default_match = re.search(r"\|\s*default\(['\"]?([^'\"\)]*)['\"]?\)", inner)
    if default_match:
        key = re.sub(r"\|\s*default\(['\"]?[^'\"\)]*['\"]?\)", "", inner).strip()
        default_val = default_match.group(1)
        return key, default_val

    return inner.strip(), None


def replace_placeholders(content: str, values: dict) -> str:
    """Replace all ${{ values.xxx }} expressions in content."""
    pattern = re.compile(r"\$\{\{\s*values\.[^}]+\}\}")

    def replacer(match):
        expr = match.group(0)
        key, default_val = parse_value_expr(expr)

        # Support nested keys like values.nested.key
        parts = key.split(".")
        current = values
        for part in parts:
            if isinstance(current, dict) and part in current:
                current = current[part]
            else:
                current = None
                break

        if current is not None:
            return str(current)
        if default_val is not None:
            return default_val
        return expr  # leave unresolved if no default

    return pattern.sub(replacer, content)


def process_fragments(input_dir: str, output_dir: str, values: dict):
    """Copy all files from input_dir to output_dir, replacing placeholders."""
    if not os.path.exists(input_dir):
        print(json.dumps({"error": f"Input directory not found: {input_dir}"}))
        sys.exit(1)

    os.makedirs(output_dir, exist_ok=True)
    processed = []

    for root, dirs, files in os.walk(input_dir):
        rel_root = os.path.relpath(root, input_dir)
        out_root = os.path.join(output_dir, rel_root) if rel_root != "." else output_dir
        os.makedirs(out_root, exist_ok=True)

        for filename in files:
            in_path = os.path.join(root, filename)
            out_path = os.path.join(out_root, filename)

            with open(in_path, "r") as f:
                content = f.read()

            new_content = replace_placeholders(content, values)

            with open(out_path, "w") as f:
                f.write(new_content)

            processed.append(os.path.join(rel_root, filename) if rel_root != "." else filename)

    return processed


def main():
    parser = argparse.ArgumentParser(description="Process skeleton fragments")
    parser.add_argument("--input", required=True, help="Input fragment directory")
    parser.add_argument("--output", required=True, help="Output directory")
    parser.add_argument("--values", required=True, help="JSON string of values")
    args = parser.parse_args()

    try:
        values = json.loads(args.values)
    except json.JSONDecodeError as e:
        print(json.dumps({"error": f"Invalid JSON values: {e}"}))
        sys.exit(1)

    processed = process_fragments(args.input, args.output, values)
    print(json.dumps({"success": True, "processed": processed, "count": len(processed)}))


if __name__ == "__main__":
    main()
