#!/usr/bin/env python3
"""
Uniphi-Alchemy Map validator

Usage:
  python3 validate.py templates/uniphi-alchemy-map-schema.json examples/example_alchemy_map.json
"""
import json
import sys

def basic_check(d: dict):
    required = ["project","date","phase","intent","axioms","ingredients","operations"]
    for k in required:
        if k not in d:
            raise ValueError(f"Missing required key: {k}")
    if not (0 <= int(d["phase"]) <= 6):
        raise ValueError("phase must be 0..6")
    if not (isinstance(d["ingredients"], list) and len(d["ingredients"]) == 9):
        raise ValueError("ingredients must be a list of 9 items")
    if not (isinstance(d["operations"], list) and len(d["operations"]) == 7):
        raise ValueError("operations must be a list of 7 items")

def main():
    if len(sys.argv) < 3:
        print("Usage: python3 validate.py <schema.json> <map.json>", file=sys.stderr)
        sys.exit(2)

    schema_path, data_path = sys.argv[1], sys.argv[2]
    with open(schema_path, "r", encoding="utf-8") as f:
        schema = json.load(f)
    with open(data_path, "r", encoding="utf-8") as f:
        data = json.load(f)

    # Prefer jsonschema if available
    try:
        import jsonschema  # type: ignore
        jsonschema.validate(instance=data, schema=schema)
        print("OK (jsonschema)")
    except ImportError:
        basic_check(data)
        print("OK (basic check; install jsonschema for full validation)")
    except Exception as e:
        print(f"INVALID: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
