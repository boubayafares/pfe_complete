"""Small structural validator for the checked-in FootTech OpenAPI contract."""

from __future__ import annotations

from collections import Counter
from pathlib import Path
from typing import Any

import yaml


SPEC_PATH = Path(__file__).with_name("foottech_api.yaml")
HTTP_METHODS = {"get", "post", "put", "patch", "delete", "options", "head", "trace"}


def iter_refs(value: Any):
    if isinstance(value, dict):
        ref = value.get("$ref")
        if isinstance(ref, str):
            yield ref
        for child in value.values():
            yield from iter_refs(child)
    elif isinstance(value, list):
        for child in value:
            yield from iter_refs(child)


def main() -> None:
    document = yaml.safe_load(SPEC_PATH.read_text(encoding="utf-8"))
    schemas = document.get("components", {}).get("schemas", {})
    paths = document.get("paths", {})

    missing_refs = sorted({
        ref.rsplit("/", 1)[-1]
        for ref in iter_refs(document)
        if ref.startswith("#/components/schemas/") and ref.rsplit("/", 1)[-1] not in schemas
    })
    operation_ids = [
        operation.get("operationId")
        for path_item in paths.values()
        for method, operation in path_item.items()
        if method in HTTP_METHODS and isinstance(operation, dict) and operation.get("operationId")
    ]
    duplicate_operation_ids = sorted(
        operation_id for operation_id, count in Counter(operation_ids).items() if count > 1
    )

    if missing_refs or duplicate_operation_ids:
        raise SystemExit(
            f"missing_refs={missing_refs} duplicate_operation_ids={duplicate_operation_ids}"
        )

    print(
        f"paths={len(paths)} schemas={len(schemas)} "
        "missing_refs=[] duplicate_operation_ids=[]"
    )


if __name__ == "__main__":
    main()
