FROM python:3.12-slim
WORKDIR /app
COPY apps/agent/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY apps/agent ./apps/agent
COPY config ./config
CMD ["uvicorn", "apps.agent.gateway:app", "--host", "0.0.0.0", "--port", "8080"]
