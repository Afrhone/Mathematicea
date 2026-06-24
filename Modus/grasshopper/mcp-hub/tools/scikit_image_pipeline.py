#!/usr/bin/env python3
"""Minimal scikit-image pipeline helper for niurk MCP hub.
Usage:
  python3 tools/scikit_image_pipeline.py input.png outdir
Requires: pip install scikit-image imageio numpy
"""
from __future__ import annotations
import json
import sys
from pathlib import Path


def main() -> int:
    if len(sys.argv) < 3:
        print("usage: scikit_image_pipeline.py input-image outdir", file=sys.stderr)
        return 2
    image_path = Path(sys.argv[1])
    outdir = Path(sys.argv[2])
    outdir.mkdir(parents=True, exist_ok=True)
    try:
        import numpy as np
        import imageio.v3 as iio
        from skimage import filters, measure, morphology, util, color
    except Exception as exc:  # pragma: no cover
        print(f"missing dependency: {exc}", file=sys.stderr)
        return 3

    img = iio.imread(image_path)
    gray = color.rgb2gray(img) if getattr(img, 'ndim', 0) == 3 else util.img_as_float(img)
    gray = util.img_as_float(gray)
    threshold = filters.threshold_otsu(gray)
    mask = gray > threshold
    mask = morphology.remove_small_objects(mask, 32)
    mask = morphology.binary_closing(mask, morphology.disk(2))
    labels = measure.label(mask)
    props = measure.regionprops_table(labels, intensity_image=gray, properties=("label", "area", "centroid", "mean_intensity", "bbox"))
    features = {k: [float(x) if hasattr(x, '__float__') else x for x in v] for k, v in props.items()}
    iio.imwrite(outdir / "mask.png", (mask.astype('uint8') * 255))
    (outdir / "features.json").write_text(json.dumps({"image": str(image_path), "threshold": float(threshold), "features": features}, indent=2))
    print(json.dumps({"ok": True, "outdir": str(outdir), "regions": int(labels.max())}, indent=2))
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
