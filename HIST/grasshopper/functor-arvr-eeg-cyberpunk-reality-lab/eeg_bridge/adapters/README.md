# EEG adapters

Current implemented adapter:

```text
mock
```

Future adapter contracts:

```text
serial  → parse serial CSV/JSON samples
lsl     → Lab Streaming Layer stream
openbci → OpenBCI Cyton/Ganglion bridge
muse    → Muse bridge
```

All adapters must output:

```json
{
  "time": 0.0,
  "sample": [],
  "features": {
    "energy": 0.0,
    "attention_proxy": 0.0,
    "blink_noise_proxy": 0.0
  }
}
```
