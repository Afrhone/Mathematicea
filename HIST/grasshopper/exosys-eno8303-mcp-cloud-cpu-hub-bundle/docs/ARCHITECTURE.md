# Architecture

```text
eno8303 direct switch link
  ├── swap/dump lane
  ├── CPU queue lane
  ├── MCP CPU Hub
  ├── Google Agent Gateway
  ├── IBM Quantum Gateway
  ├── Substack bridge
  └── Gamelab VM orchestrator
```

## Label swap example

```text
swap:exosys-rhiz:eno8303:cpu-mem-lane
```

A label swap maps task/resource intent to a live topology edge and a gateway control event.
