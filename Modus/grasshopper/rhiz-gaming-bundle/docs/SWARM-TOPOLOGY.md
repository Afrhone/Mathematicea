# Docker Swarm topology

Recommended manager layout in this bundle:

- `pi-rhiz` — manager 1
- `factau-rhiz` — manager 2

Optional workers:

- `niurk-24`
- `niurk-43`

Use host labels and placement constraints to pin GPU services to GPU-capable workers.
