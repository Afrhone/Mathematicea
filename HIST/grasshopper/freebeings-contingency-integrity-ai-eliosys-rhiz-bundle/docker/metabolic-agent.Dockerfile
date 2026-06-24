FROM python:3.11-slim
WORKDIR /app
COPY bin/ /app/bin/
COPY directives/ /app/directives/
COPY docs/ /app/docs/
RUN chmod +x /app/bin/*.py /app/bin/integrity-ai || true
CMD ["python3", "/app/bin/metabolic-engine.py", "cycle", "--env", "/app/env/freebeings.env"]
