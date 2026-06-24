#!/usr/bin/env python3
import os, time, json, math, random
from pathlib import Path

MODE = os.getenv("EEG_MODE", "mock")
SINK = Path(os.getenv("EEG_SINK", "/var/lib/reality-lab/eeg.ndjson"))
RATE = int(os.getenv("EEG_SAMPLE_RATE", "250"))
CHANNELS = int(os.getenv("EEG_CHANNELS", "8"))

def sink(obj):
    SINK.parent.mkdir(parents=True, exist_ok=True)
    with SINK.open("a", encoding="utf-8") as f:
        f.write(json.dumps(obj) + "\n")

def mock_sample(t):
    return [
        math.sin(t * 2 * math.pi * (8 + i * 0.7)) * 0.4 + random.gauss(0, 0.04)
        for i in range(CHANNELS)
    ]

def features(x):
    energy = sum(v*v for v in x) / max(1, len(x))
    return {
        "energy": energy,
        "attention_proxy": max(0.0, min(1.0, energy * 2.0)),
        "blink_noise_proxy": max(abs(v) for v in x),
    }

def main():
    print(f"EEG bridge mode={MODE} sink={SINK}")
    dt = 1.0 / RATE
    while True:
        t = time.time()
        sample = mock_sample(t)
        obj = {"time": t, "mode": MODE, "sample": sample, "features": features(sample)}
        sink(obj)
        time.sleep(dt)

if __name__ == "__main__":
    main()
