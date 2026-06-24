# Märklin Foundation Layer

This layer uses a model-train/clockwork metaphor: modular rails, gears, switches, loops, and bridges.

It is not affiliated with Märklin. The name is used here as the user-supplied shorthand for a miniature mechanical foundation.

## Mapping

```text
rail loop       -> closed phase orbit
tourbillon cage -> rotating reference frame
switch track    -> prime gate
gear train      -> coupled oscillator chain
station clock   -> compute-turn tick source
```

## Engineering Use

The metaphor helps keep the engine modular:

- every loop is inspectable
- every turn advances deterministically
- every switch/gate can be tested
- every subsystem can be replaced without changing the whole railway
