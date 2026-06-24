# Ops Doctor Pseudocode

```python
def run_diagnostic(job):
    assert job.invariant
    facts = collect_read_only_facts(job.targets)
    contradictions = compare_against_invariant(facts, job.invariant)
    return Report(
        invariant=job.invariant,
        facts=facts,
        contradictions=contradictions,
        next_step=single_minimal_step(contradictions)
    )
```

Required checks:
- DNS resolution inside target container
- host DNS resolution
- endpoint status by direct IP
- endpoint status by declared hostname
- service ownership of target port
- Docker Swarm service poisoning
- proxy upstream config
- UI environment variables
