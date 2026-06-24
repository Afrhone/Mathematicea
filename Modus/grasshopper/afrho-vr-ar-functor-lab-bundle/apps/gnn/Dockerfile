FROM python:3.12-slim
WORKDIR /app
COPY apps/gnn/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY apps/gnn ./apps/gnn
CMD ["python", "-m", "apps.gnn.worker"]
